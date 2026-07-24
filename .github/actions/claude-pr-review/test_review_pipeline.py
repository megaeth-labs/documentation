#!/usr/bin/env python3

import copy
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

import review_pipeline as pipeline


def review_input(*, mode: str = "full"):
    manifest = pipeline.empty_manifest(
        repository="megaeth-labs/example",
        pull_request=7,
        pipeline_version="sha256:pipeline",
        rubric_version="sha256:rubric",
    )
    return {
        "schema_version": 1,
        "repository": "megaeth-labs/example",
        "pull_request": 7,
        "pull_request_data": {
            "base_sha": "a" * 40,
            "head_sha": "b" * 40,
        },
        "review_scope": {
            "mode": mode,
            "reason": "test",
            "previous_reviewed_head": "a" * 40 if mode == "incremental" else None,
            "current_head": "b" * 40,
            "changed_paths": ["src/example.py"],
            "full_pr_paths": ["src/example.py"],
            "high_risk": False,
            "model_tier": "fast",
            "run_premortem": False,
        },
        "manifest": manifest,
        "review_threads": [],
        "commentable_lines": {"src/example.py": [10, 11, 12]},
        "sticky_comment_id": None,
        "pipeline_version": "sha256:pipeline",
        "rubric_version": "sha256:rubric",
    }


def clean_output():
    return {
        "scope_summary": "Reviewed the example change.",
        "findings": [],
        "open_questions": [],
        "prior_findings": [],
    }


