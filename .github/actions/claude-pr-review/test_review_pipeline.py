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


def sample_finding(**overrides):
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
    finding.update(overrides)
    return finding


class ReviewPipelineTests(unittest.TestCase):
    def test_action_allows_structured_output(self):
        action = Path(pipeline.__file__).with_name("action.yml").read_text(
            encoding="utf-8"
        )
        self.assertIn("Read,Glob,Grep,StructuredOutput,", action)
        self.assertIn("id: review_retry", action)
        self.assertIn("MUST call the\n          StructuredOutput tool", action)
        self.assertIn("GH_TOKEN: ${{ github.token }}", action)
        self.assertNotIn("GH_TOKEN: ${{ steps.review", action)

    def test_output_schema_uses_action_compatible_dialect(self):
        schema_path = Path(pipeline.__file__).with_name(
            "review-output.schema.json"
        )
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        self.assertNotIn("$schema", schema)
        self.assertEqual(schema["type"], "object")

    def test_expected_pull_requires_frozen_base_and_head(self):
        pull = {
            "base": {"sha": "base"},
            "head": {"sha": "head"},
        }
        pipeline.require_expected_pull(
            pull,
            expected_base="base",
            expected_head="head",
            context="in test",
        )
        with self.assertRaises(pipeline.StaleReviewError):
            pipeline.require_expected_pull(
                pull,
                expected_base="different-base",
                expected_head="head",
                context="in test",
            )

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

    def test_job_token_publisher_identities_are_recognized(self):
        self.assertTrue(pipeline.is_bot_login("github-actions"))
        self.assertTrue(pipeline.is_bot_login("github-actions[bot]"))
        self.assertFalse(pipeline.is_bot_login("unrelated-bot[bot]"))

    def test_latest_reviewed_head_ignores_unrelated_actions_review(self):
        state = review_input()["manifest"]
        marker = (
            f"{pipeline.STATE_MARKER_PREFIX}{pipeline.encode_state(state)} -->"
        )
        reviews = [
            {
                "body": marker,
                "commit_id": "reviewed-head",
                "user": {"login": "github-actions[bot]"},
            },
            {
                "body": "unrelated workflow review",
                "commit_id": "unrelated-head",
                "user": {"login": "github-actions[bot]"},
            },
        ]
        self.assertEqual(
            pipeline.latest_reviewed_head(reviews),
            "reviewed-head",
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
                    "user": {"login": "github-actions[bot]"},
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
                    "user": {"login": "github-actions[bot]"},
                }
            ],
            repository="megaeth-labs/example",
            pull_request=7,
        )
        self.assertEqual(loaded["cursor"]["review_id"], 42)

    def test_inline_fallback_review_restores_body_only_finding(self):
        state = review_input()["manifest"]
        state["findings"]["F-1"] = {
            "status": "open",
            "thread_required": True,
            "thread_id": None,
        }
        marker = (
            f"{pipeline.STATE_MARKER_PREFIX}{pipeline.encode_state(state)} -->"
        )
        loaded = pipeline.load_review_state(
            [
                {
                    "id": 42,
                    "body": f"{marker}\n{pipeline.INLINE_FALLBACK_MARKER}",
                    "user": {"login": "github-actions[bot]"},
                }
            ],
            repository="megaeth-labs/example",
            pull_request=7,
        )
        self.assertFalse(loaded["findings"]["F-1"]["thread_required"])

    def test_job_token_thread_links_only_from_stateful_review(self):
        manifest = review_input()["manifest"]
        manifest["findings"]["F-1"] = {
            "status": "open",
            "title": "Retry state survives a failed attempt",
            "path": "src/example.py",
            "line": 11,
        }
        thread = {
            "id": "THREAD",
            "isResolved": False,
            "comments": {
                "nodes": [
                    {
                        "databaseId": 99,
                        "body": (
                            "**[Major]** Retry state survives a failed attempt"
                        ),
                        "path": "src/example.py",
                        "line": 11,
                        "url": "https://example.test/thread",
                        "author": {"login": "github-actions"},
                        "pullRequestReview": {
                            "databaseId": 42,
                            "body": "unrelated workflow review",
                            "author": {"login": "github-actions"},
                        },
                    }
                ]
            },
        }
        pipeline.import_legacy_findings(manifest, [thread])
        self.assertIsNone(manifest["findings"]["F-1"].get("thread_id"))

        state = review_input()["manifest"]
        marker = (
            f"{pipeline.STATE_MARKER_PREFIX}{pipeline.encode_state(state)} -->"
        )
        thread["comments"]["nodes"][0]["pullRequestReview"]["body"] = marker
        pipeline.import_legacy_findings(manifest, [thread])
        finding = manifest["findings"]["F-1"]
        self.assertEqual(finding["thread_id"], "THREAD")
        self.assertEqual(finding["comment_id"], 99)
        self.assertTrue(finding["thread_required"])

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
        output["findings"] = [sample_finding()]
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

    def test_skip_with_open_finding_preserves_manifest(self):
        value = review_input(mode="skip")
        value["manifest"]["findings"]["F-existing"] = {
            "status": "open",
            "severity": "major",
            "thread_id": "THREAD",
        }
        payload = pipeline.compile_review(value, None)
        self.assertFalse(payload["should_submit_review"])
        self.assertEqual(
            payload["manifest"]["findings"]["F-existing"]["status"],
            "open",
        )

    def test_finding_path_is_canonicalized(self):
        output = clean_output()
        output["findings"] = [sample_finding(path="./src/example.py")]
        payload = pipeline.compile_review(review_input(), output)
        self.assertEqual(
            payload["inline_comments"][0]["path"],
            "src/example.py",
        )

    def test_invalid_finding_path_fails_loudly(self):
        output = clean_output()
        output["findings"] = [sample_finding(path="src/not-changed.py")]
        with self.assertRaisesRegex(pipeline.PipelineError, "unchanged path"):
            pipeline.compile_review(review_input(), output)

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

    def test_inline_finding_cannot_resolve_without_thread_id(self):
        value = review_input()
        value["manifest"]["findings"]["F-existing"] = {
            "status": "open",
            "severity": "major",
            "thread_required": True,
            "thread_id": None,
        }
        output = clean_output()
        output["prior_findings"] = [
            {
                "finding_id": "F-existing",
                "disposition": "resolved",
                "reason": "The retry now clears partial state.",
            }
        ]
        with self.assertRaisesRegex(
            pipeline.PipelineError,
            "without a GitHub thread ID",
        ):
            pipeline.compile_review(value, output)

    def test_existing_open_finding_is_not_reposted(self):
        output = clean_output()
        finding = sample_finding()
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

    def test_resolved_prior_does_not_suppress_distinct_same_symbol_finding(self):
        value = review_input()
        value["manifest"]["findings"]["F-existing"] = {
            "status": "open",
            "severity": "major",
            "path": "src/example.py",
            "symbol": "retry",
            "line": 11,
            "thread_id": "THREAD",
        }
        output = clean_output()
        output["prior_findings"] = [
            {
                "finding_id": "F-existing",
                "disposition": "resolved",
                "reason": "The partial-state leak was fixed.",
            }
        ]
        output["findings"] = [
            sample_finding(
                title="Retry count is off by one",
                root_cause="The retry condition uses an inclusive bound",
                impact="One extra request is issued after exhaustion.",
                suggested_fix="Use an exclusive retry bound.",
            )
        ]
        payload = pipeline.compile_review(value, output)
        self.assertEqual(payload["resolve_thread_ids"], ["THREAD"])
        self.assertEqual(len(payload["inline_comments"]), 1)

    def test_round_marker_changes_with_rubric_version(self):
        first = review_input()
        second = review_input()
        second["rubric_version"] = "sha256:new-rubric"
        first_payload = pipeline.compile_review(first, clean_output())
        second_payload = pipeline.compile_review(second, clean_output())
        self.assertNotEqual(
            first_payload["round_marker"],
            second_payload["round_marker"],
        )
        self.assertNotEqual(
            first_payload["round"]["round_id"],
            second_payload["round"]["round_id"],
        )

    @mock.patch.object(pipeline, "gh_pages")
    def test_existing_round_review_requires_bot_author_and_commit(
        self,
        pages_mock,
    ):
        pages_mock.return_value = [
            {
                "id": 1,
                "body": "<!-- round -->",
                "commit_id": "head",
                "user": {"login": "human"},
            },
            {
                "id": 2,
                "body": "<!-- round -->",
                "commit_id": "other-head",
                "user": {"login": "claude"},
            },
            {
                "id": 3,
                "body": "<!-- round -->",
                "commit_id": "head",
                "user": {"login": "github-actions[bot]"},
            },
        ]
        self.assertEqual(
            pipeline.existing_round_review(
                "megaeth-labs/example",
                7,
                "<!-- round -->",
                "head",
            ),
            3,
        )

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
                "body": "**[Major]** Finding",
                "html_url": "https://example.test/thread",
            }
        ]
        payload = {
            "should_submit_review": True,
            "repository": "megaeth-labs/example",
            "pull_request": 7,
            "round_marker": "<!-- round -->",
            "frozen_head": "b" * 40,
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
        review_id, posted, inline_published = pipeline.submit_review(payload)
        self.assertEqual(review_id, 42)
        self.assertEqual(posted["F-1"]["comment_id"], 99)
        self.assertTrue(inline_published)
        request = json.loads(run_mock.call_args.kwargs["input_text"])
        self.assertEqual(request["commit_id"], "b" * 40)
        self.assertEqual(request["event"], "COMMENT")
        self.assertEqual(len(request["comments"]), 1)
        self.assertNotIn("finding_id", request["comments"][0])

    @mock.patch.object(pipeline.time, "sleep")
    @mock.patch.object(pipeline, "review_threads")
    def test_published_thread_links_through_exact_review(
        self,
        threads_mock,
        sleep_mock,
    ):
        threads_mock.side_effect = [
            [],
            [
                {
                    "id": "THREAD",
                    "comments": {
                        "nodes": [
                            {
                                "databaseId": 99,
                                "path": "src/example.py",
                                "line": 11,
                                "body": "**[Major]** Finding",
                                "url": "https://example.test/thread",
                                "author": {"login": "github-actions"},
                                "pullRequestReview": {
                                    "databaseId": 42,
                                    "body": "state",
                                    "author": {"login": "github-actions"},
                                },
                            }
                        ]
                    },
                }
            ],
        ]
        manifest = review_input()["manifest"]
        manifest["findings"]["F-1"] = {
            "status": "open",
            "comment_id": None,
            "thread_id": None,
            "thread_required": True,
        }
        payload = {
            "repository": "megaeth-labs/example",
            "pull_request": 7,
            "inline_comments": [
                {
                    "finding_id": "F-1",
                    "path": "src/example.py",
                    "line": 11,
                    "body": "**[Major]** Finding",
                }
            ],
        }
        pipeline.attach_published_threads(payload, manifest, 42)
        finding = manifest["findings"]["F-1"]
        self.assertEqual(finding["thread_id"], "THREAD")
        self.assertEqual(finding["comment_id"], 99)
        sleep_mock.assert_called_once_with(
            pipeline.GITHUB_LINK_RETRY_DELAY_SECONDS
        )

    @mock.patch.object(pipeline, "gh_json")
    def test_thread_resolution_requires_github_confirmation(self, gh_json_mock):
        gh_json_mock.return_value = {
            "data": {
                "resolveReviewThread": {
                    "thread": {"id": "THREAD", "isResolved": True}
                }
            }
        }
        self.assertEqual(pipeline.resolve_threads(["THREAD"]), {"THREAD"})

        gh_json_mock.return_value = {
            "data": {
                "resolveReviewThread": {
                    "thread": {"id": "THREAD", "isResolved": False}
                }
            }
        }
        with self.assertRaisesRegex(
            pipeline.PipelineError,
            "did not confirm resolution",
        ):
            pipeline.resolve_threads(["THREAD"])

    @mock.patch.object(pipeline, "submit_review")
    @mock.patch.object(pipeline, "gh_json")
    def test_stale_head_is_discarded_before_writes(
        self,
        gh_json_mock,
        submit_mock,
    ):
        gh_json_mock.return_value = {
            "base": {"sha": "base"},
            "head": {"sha": "new-head"},
        }
        payload = {
            "mode": "incremental",
            "repository": "megaeth-labs/example",
            "pull_request": 7,
            "frozen_head": "old-head",
            "base_sha": "base",
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