class ReviewPipelineTests(unittest.TestCase):
    def test_state_marker_round_trip(self):
        state = pipeline.empty_manifest(
            repository="megaeth-labs/example",
            pull_request=7,
            pipeline_version="pipeline",
            rubric_version="rubric",
        )
        body = (
            "visible\n\n"
            f"{pipeline.STATE_MARKER_PREFIX}{pipeline.encode_state(state)} -->"
        )
        self.assertEqual(pipeline.decode_state(body), state)

    def test_patch_parser_returns_right_side_lines(self):
        patch = """@@ -9,3 +9,4 @@
 context
-old
+new
+another
 context
"""
        self.assertEqual(pipeline.parse_patch_lines(patch), {9, 10, 11, 12})

    def test_high_risk_routing(self):
        self.assertTrue(
            pipeline.is_high_risk([".github/workflows/review.yml"])
        )
        self.assertFalse(pipeline.is_high_risk(["docs/guide.md"]))

    def test_internal_provenance_is_removed_from_public_text(self):
        self.assertEqual(
            pipeline.public_text(
                "(pre-mortem, confirmed) Token leaks through tracing",
                maximum=160,
            ),
            "Token leaks through tracing",
        )

    def test_sticky_state_must_be_bot_authored(self):
        state = review_input()["manifest"]
        marker = (
            f"{pipeline.STATE_MARKER_PREFIX}{pipeline.encode_state(state)} -->"
        )
        loaded, comment_id = pipeline.load_sticky_state(
            [
                {
                    "id": 1,
                    "body": marker,
                    "user": {"login": "external-user"},
                },
                {
                    "id": 2,
                    "body": marker,
                    "user": {"login": "claude"},
                },
            ],
            repository="megaeth-labs/example",
            pull_request=7,
        )
        self.assertEqual(loaded, state)
        self.assertEqual(comment_id, 2)

    def test_review_body_is_manifest_fallback(self):
        state = review_input()["manifest"]
        marker = (
            f"{pipeline.STATE_MARKER_PREFIX}{pipeline.encode_state(state)} -->"
        )
        loaded = pipeline.load_review_state(
            [
                {
                    "id": 42,
                    "body": marker,
                    "user": {"login": "claude"},
                }
            ],
            repository="megaeth-labs/example",
            pull_request=7,
        )
        self.assertEqual(loaded["cursor"]["review_id"], 42)

    def test_unresolved_github_thread_reopens_manifest_finding(self):
        manifest = review_input()["manifest"]
        manifest["findings"]["F-1"] = {
            "status": "resolved",
            "resolved_sha": "old",
            "thread_id": "THREAD",
        }
        pipeline.sync_manifest_threads(
            manifest,
            [{"id": "THREAD", "isResolved": False}],
        )
        self.assertEqual(manifest["findings"]["F-1"]["status"], "open")
        self.assertIsNone(manifest["findings"]["F-1"]["resolved_sha"])

    def test_clean_incremental_review_is_compact(self):
        payload = pipeline.compile_review(
            review_input(mode="incremental"),
            clean_output(),
        )
        self.assertEqual(payload["verdict"], "clean")
        self.assertFalse(payload["should_submit_review"])
        self.assertIn("✅ Re-review clean", payload["review_body"])
        self.assertIn("aaaaaaaa..bbbbbbbb", payload["review_body"])
        self.assertNotIn("pre-mortem", payload["review_body"].lower())

    def test_finding_is_anchored_and_rendered_deterministically(self):
        output = clean_output()
        output["findings"] = [
            {
                "title": "Retry state survives a failed attempt",
                "path": "src/example.py",
                "symbol": "retry",
                "line": 11,
                "start_line": None,
                "severity": "major",
                "confidence": "high",
                "root_cause": "The retry loop reuses partial state",
                "impact": "Every later attempt fails deterministically.",
                "suggested_fix": "Clear partial state at the start of each attempt.",
            }
        ]
        payload = pipeline.compile_review(review_input(), output)
        self.assertEqual(payload["verdict"], "findings")
        self.assertTrue(payload["should_submit_review"])
        self.assertEqual(len(payload["inline_comments"]), 1)
        self.assertEqual(
            payload["inline_comments"][0]["body"],
            "**[Major]** Retry state survives a failed attempt\n\n"
            "Every later attempt fails deterministically.\n\n"
            "Suggested fix: Clear partial state at the start of each attempt.",
        )

    def test_uncertain_item_becomes_open_question(self):
        output = clean_output()
        output["open_questions"] = [
            {
                "question": "Can the upstream return duplicate records?",
                "confidence": "medium",
                "why_it_matters": "Duplicate records would be applied twice.",
                "verification": "Confirm the upstream uniqueness contract.",
            }
        ]
        payload = pipeline.compile_review(review_input(), output)
        self.assertEqual(payload["verdict"], "questions")
        self.assertEqual(payload["inline_comments"], [])
        self.assertIn(
            "Open question · Medium confidence",
            payload["review_body"],
        )

    def test_every_open_prior_finding_requires_a_disposition(self):
        value = review_input()
        value["manifest"]["findings"]["F-existing"] = {
            "status": "open",
            "severity": "major",
            "thread_id": "THREAD",
        }
        with self.assertRaisesRegex(
            pipeline.PipelineError,
            "disposition every open finding",
        ):
            pipeline.compile_review(value, clean_output())

    def test_resolved_prior_finding_produces_thread_resolution(self):
        value = review_input()
        value["manifest"]["findings"]["F-existing"] = {
            "status": "open",
            "severity": "major",
            "thread_id": "THREAD",
        }
        output = clean_output()
        output["prior_findings"] = [
            {
                "finding_id": "F-existing",
                "disposition": "resolved",
                "reason": "The retry now clears partial state.",
            }
        ]
        payload = pipeline.compile_review(value, output)
        self.assertEqual(payload["resolve_thread_ids"], ["THREAD"])
        self.assertEqual(
            payload["manifest"]["findings"]["F-existing"]["status"],
            "resolved",
        )

    def test_existing_open_finding_is_not_reposted(self):
        output = clean_output()
        finding = {
            "title": "Retry state survives a failed attempt",
            "path": "src/example.py",
            "symbol": "retry",
            "line": 11,
            "start_line": None,
            "severity": "major",
            "confidence": "high",
            "root_cause": "The retry loop reuses partial state",
            "impact": "Every later attempt fails deterministically.",
            "suggested_fix": "Clear partial state at the start of each attempt.",
        }
        item_id = pipeline.finding_id(finding)
        value = review_input()
        value["manifest"]["findings"][item_id] = {
            "status": "open",
            "severity": "major",
            "thread_id": "THREAD",
        }
        output["findings"] = [copy.deepcopy(finding)]
        output["prior_findings"] = [
            {
                "finding_id": item_id,
                "disposition": "open",
                "reason": "The issue remains.",
            }
        ]
        payload = pipeline.compile_review(value, output)
        self.assertEqual(payload["inline_comments"], [])
        self.assertFalse(payload["should_submit_review"])

    @mock.patch.object(pipeline, "gh_pages")
    @mock.patch.object(pipeline, "existing_round_review", return_value=None)
    @mock.patch.object(pipeline, "run")
    def test_review_submission_is_one_atomic_request(
        self,
        run_mock,
        _existing_mock,
        pages_mock,
    ):
        run_mock.return_value = SimpleNamespace(
            returncode=0,
            stdout=json.dumps({"id": 42}),
            stderr="",
        )
        pages_mock.return_value = [
            {
                "id": 99,
                "path": "src/example.py",
                "line": 11,
                "body": "**[Major]** Finding",
                "html_url": "https://example.test/thread",
            }
        ]
        payload = {
            "should_submit_review": True,
            "repository": "megaeth-labs/example",
            "pull_request": 7,
            "round_marker": "<!-- round -->",
            "review_body": "Review body",
            "inline_comments": [
                {
                    "finding_id": "F-1",
                    "path": "src/example.py",
                    "line": 11,
                    "side": "RIGHT",
                    "body": "**[Major]** Finding",
                }
            ],
        }
        review_id, posted = pipeline.submit_review(payload)
        self.assertEqual(review_id, 42)
        self.assertEqual(posted["F-1"]["comment_id"], 99)
        request = json.loads(run_mock.call_args.kwargs["input_text"])
        self.assertEqual(request["event"], "COMMENT")
        self.assertEqual(len(request["comments"]), 1)
        self.assertNotIn("finding_id", request["comments"][0])

    @mock.patch.object(pipeline, "submit_review")
    @mock.patch.object(pipeline, "gh_json")
    def test_stale_head_is_discarded_before_writes(
        self,
        gh_json_mock,
        submit_mock,
    ):
        gh_json_mock.return_value = {"head": {"sha": "new-head"}}
        payload = {
            "mode": "incremental",
            "repository": "megaeth-labs/example",
            "pull_request": 7,
            "frozen_head": "old-head",
            "verdict": "clean",
        }
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, "review-payload.json").write_text(
                json.dumps(payload),
                encoding="utf-8",
            )
            pipeline.publish(SimpleNamespace(state_dir=directory))
        submit_mock.assert_not_called()


if __name__ == "__main__":
    unittest.main()
