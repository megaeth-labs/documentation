#!/usr/bin/env python3
"""Deterministic preparation, compilation, and publication for PR reviews."""

from __future__ import annotations

import argparse
import base64
import copy
import datetime as dt
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import Any, Callable


SCHEMA_VERSION = 1
MODEL_POLICY_VERSION = "v1"
STATE_MARKER_PREFIX = "<!-- claude-review-state:v1 "
STATE_MARKER_RE = re.compile(
    r"<!-- claude-review-state:v1 ([A-Za-z0-9_-]+) -->"
)
INLINE_FALLBACK_MARKER = "<!-- claude-review-inline-fallback:v1 -->"
SEVERITIES = {"critical", "major", "minor", "nit"}
QUESTION_CONFIDENCE = {"medium", "low"}
INTERNAL_TERMS_RE = re.compile(
    r"\b(pre[- ]mortem|verifier|sub-?agent|tool[- ]flow)\b",
    re.IGNORECASE,
)
INTERNAL_LABEL_RE = re.compile(
    r"(?i)(?:\((?:pre[- ]mortem|verifier)[^)]*\)|"
    r"\b(?:pre[- ]mortem|verifier|sub-?agent|tool[- ]flow)"
    r"(?:\s+(?:analysis|confirmed|unverified))?\b[\s:,-]*)"
)
HIGH_RISK_PARTS = {
    "auth",
    "authentication",
    "authorization",
    "concurrency",
    "consensus",
    "crypto",
    "database",
    "lock",
    "migration",
    "permission",
    "protocol",
    "schema",
    "security",
    "storage",
}
LEGACY_REVIEWER_LOGINS = {
    "claude",
    "github-actions",
}
GITHUB_LINK_RETRY_ATTEMPTS = 5
GITHUB_LINK_RETRY_DELAY_SECONDS = 1


class PipelineError(RuntimeError):
    """A deterministic pipeline failure."""


class StaleReviewError(PipelineError):
    """The pull request no longer matches the frozen review revision."""


def run(
    args: list[str],
    *,
    input_text: str | None = None,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        args,
        input=input_text,
        text=True,
        capture_output=True,
        check=False,
    )
    if check and result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise PipelineError(f"{' '.join(args)} failed: {detail}")
    return result


def gh_json(
    args: list[str],
    *,
    input_value: Any | None = None,
) -> Any:
    input_text = None
    command = ["gh", *args]
    if input_value is not None:
        input_text = json.dumps(input_value, separators=(",", ":"))
        command.extend(["--input", "-"])
    result = run(command, input_text=input_text)
    if not result.stdout.strip():
        return None
    return json.loads(result.stdout)


def gh_pages(endpoint: str) -> list[Any]:
    value = gh_json(["api", "--paginate", "--slurp", endpoint])
    if not isinstance(value, list):
        return []
    flattened: list[Any] = []
    for page in value:
        if isinstance(page, list):
            flattened.extend(page)
    return flattened


def authenticated_login() -> str:
    response = gh_json(
        [
            "api",
            "graphql",
            "-f",
            "query=query { viewer { login } }",
        ]
    )
    login = str(
        (response or {}).get("data", {}).get("viewer", {}).get("login") or ""
    )
    if not login:
        raise PipelineError("could not determine GitHub publisher identity")
    return login


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()


def compact_json(value: Any) -> str:
    return json.dumps(value, separators=(",", ":"), sort_keys=True)


def encode_state(state: dict[str, Any]) -> str:
    payload = compact_json(state).encode()
    return base64.urlsafe_b64encode(payload).decode().rstrip("=")


def decode_state(body: str) -> dict[str, Any] | None:
    match = STATE_MARKER_RE.search(body)
    if not match:
        return None
    encoded = match.group(1)
    encoded += "=" * (-len(encoded) % 4)
    try:
        value = json.loads(base64.urlsafe_b64decode(encoded))
    except (ValueError, json.JSONDecodeError):
        return None
    return value if isinstance(value, dict) else None


def hash_files(paths: list[Path]) -> str:
    digest = hashlib.sha256()
    for path in sorted(paths):
        digest.update(path.name.encode())
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return f"sha256:{digest.hexdigest()}"


def sanitize_text(value: Any, *, maximum: int) -> str:
    text = " ".join(str(value or "").strip().split())
    text = text.replace("<!--", "").replace("-->", "")
    return text[:maximum].rstrip()


def canonicalize_path(value: Any) -> str:
    path = sanitize_text(value, maximum=500)
    while path.startswith("./"):
        path = path[2:]
    return path


def pull_base_head(pull: dict[str, Any]) -> tuple[str, str]:
    return str(pull["base"]["sha"]), str(pull["head"]["sha"])


def require_expected_pull(
    pull: dict[str, Any],
    *,
    expected_base: str,
    expected_head: str,
    context: str,
) -> None:
    base_sha, head_sha = pull_base_head(pull)
    if base_sha != expected_base or head_sha != expected_head:
        raise StaleReviewError(
            f"PR changed {context}: expected {expected_base}..{expected_head}, "
            f"found {base_sha}..{head_sha}"
        )


def public_text(value: Any, *, maximum: int) -> str:
    text = sanitize_text(value, maximum=maximum)
    text = INTERNAL_LABEL_RE.sub("", text)
    return " ".join(text.split()).strip()


def normalize_key(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")


def finding_id(finding: dict[str, Any]) -> str:
    key = "|".join(
        (
            sanitize_text(finding.get("path"), maximum=500).lower(),
            sanitize_text(finding.get("symbol"), maximum=200).lower(),
            normalize_key(sanitize_text(finding.get("root_cause"), maximum=600)),
        )
    )
    return f"F-{hashlib.sha256(key.encode()).hexdigest()[:12]}"


def parse_patch_lines(patch: str) -> set[int]:
    """Return RIGHT-side line numbers present in unified-diff hunks."""
    lines: set[int] = set()
    current: int | None = None
    for raw in patch.splitlines():
        if raw.startswith("@@"):
            match = re.search(r"\+(\d+)(?:,\d+)?", raw)
            current = int(match.group(1)) if match else None
            continue
        if current is None:
            continue
        if raw.startswith("\\"):
            continue
        if raw.startswith("-"):
            continue
        if raw.startswith("+") or raw.startswith(" "):
            lines.add(current)
            current += 1
            continue
        current = None
    return lines


def is_high_risk(paths: list[str]) -> bool:
    for path in paths:
        lowered = path.lower()
        if lowered.startswith((".github/actions/", ".github/workflows/")):
            return True
        tokens = set(re.split(r"[^a-z0-9]+", lowered))
        if tokens & HIGH_RISK_PARTS:
            return True
    return False


def canonical_login(login: str | None) -> str:
    lowered = (login or "").lower()
    return lowered.removesuffix("[bot]")


def reviewer_logins(publisher_login: str | None = None) -> set[str]:
    logins = set(LEGACY_REVIEWER_LOGINS)
    if publisher_login:
        logins.add(canonical_login(publisher_login))
    return logins


def is_bot_login(
    login: str | None,
    *,
    publisher_login: str | None = None,
) -> bool:
    return canonical_login(login) in reviewer_logins(publisher_login)


def is_stateful_review(
    login: str | None,
    body: str | None,
    *,
    publisher_login: str | None = None,
) -> bool:
    lowered = canonical_login(login)
    if lowered == "claude":
        return True
    return (
        lowered in reviewer_logins(publisher_login)
        and decode_state(body or "") is not None
    )


def is_owned_review_comment(
    comment: dict[str, Any],
    *,
    repository: str,
    pull_request: int,
    publisher_login: str | None = None,
) -> bool:
    login = canonical_login((comment.get("author") or {}).get("login"))
    if login == "claude":
        return True
    if login not in reviewer_logins(publisher_login):
        return False
    review = comment.get("pullRequestReview") or {}
    review_login = (review.get("author") or {}).get("login")
    state = decode_state(str(review.get("body") or ""))
    return (
        is_stateful_review(
            review_login,
            str(review.get("body") or ""),
            publisher_login=publisher_login,
        )
        and valid_manifest(
            state,
            repository=repository,
            pull_request=pull_request,
        )
    )


def empty_manifest(
    *,
    repository: str,
    pull_request: int,
    pipeline_version: str,
    rubric_version: str,
) -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "repository": repository,
        "pull_request": pull_request,
        "reviewer": {
            "pipeline_version": pipeline_version,
            "rubric_version": rubric_version,
            "model_policy_version": MODEL_POLICY_VERSION,
        },
        "cursor": {
            "last_published_head": None,
            "base_branch_sha": None,
            "review_id": None,
            "reviewed_at": None,
            "mode": None,
        },
        "findings": {},
        "rounds": [],
    }


def valid_manifest(
    state: dict[str, Any] | None,
    *,
    repository: str,
    pull_request: int,
) -> bool:
    return bool(
        state
        and state.get("schema_version") == SCHEMA_VERSION
        and state.get("repository") == repository
        and state.get("pull_request") == pull_request
        and isinstance(state.get("findings"), dict)
        and isinstance(state.get("rounds"), list)
    )


def load_sticky_state(
    comments: list[dict[str, Any]],
    *,
    repository: str,
    pull_request: int,
    publisher_login: str | None = None,
) -> tuple[dict[str, Any] | None, int | None]:
    for comment in reversed(comments):
        login = (comment.get("user") or {}).get("login")
        if not is_bot_login(login, publisher_login=publisher_login):
            continue
        body = comment.get("body") or ""
        state = decode_state(body)
        if valid_manifest(
            state,
            repository=repository,
            pull_request=pull_request,
        ):
            editable_comment_id = (
                int(comment["id"])
                if not publisher_login
                or canonical_login(login) == canonical_login(publisher_login)
                else None
            )
            return state, editable_comment_id
    return None, None


def load_review_state(
    reviews: list[dict[str, Any]],
    *,
    repository: str,
    pull_request: int,
    publisher_login: str | None = None,
) -> dict[str, Any] | None:
    for review in reversed(reviews):
        if not is_bot_login(
            (review.get("user") or {}).get("login"),
            publisher_login=publisher_login,
        ):
            continue
        body = review.get("body") or ""
        state = decode_state(body)
        if not valid_manifest(
            state,
            repository=repository,
            pull_request=pull_request,
        ):
            continue
        if INLINE_FALLBACK_MARKER in body:
            for finding in state["findings"].values():
                if isinstance(finding, dict) and not finding.get("thread_id"):
                    finding["thread_required"] = False
        state.setdefault("cursor", {})["review_id"] = review.get("id")
        return state
    return None


def compare_commits(
    repository: str,
    previous: str,
    current: str,
) -> dict[str, Any] | None:
    result = run(
        [
            "gh",
            "api",
            f"repos/{repository}/compare/{previous}...{current}",
        ],
        check=False,
    )
    if result.returncode != 0:
        return None
    value = json.loads(result.stdout)
    return value if isinstance(value, dict) else None


def latest_reviewed_head(
    reviews: list[dict[str, Any]],
    *,
    publisher_login: str | None = None,
) -> str | None:
    for review in reversed(reviews):
        login = (review.get("user") or {}).get("login")
        commit_id = review.get("commit_id")
        if (
            is_stateful_review(
                login,
                str(review.get("body") or ""),
                publisher_login=publisher_login,
            )
            and commit_id
        ):
            return str(commit_id)
    return None


def review_threads(repository: str, pull_request: int) -> list[dict[str, Any]]:
    owner, name = repository.split("/", 1)
    query = """
query($owner:String!, $name:String!, $number:Int!, $cursor:String) {
  repository(owner:$owner, name:$name) {
    pullRequest(number:$number) {
      reviewThreads(first:100, after:$cursor) {
        nodes {
          id
          isResolved
          isOutdated
          comments(first:20) {
            nodes {
              author { login }
              body
              path
              line
              originalLine
              url
              databaseId
              pullRequestReview {
                databaseId
                body
                author { login }
              }
            }
          }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}
"""
    threads: list[dict[str, Any]] = []
    cursor: str | None = None
    while True:
        command = [
            "api",
            "graphql",
            "-f",
            f"query={query}",
            "-f",
            f"owner={owner}",
            "-f",
            f"name={name}",
            "-F",
            f"number={pull_request}",
        ]
        if cursor:
            command.extend(["-f", f"cursor={cursor}"])
        data = gh_json(command)
        connection = (
            data.get("data", {})
            .get("repository", {})
            .get("pullRequest", {})
            .get("reviewThreads", {})
        )
        threads.extend(connection.get("nodes", []))
        page_info = connection.get("pageInfo", {})
        if not page_info.get("hasNextPage"):
            return threads
        cursor = page_info.get("endCursor")
        if not cursor:
            raise PipelineError("review thread pagination returned no cursor")


def import_legacy_findings(
    manifest: dict[str, Any],
    threads: list[dict[str, Any]],
    *,
    publisher_login: str | None = None,
) -> None:
    known_threads: dict[str, dict[str, Any]] = {}
    known_comments: dict[int, dict[str, Any]] = {}
    for value in manifest["findings"].values():
        if not isinstance(value, dict):
            continue
        if value.get("thread_id"):
            known_threads[str(value["thread_id"])] = value
        if value.get("comment_id"):
            known_comments[int(value["comment_id"])] = value
    for thread in threads:
        comments = (thread.get("comments") or {}).get("nodes") or []
        if thread.get("isResolved") or not comments:
            continue
        first = comments[0]
        if not is_owned_review_comment(
            first,
            repository=str(manifest.get("repository") or ""),
            pull_request=int(manifest.get("pull_request") or 0),
            publisher_login=publisher_login,
        ):
            continue
        thread_id = thread.get("id")
        comment_id = int(first.get("databaseId") or 0)
        if not thread_id or thread_id in known_threads:
            continue
        if comment_id in known_comments:
            known_comments[comment_id]["thread_id"] = thread_id
            known_comments[comment_id]["thread_url"] = first.get("url")
            known_comments[comment_id]["thread_required"] = True
            continue
        matching_findings = [
            value
            for value in manifest["findings"].values()
            if isinstance(value, dict)
            and value.get("status") == "open"
            and not value.get("thread_id")
            and value.get("path") == first.get("path")
            and value.get("line")
            == (first.get("line") or first.get("originalLine"))
            and value.get("title")
            and value["title"] in (first.get("body") or "")
        ]
        if matching_findings:
            matching_findings[0]["thread_id"] = thread_id
            matching_findings[0]["comment_id"] = comment_id or None
            matching_findings[0]["thread_url"] = first.get("url")
            matching_findings[0]["thread_required"] = True
            continue
        legacy_id = f"F-legacy-{hashlib.sha256(thread_id.encode()).hexdigest()[:8]}"
        title = sanitize_text(first.get("body"), maximum=160)
        manifest["findings"][legacy_id] = {
            "fingerprint": None,
            "status": "open",
            "thread_resolution": "unresolved",
            "severity": "major",
            "confidence": "high",
            "title": title,
            "path": first.get("path"),
            "symbol": "",
            "line": first.get("line") or first.get("originalLine"),
            "thread_id": thread_id,
            "comment_id": comment_id or None,
            "thread_url": first.get("url"),
            "thread_required": True,
            "first_seen_sha": None,
            "last_checked_sha": None,
            "resolved_sha": None,
        }


def sync_manifest_threads(
    manifest: dict[str, Any],
    threads: list[dict[str, Any]],
) -> None:
    thread_status = {
        str(thread["id"]): bool(thread.get("isResolved"))
        for thread in threads
        if thread.get("id")
    }
    for finding in manifest["findings"].values():
        if not isinstance(finding, dict) or not finding.get("thread_id"):
            continue
        resolved = thread_status.get(str(finding["thread_id"]))
        if resolved is True:
            finding["status"] = "resolved"
            finding["thread_resolution"] = "confirmed"
        elif resolved is False:
            if (
                finding.get("status") == "resolved"
                and finding.get("thread_resolution") == "confirmed"
            ):
                finding["status"] = "open"
                finding["resolved_sha"] = None
                finding["thread_resolution"] = "unresolved"
            elif finding.get("status") == "resolved":
                # An unresolved GitHub thread is expected when publication used
                # the job token and deliberately skipped thread resolution.
                # Preserve the code-level disposition until a capable identity
                # can resolve the thread.
                finding["thread_resolution"] = "skipped"
            else:
                finding["thread_resolution"] = "unresolved"


def write_github_output(values: dict[str, Any]) -> None:
    output_path = os.environ.get("GITHUB_OUTPUT")
    if not output_path:
        return
    with Path(output_path).open("a", encoding="utf-8") as output:
        for key, value in values.items():
            output.write(f"{key}={value}\n")


def prepare(args: argparse.Namespace) -> None:
    action_dir = Path(__file__).resolve().parent
    state_dir = Path(args.state_dir)
    state_dir.mkdir(parents=True, exist_ok=True)

    pipeline_version = hash_files(
        [
            action_dir / "action.yml",
            action_dir / "review_pipeline.py",
            action_dir / "review-output.schema.json",
        ]
    )
    rubric_version = hash_files(
        [
            action_dir / "rubric.md",
            action_dir / "rubric-detail.md",
            action_dir / "premortem.md",
        ]
    )
    publisher_login = authenticated_login()

    pull = gh_json(
        ["api", f"repos/{args.repository}/pulls/{args.pull_request}"]
    )
    base_sha, current_head = pull_base_head(pull)
    expected_head = str(args.event_head or current_head)
    expected_base = str(args.event_base or base_sha)
    require_expected_pull(
        pull,
        expected_base=expected_base,
        expected_head=expected_head,
        context="before preparation",
    )
    comments = gh_pages(
        f"repos/{args.repository}/issues/{args.pull_request}/comments?per_page=100"
    )
    reviews = gh_pages(
        f"repos/{args.repository}/pulls/{args.pull_request}/reviews?per_page=100"
    )
    files = gh_pages(
        f"repos/{args.repository}/pulls/{args.pull_request}/files?per_page=100"
    )
    threads = review_threads(args.repository, args.pull_request)

    sticky_state, sticky_comment_id = load_sticky_state(
        comments,
        repository=args.repository,
        pull_request=args.pull_request,
        publisher_login=publisher_login,
    )
    review_state = load_review_state(
        reviews,
        repository=args.repository,
        pull_request=args.pull_request,
        publisher_login=publisher_login,
    )
    prior_state = sticky_state or review_state
    manifest = (
        copy.deepcopy(prior_state)
        if prior_state is not None
        else empty_manifest(
            repository=args.repository,
            pull_request=args.pull_request,
            pipeline_version=pipeline_version,
            rubric_version=rubric_version,
        )
    )
    import_legacy_findings(
        manifest,
        threads,
        publisher_login=publisher_login,
    )
    sync_manifest_threads(manifest, threads)

    previous_head = (
        manifest.get("cursor", {}).get("last_published_head")
        or latest_reviewed_head(
            reviews,
            publisher_login=publisher_login,
        )
    )
    version_matches = (
        prior_state is not None
        and manifest.get("reviewer", {}).get("pipeline_version")
        == pipeline_version
        and manifest.get("reviewer", {}).get("rubric_version") == rubric_version
        and manifest.get("reviewer", {}).get("model_policy_version")
        == MODEL_POLICY_VERSION
        and canonical_login(
            manifest.get("reviewer", {}).get("publisher_login")
        )
        == canonical_login(publisher_login)
    )

    mode = "full"
    mode_reason = "no previous automated review"
    incremental_paths: list[str] = []
    comparison = (
        compare_commits(args.repository, previous_head, current_head)
        if previous_head and previous_head != current_head
        else None
    )
    comparison_files = (
        comparison.get("files", []) if isinstance(comparison, dict) else []
    )
    comparison_complete = len(comparison_files) < 300
    if previous_head == current_head and version_matches:
        mode = "skip"
        mode_reason = "current head already reviewed"
    elif (
        previous_head
        and version_matches
        and comparison
        and comparison.get("status") in {"ahead", "identical"}
        and comparison_complete
    ):
        mode = "incremental"
        mode_reason = "valid prior manifest and ancestor review cursor"
        incremental_paths = [
            str(file["filename"])
            for file in comparison_files
            if isinstance(file, dict) and file.get("filename")
        ]
    elif previous_head and not version_matches:
        mode_reason = "review pipeline or rubric version changed"
    elif comparison and not comparison_complete:
        mode_reason = "incremental compare exceeded the GitHub file limit"
    elif previous_head:
        mode_reason = "previous reviewed head is not an ancestor"

    full_paths = [str(file["filename"]) for file in files]
    scope_paths = incremental_paths if mode == "incremental" else full_paths
    high_risk = is_high_risk(scope_paths)
    open_high_finding_touched = any(
        finding.get("status") == "open"
        and finding.get("severity") in {"critical", "major"}
        and finding.get("path") in scope_paths
        for finding in manifest["findings"].values()
        if isinstance(finding, dict)
    )
    model_tier = (
        "strong"
        if mode == "full"
        or high_risk
        or open_high_finding_touched
        or args.review_depth == "deep"
        else "fast"
    )
    if args.premortem == "on":
        run_premortem = True
    elif args.premortem == "off":
        run_premortem = False
    else:
        run_premortem = mode == "full" or high_risk

    full_diff = run(
        [
            "gh",
            "pr",
            "diff",
            str(args.pull_request),
            "--repo",
            args.repository,
        ]
    ).stdout
    require_expected_pull(
        gh_json(
            ["api", f"repos/{args.repository}/pulls/{args.pull_request}"]
        ),
        expected_base=expected_base,
        expected_head=expected_head,
        context="during preparation",
    )
    (state_dir / "full.diff").write_text(full_diff, encoding="utf-8")
    if mode == "incremental":
        incremental_diff = "\n".join(
            (
                f"diff --git a/{file['filename']} b/{file['filename']}\n"
                f"--- a/{file['filename']}\n"
                f"+++ b/{file['filename']}\n"
                f"{file.get('patch') or ''}"
            )
            for file in comparison_files
            if isinstance(file, dict) and file.get("filename")
        )
    else:
        incremental_diff = full_diff
    (state_dir / "review.diff").write_text(incremental_diff, encoding="utf-8")

    commentable_lines = {
        str(file["filename"]): sorted(
            parse_patch_lines(str(file.get("patch") or ""))
        )
        for file in files
    }
    input_value = {
        "schema_version": SCHEMA_VERSION,
        "repository": args.repository,
        "pull_request": args.pull_request,
        "pull_request_data": {
            "title": pull.get("title"),
            "body": pull.get("body"),
            "base_ref": pull["base"]["ref"],
            "base_sha": base_sha,
            "head_ref": pull["head"]["ref"],
            "head_sha": current_head,
        },
        "review_scope": {
            "mode": mode,
            "reason": mode_reason,
            "previous_reviewed_head": previous_head,
            "current_head": current_head,
            "changed_paths": scope_paths,
            "full_pr_paths": full_paths,
            "high_risk": high_risk,
            "model_tier": model_tier,
            "run_premortem": run_premortem,
        },
        "manifest": manifest,
        "review_threads": threads,
        "commentable_lines": commentable_lines,
        "sticky_comment_id": sticky_comment_id,
        "publisher_login": publisher_login,
        "thread_resolution_enabled": args.resolve_threads == "true",
        "pipeline_version": pipeline_version,
        "rubric_version": rubric_version,
    }
    (state_dir / "review-input.json").write_text(
        json.dumps(input_value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    schema = json.loads(
        (action_dir / "review-output.schema.json").read_text(encoding="utf-8")
    )
    write_github_output(
        {
            "mode": mode,
            "model_tier": model_tier,
            "run_premortem": str(run_premortem).lower(),
            "previous_head": previous_head or "",
            "current_head": current_head,
            "output_schema": compact_json(schema),
        }
    )


def validate_model_output(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise PipelineError("structured review output must be an object")
    required = {
        "scope_summary",
        "findings",
        "open_questions",
        "prior_findings",
    }
    if not required.issubset(value):
        missing = ", ".join(sorted(required - set(value)))
        raise PipelineError(f"structured review output missing: {missing}")
    for field in ("findings", "open_questions", "prior_findings"):
        if not isinstance(value[field], list):
            raise PipelineError(f"{field} must be an array")
    return value


def scope_label(review_input: dict[str, Any]) -> str:
    scope = review_input["review_scope"]
    previous = scope.get("previous_reviewed_head")
    current = scope["current_head"]
    if scope["mode"] == "incremental" and previous:
        return f"`{previous[:8]}..{current[:8]}`"
    return f"head `{current[:8]}`"


def render_finding(finding: dict[str, Any]) -> str:
    severity = finding["severity"].capitalize()
    title = public_text(finding["title"], maximum=160)
    impact = public_text(finding["impact"], maximum=800)
    fix = public_text(finding["suggested_fix"], maximum=800)
    return (
        f"**[{severity}]** {title}\n\n"
        f"{impact}\n\n"
        f"Suggested fix: {fix}"
    )


def render_question(question: dict[str, Any]) -> str:
    confidence = question["confidence"].capitalize()
    text = public_text(question["question"], maximum=500)
    why = public_text(question["why_it_matters"], maximum=600)
    verify = public_text(question["verification"], maximum=600)
    return (
        f"❓ **Open question · {confidence} confidence**\n"
        f"- {text}\n"
        f"- Why it matters: {why}\n"
        f"- How to verify: {verify}"
    )


def compile_review(
    review_input: dict[str, Any],
    model_output: dict[str, Any] | None,
) -> dict[str, Any]:
    manifest = copy.deepcopy(review_input["manifest"])
    scope = review_input["review_scope"]
    head = scope["current_head"]
    round_key = (
        f"{review_input['repository']}#{review_input['pull_request']}@"
        f"{head}:{review_input['pipeline_version']}:"
        f"{review_input['rubric_version']}:{MODEL_POLICY_VERSION}"
    )
    round_id = hashlib.sha256(round_key.encode()).hexdigest()[:20]
    round_marker = (
        f"<!-- claude-review-round:v1 "
        f"{round_id} -->"
    )

    if scope["mode"] == "skip":
        model_output = {
            "scope_summary": "No changes since the last completed review.",
            "findings": [],
            "open_questions": [],
            "prior_findings": [
                {
                    "finding_id": item_id,
                    "disposition": "open",
                    "reason": "No changes were analyzed in skip mode.",
                }
                for item_id, item in manifest["findings"].items()
                if isinstance(item, dict) and item.get("status") == "open"
            ],
        }
    model_output = validate_model_output(model_output)

    expected_prior_ids = {
        item_id
        for item_id, item in manifest["findings"].items()
        if isinstance(item, dict) and item.get("status") == "open"
    }
    returned_prior_ids = [
        str(item.get("finding_id") or "")
        for item in model_output["prior_findings"]
        if isinstance(item, dict)
    ]
    if len(returned_prior_ids) != len(set(returned_prior_ids)):
        raise PipelineError("prior_findings contains duplicate finding IDs")
    unknown = sorted(set(returned_prior_ids) - expected_prior_ids)
    if unknown:
        raise PipelineError(
            "prior_findings references findings that are not open "
            f"(unknown={unknown})"
        )

    scope_summary = public_text(
        model_output["scope_summary"],
        maximum=240,
    )
    if INTERNAL_TERMS_RE.search(scope_summary):
        scope_summary = (
            f"Reviewed {len(scope['changed_paths'])} changed file(s)."
        )

    resolution_ids: list[str] = []
    resolution_enabled = bool(
        review_input.get("thread_resolution_enabled", False)
    )
    for disposition in model_output["prior_findings"]:
        if not isinstance(disposition, dict):
            raise PipelineError("prior_findings contains a non-object")
        item_id = str(disposition.get("finding_id") or "")
        item = manifest["findings"].get(item_id)
        if not isinstance(item, dict):
            raise PipelineError(f"prior_findings references unknown ID: {item_id}")
        status = disposition.get("disposition")
        if status not in {"open", "resolved"}:
            raise PipelineError(
                f"prior_findings has invalid disposition for {item_id}"
            )
        item["status"] = status
        item["last_checked_sha"] = head
        if status == "resolved":
            if item.get("thread_required") and not item.get("thread_id"):
                raise PipelineError(
                    f"cannot resolve inline finding {item_id} without "
                    "a GitHub thread ID"
                )
            item["resolved_sha"] = head
            if item.get("thread_id"):
                item["thread_resolution"] = (
                    "pending" if resolution_enabled else "skipped"
                )
        elif item.get("thread_id"):
            item["thread_resolution"] = "unresolved"

    if resolution_enabled:
        resolution_ids = sorted(
            {
                str(item["thread_id"])
                for item in manifest["findings"].values()
                if isinstance(item, dict)
                and item.get("status") == "resolved"
                and item.get("thread_id")
                and item.get("thread_resolution") != "confirmed"
            }
        )

    changed_paths = set(scope["full_pr_paths"])
    commentable = {
        path: set(lines)
        for path, lines in review_input["commentable_lines"].items()
    }
    findings: list[dict[str, Any]] = []
    for index, raw in enumerate(model_output["findings"]):
        if not isinstance(raw, dict):
            raise PipelineError(f"finding {index} is not an object")
        severity = str(raw.get("severity", "")).lower()
        confidence = str(raw.get("confidence", "")).lower()
        path = canonicalize_path(raw.get("path"))
        if (
            severity not in SEVERITIES
            or confidence != "high"
        ):
            raise PipelineError(
                f"finding {index} has invalid severity or confidence"
            )
        if path not in changed_paths:
            raise PipelineError(
                f"finding {index} references unchanged path: {path!r}"
            )
        try:
            line = int(raw["line"])
        except (KeyError, TypeError, ValueError):
            raise PipelineError(f"finding {index} has an invalid line")
        if isinstance(raw.get("line"), bool) or line < 1:
            raise PipelineError(f"finding {index} has an invalid line")
        finding = {
            "title": public_text(raw.get("title"), maximum=160),
            "path": path,
            "symbol": sanitize_text(raw.get("symbol"), maximum=200),
            "line": line,
            "start_line": raw.get("start_line"),
            "severity": severity,
            "confidence": confidence,
            "root_cause": sanitize_text(
                raw.get("root_cause"),
                maximum=600,
            ),
            "impact": public_text(raw.get("impact"), maximum=800),
            "suggested_fix": public_text(
                raw.get("suggested_fix"),
                maximum=800,
            ),
        }
        if not all(
            finding[field]
            for field in ("title", "path", "root_cause", "impact", "suggested_fix")
        ):
            raise PipelineError(f"finding {index} is missing required text")
        prior_finding_id = raw.get("prior_finding_id")
        if (
            prior_finding_id
            and isinstance(manifest["findings"].get(prior_finding_id), dict)
            and manifest["findings"][prior_finding_id].get("status") == "open"
        ):
            manifest["findings"][prior_finding_id]["last_checked_sha"] = head
            continue
        finding["finding_id"] = finding_id(finding)
        existing = manifest["findings"].get(finding["finding_id"])
        if isinstance(existing, dict) and existing.get("status") == "open":
            existing["last_checked_sha"] = head
            continue
        finding["inline"] = line in commentable.get(path, set())
        findings.append(finding)

    high = [f for f in findings if f["severity"] in {"critical", "major"}][:5]
    low = [f for f in findings if f["severity"] in {"minor", "nit"}][:5]
    findings = high + low

    questions: list[dict[str, Any]] = []
    for index, raw in enumerate(model_output["open_questions"][:3]):
        if not isinstance(raw, dict):
            raise PipelineError(f"open question {index} is not an object")
        confidence = str(raw.get("confidence", "")).lower()
        if confidence not in QUESTION_CONFIDENCE:
            raise PipelineError(
                f"open question {index} has invalid confidence"
            )
        question = {
            "question": public_text(raw.get("question"), maximum=500),
            "confidence": confidence,
            "why_it_matters": public_text(
                raw.get("why_it_matters"),
                maximum=600,
            ),
            "verification": public_text(
                raw.get("verification"),
                maximum=600,
            ),
        }
        if not all(question.values()):
            raise PipelineError(f"open question {index} is incomplete")
        questions.append(question)

    for finding in findings:
        item_id = finding["finding_id"]
        existing = manifest["findings"].get(item_id, {})
        manifest["findings"][item_id] = {
            "fingerprint": item_id,
            "status": "open",
            "thread_resolution": "unresolved",
            "severity": finding["severity"],
            "confidence": finding["confidence"],
            "title": finding["title"],
            "path": finding["path"],
            "symbol": finding["symbol"],
            "line": finding["line"],
            "thread_id": existing.get("thread_id"),
            "comment_id": existing.get("comment_id"),
            "thread_url": existing.get("thread_url"),
            "thread_required": finding["inline"],
            "first_seen_sha": existing.get("first_seen_sha") or head,
            "last_checked_sha": head,
            "resolved_sha": None,
        }

    open_findings = [
        item
        for item in manifest["findings"].values()
        if isinstance(item, dict) and item.get("status") == "open"
    ]
    resolved_count = sum(
        1
        for item in manifest["findings"].values()
        if isinstance(item, dict) and item.get("resolved_sha") == head
    )
    critical_count = sum(f["severity"] == "critical" for f in findings)
    major_count = sum(f["severity"] == "major" for f in findings)
    suggestion_count = sum(
        f["severity"] in {"minor", "nit"} for f in findings
    )
    scope_text = scope_label(review_input)

    inline_comments: list[dict[str, Any]] = []
    body_only: list[str] = []
    for finding in findings:
        body = render_finding(finding)
        if finding["inline"]:
            comment = {
                "finding_id": finding["finding_id"],
                "path": finding["path"],
                "line": finding["line"],
                "side": "RIGHT",
                "body": body,
            }
            start_line = finding.get("start_line")
            if (
                isinstance(start_line, int)
                and start_line < finding["line"]
                and start_line in commentable.get(finding["path"], set())
            ):
                comment["start_line"] = start_line
                comment["start_side"] = "RIGHT"
            inline_comments.append(comment)
        else:
            body_only.append(
                f"- `{finding['path']}:{finding['line']}` — "
                f"**[{finding['severity'].capitalize()}]** "
                f"{finding['title']} {finding['impact']} "
                f"Suggested fix: {finding['suggested_fix']}"
            )

    sections: list[str] = []
    if findings:
        sections.extend(
            [
                f"⚠️ Review needs attention — {len(findings)} finding(s)",
                (
                    f"{critical_count} blocking · {major_count} should-fix · "
                    f"{suggestion_count} suggestion(s) · "
                    f"{len(questions)} open question(s)"
                ),
                f"Reviewed {scope_text}.",
            ]
        )
        if inline_comments:
            sections.append("Details are attached inline.")
        if body_only:
            sections.append(
                "Findings without inline anchors:\n" + "\n".join(body_only)
            )
    elif questions:
        sections.extend(
            [
                f"❓ Review complete — {len(questions)} open question(s)",
                f"Reviewed {scope_text}.",
                scope_summary,
            ]
        )
    else:
        sections.extend(
            [
                "✅ Re-review clean"
                if scope["mode"] == "incremental"
                else "✅ Review clean",
                (
                    f"{resolved_count} prior finding(s) resolved · "
                    f"0 new · {len(open_findings)} open"
                ),
                f"Reviewed {scope_text}.",
                scope_summary,
            ]
        )
    if questions:
        sections.append(
            "Open questions:\n"
            + "\n\n".join(render_question(question) for question in questions)
        )
    review_body = "\n\n".join(section for section in sections if section)

    status_icon = "⚠️" if open_findings or findings else "✅"
    status_title = (
        f"{status_icon} {len(open_findings)} open finding(s)"
        if open_findings
        else f"{status_icon} Review clean"
    )
    status_body = (
        "## Claude review status\n\n"
        f"{status_title}\n\n"
        f"Last reviewed: {scope_text}\n\n"
        f"New this round: {len(findings)} · "
        f"Resolved this round: {resolved_count} · "
        f"Open questions: {len(questions)}"
    )

    manifest["reviewer"] = {
        "pipeline_version": review_input["pipeline_version"],
        "rubric_version": review_input["rubric_version"],
        "model_policy_version": MODEL_POLICY_VERSION,
        "publisher_login": review_input.get("publisher_login"),
    }
    round_value = {
        "round_id": round_id,
        "from": scope.get("previous_reviewed_head"),
        "to": head,
        "mode": scope["mode"],
        "result": (
            "findings"
            if findings
            else "questions"
            if questions
            else "clean"
        ),
        "new_findings": len(findings),
        "resolved_findings": resolved_count,
        "open_findings": len(open_findings),
        "review_id": None,
    }
    review_manifest = copy.deepcopy(manifest)
    review_manifest["cursor"] = {
        "last_published_head": head,
        "base_branch_sha": review_input["pull_request_data"]["base_sha"],
        "review_id": None,
        "reviewed_at": None,
        "mode": scope["mode"],
    }
    review_manifest.setdefault("rounds", []).append(copy.deepcopy(round_value))
    prune_manifest(review_manifest)
    review_body = (
        f"{review_body}\n\n{round_marker}\n"
        f"{STATE_MARKER_PREFIX}{encode_state(review_manifest)} -->"
    )

    return {
        "schema_version": SCHEMA_VERSION,
        "repository": review_input["repository"],
        "pull_request": review_input["pull_request"],
        "publisher_login": review_input.get("publisher_login"),
        "frozen_head": head,
        "base_sha": review_input["pull_request_data"]["base_sha"],
        "mode": scope["mode"],
        "round_marker": round_marker,
        "review_body": review_body,
        "inline_comments": inline_comments,
        "body_only_findings": body_only,
        "resolve_thread_ids": sorted(set(resolution_ids)),
        "should_submit_review": bool(findings or questions),
        "sticky_comment_id": review_input.get("sticky_comment_id"),
        "status_body": status_body,
        "manifest": manifest,
        "round": round_value,
        "verdict": round_value["result"],
    }


def compile_command(args: argparse.Namespace) -> None:
    state_dir = Path(args.state_dir)
    review_input = json.loads(
        (state_dir / "review-input.json").read_text(encoding="utf-8")
    )
    if review_input["review_scope"]["mode"] == "skip":
        model_output = None
    else:
        raw = os.environ.get("REVIEW_STRUCTURED_OUTPUT", "")
        if not raw:
            raise PipelineError("Claude returned no structured review output")
        model_output = json.loads(raw)
    payload = compile_review(review_input, model_output)
    (state_dir / "review-payload.json").write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    write_github_output({"verdict": payload["verdict"]})


def existing_round_review(
    repository: str,
    pull_request: int,
    marker: str,
    commit_id: str,
    *,
    publisher_login: str | None = None,
) -> int | None:
    reviews = gh_pages(
        f"repos/{repository}/pulls/{pull_request}/reviews?per_page=100"
    )
    for review in reversed(reviews):
        login = str((review.get("user") or {}).get("login") or "")
        if not is_bot_login(login, publisher_login=publisher_login):
            continue
        if str(review.get("commit_id") or "") != commit_id:
            continue
        if marker in (review.get("body") or ""):
            return int(review["id"])
    return None


def review_used_inline_fallback(
    repository: str,
    pull_request: int,
    review_id: int,
) -> bool:
    review = gh_json(
        [
            "api",
            f"repos/{repository}/pulls/{pull_request}/reviews/{review_id}",
        ]
    )
    return INLINE_FALLBACK_MARKER in str((review or {}).get("body") or "")


def match_review_comments(
    repository: str,
    pull_request: int,
    review_id: int,
    expected_comments: list[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    if not expected_comments:
        return {}
    posted: dict[str, dict[str, Any]] = {}
    for attempt in range(GITHUB_LINK_RETRY_ATTEMPTS):
        posted_comments = gh_pages(
            f"repos/{repository}/pulls/{pull_request}/reviews/"
            f"{review_id}/comments?per_page=100"
        )
        used_ids: set[int] = set()
        posted = {}
        for expected in expected_comments:
            matches = []
            for comment in posted_comments:
                comment_id = int(comment.get("id") or 0)
                line = comment.get("line") or comment.get("original_line")
                if (
                    comment_id not in used_ids
                    and comment.get("path") == expected["path"]
                    and comment.get("body") == expected["body"]
                    and (line is None or line == expected["line"])
                ):
                    matches.append(comment)
            if not matches:
                continue
            comment = max(matches, key=lambda item: int(item.get("id") or 0))
            comment_id = int(comment.get("id") or 0)
            used_ids.add(comment_id)
            posted[expected["finding_id"]] = {
                "comment_id": comment_id or None,
                "thread_url": comment.get("html_url"),
            }
        if len(posted) == len(expected_comments):
            return posted
        if attempt + 1 < GITHUB_LINK_RETRY_ATTEMPTS:
            time.sleep(GITHUB_LINK_RETRY_DELAY_SECONDS)
    return posted


def recover_existing_review(
    repository: str,
    pull_request: int,
    review_id: int,
    expected_comments: list[dict[str, Any]],
) -> tuple[dict[str, dict[str, Any]], bool]:
    inline_fallback = review_used_inline_fallback(
        repository,
        pull_request,
        review_id,
    )
    posted = (
        {}
        if inline_fallback
        else match_review_comments(
            repository,
            pull_request,
            review_id,
            expected_comments,
        )
    )
    return posted, bool(expected_comments) and not inline_fallback


def submit_review(
    payload: dict[str, Any],
    *,
    before_write: Callable[[], None] | None = None,
) -> tuple[int | None, dict[str, dict[str, Any]], bool]:
    if not payload["should_submit_review"]:
        return None, {}, False
    existing = existing_round_review(
        payload["repository"],
        payload["pull_request"],
        payload["round_marker"],
        payload["frozen_head"],
        publisher_login=payload.get("publisher_login"),
    )
    if existing is not None:
        posted, inline_published = recover_existing_review(
            payload["repository"],
            payload["pull_request"],
            existing,
            payload["inline_comments"],
        )
        return existing, posted, inline_published

    repository = payload["repository"]
    pull_request = payload["pull_request"]
    comments = [
        {
            key: value
            for key, value in comment.items()
            if key != "finding_id"
        }
        for comment in payload["inline_comments"]
    ]
    request = {
        "commit_id": payload["frozen_head"],
        "event": "COMMENT",
        "body": payload["review_body"],
        "comments": comments,
    }
    if before_write is not None:
        before_write()
    result = run(
        [
            "gh",
            "api",
            f"repos/{repository}/pulls/{pull_request}/reviews",
            "--method",
            "POST",
            "--input",
            "-",
        ],
        input_text=compact_json(request),
        check=False,
    )
    if result.returncode != 0:
        existing = existing_round_review(
            repository,
            pull_request,
            payload["round_marker"],
            payload["frozen_head"],
            publisher_login=payload.get("publisher_login"),
        )
        if existing is not None:
            posted, inline_published = recover_existing_review(
                repository,
                pull_request,
                existing,
                payload["inline_comments"],
            )
            return existing, posted, inline_published
        fallback = [
            f"- `{comment['path']}:{comment['line']}` — "
            f"{sanitize_text(comment['body'], maximum=1800)}"
            for comment in payload["inline_comments"]
        ]
        body = payload["review_body"]
        if fallback:
            body += (
                "\n\nFindings without inline anchors:\n"
                + "\n".join(fallback)
            )
        body += f"\n\n{INLINE_FALLBACK_MARKER}"
        if before_write is not None:
            before_write()
        response = gh_json(
            [
                "api",
                f"repos/{repository}/pulls/{pull_request}/reviews",
                "--method",
                "POST",
            ],
            input_value={
                "commit_id": payload["frozen_head"],
                "event": "COMMENT",
                "body": body,
            },
        )
        return int(response["id"]), {}, False

    response = json.loads(result.stdout)
    review_id = int(response["id"])
    posted = match_review_comments(
        repository,
        pull_request,
        review_id,
        payload["inline_comments"],
    )
    return review_id, posted, bool(payload["inline_comments"])


def resolve_threads(
    thread_ids: list[str],
    *,
    enabled: bool = False,
    before_write: Callable[[], None] | None = None,
) -> set[str]:
    if not enabled:
        return set()

    mutation = """
mutation($threadId:ID!) {
  resolveReviewThread(input:{threadId:$threadId}) {
    thread { id isResolved }
  }
}
"""
    resolved: set[str] = set()
    for thread_id in thread_ids:
        if before_write is not None:
            before_write()
        response = gh_json(
            [
                "api",
                "graphql",
                "-f",
                f"query={mutation}",
                "-f",
                f"threadId={thread_id}",
            ]
        )
        thread = (
            (response or {})
            .get("data", {})
            .get("resolveReviewThread", {})
            .get("thread", {})
        )
        if (
            str(thread.get("id") or "") != thread_id
            or thread.get("isResolved") is not True
        ):
            raise PipelineError(
                f"GitHub did not confirm resolution of review thread {thread_id}"
            )
        resolved.add(thread_id)
    return resolved


def attach_published_threads(
    payload: dict[str, Any],
    manifest: dict[str, Any],
    review_id: int,
) -> None:
    published_ids = {
        published["finding_id"] for published in payload["inline_comments"]
    }
    for attempt in range(GITHUB_LINK_RETRY_ATTEMPTS):
        threads = review_threads(payload["repository"], payload["pull_request"])
        for published in payload["inline_comments"]:
            finding = manifest["findings"].get(published["finding_id"])
            if not isinstance(finding, dict) or finding.get("thread_id"):
                continue
            published_comment_id = int(finding.get("comment_id") or 0)
            candidates: list[tuple[int, dict[str, Any], dict[str, Any]]] = []
            for thread in threads:
                comments = (thread.get("comments") or {}).get("nodes") or []
                if not comments:
                    continue
                first = comments[0]
                database_id = int(first.get("databaseId") or 0)
                parent_review_id = int(
                    (
                        first.get("pullRequestReview") or {}
                    ).get("databaseId")
                    or 0
                )
                exact_comment = (
                    published_comment_id
                    and database_id == published_comment_id
                    and parent_review_id == review_id
                )
                semantic_match = (
                    not published_comment_id
                    and parent_review_id == review_id
                    and first.get("path") == published["path"]
                    and (first.get("line") or first.get("originalLine"))
                    == published["line"]
                    and first.get("body") == published["body"]
                )
                if exact_comment or semantic_match:
                    candidates.append((database_id, thread, first))
            if not candidates:
                continue
            _, thread, first = max(candidates, key=lambda item: item[0])
            finding["thread_id"] = thread.get("id")
            finding["comment_id"] = int(first.get("databaseId") or 0) or None
            finding["thread_url"] = first.get("url")
            finding["thread_required"] = True
        missing = sorted(
            finding_id_value
            for finding_id_value in published_ids
            if not (
                isinstance(manifest["findings"].get(finding_id_value), dict)
                and manifest["findings"][finding_id_value].get("thread_id")
            )
        )
        if not missing:
            return
        if attempt + 1 < GITHUB_LINK_RETRY_ATTEMPTS:
            time.sleep(GITHUB_LINK_RETRY_DELAY_SECONDS)
    raise PipelineError(
        "could not associate published inline findings with GitHub threads: "
        + ", ".join(missing)
    )


def upsert_sticky(
    payload: dict[str, Any],
    manifest: dict[str, Any],
    *,
    before_write: Callable[[], None] | None = None,
) -> int:
    body = (
        f"{payload['status_body']}\n\n"
        f"{STATE_MARKER_PREFIX}{encode_state(manifest)} -->"
    )
    repository = payload["repository"]
    comment_id = payload.get("sticky_comment_id")
    if comment_id:
        if before_write is not None:
            before_write()
        comment = gh_json(
            [
                "api",
                f"repos/{repository}/issues/comments/{comment_id}",
                "--method",
                "PATCH",
            ],
            input_value={"body": body},
        )
    else:
        if before_write is not None:
            before_write()
        comment = gh_json(
            [
                "api",
                f"repos/{repository}/issues/{payload['pull_request']}/comments",
                "--method",
                "POST",
            ],
            input_value={"body": body},
        )
    return int(comment["id"])


def prune_manifest(manifest: dict[str, Any]) -> None:
    manifest["rounds"] = manifest.get("rounds", [])[-20:]
    findings = manifest.get("findings", {})
    open_items = [
        (item_id, item)
        for item_id, item in findings.items()
        if isinstance(item, dict) and item.get("status") == "open"
    ]
    resolved_items = [
        (item_id, item)
        for item_id, item in findings.items()
        if isinstance(item, dict) and item.get("status") != "open"
    ]
    resolved_items.sort(
        key=lambda pair: str(pair[1].get("last_checked_sha") or ""),
        reverse=True,
    )
    manifest["findings"] = dict(open_items + resolved_items[:30])


def write_step_summary(payload: dict[str, Any], *, stale: bool = False) -> None:
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if not summary_path:
        return
    if stale:
        body = (
            "## Claude PR review\n\n"
            "Review output was discarded because the pull request head changed "
            "during analysis.\n"
        )
    else:
        body = (
            "## Claude PR review\n\n"
            f"- Verdict: `{payload['verdict']}`\n"
            f"- Mode: `{payload['mode']}`\n"
            f"- Head: `{payload['frozen_head']}`\n"
        )
    with Path(summary_path).open("a", encoding="utf-8") as summary:
        summary.write(body)


def publish(args: argparse.Namespace) -> None:
    state_dir = Path(args.state_dir)
    payload_path = state_dir / "review-payload.json"
    payload = json.loads(payload_path.read_text(encoding="utf-8"))
    if payload["mode"] == "skip":
        write_step_summary(payload)
        write_github_output({"published": "false", "stale": "false"})
        return

    def require_frozen_pull() -> None:
        pull = gh_json(
            [
                "api",
                f"repos/{payload['repository']}/pulls/"
                f"{payload['pull_request']}",
            ]
        )
        require_expected_pull(
            pull,
            expected_base=str(payload["base_sha"]),
            expected_head=str(payload["frozen_head"]),
            context="before GitHub mutation",
        )

    try:
        require_frozen_pull()
    except StaleReviewError:
        write_step_summary(payload, stale=True)
        write_github_output({"published": "false", "stale": "true"})
        return

    try:
        review_id, posted_comments, inline_published = submit_review(
            payload,
            before_write=require_frozen_pull,
        )
        resolved_threads = resolve_threads(
            payload["resolve_thread_ids"],
            enabled=os.environ.get("GH_RESOLVE_THREADS", "").lower() == "true",
            before_write=require_frozen_pull,
        )

        manifest = payload["manifest"]
        for finding in manifest["findings"].values():
            if (
                isinstance(finding, dict)
                and finding.get("thread_id") in resolved_threads
            ):
                finding["thread_resolution"] = "confirmed"
        for finding_id_value, posted in posted_comments.items():
            finding = manifest["findings"].get(finding_id_value)
            if isinstance(finding, dict):
                finding["comment_id"] = posted.get("comment_id")
                finding["thread_url"] = posted.get("thread_url")
        if inline_published:
            if review_id is None:
                raise PipelineError(
                    "inline findings were published without a review ID"
                )
            attach_published_threads(payload, manifest, review_id)
        else:
            for published in payload["inline_comments"]:
                finding = manifest["findings"].get(published["finding_id"])
                if isinstance(finding, dict):
                    finding["thread_required"] = False
        manifest["cursor"] = {
            "last_published_head": payload["frozen_head"],
            "base_branch_sha": payload["base_sha"],
            "review_id": review_id,
            "reviewed_at": utc_now(),
            "mode": payload["mode"],
        }
        round_value = payload["round"]
        round_value["review_id"] = review_id
        rounds = manifest.setdefault("rounds", [])
        if not any(
            isinstance(item, dict)
            and item.get("round_id") == round_value["round_id"]
            for item in rounds
        ):
            rounds.append(round_value)
        manifest["rounds"] = rounds
        prune_manifest(manifest)
        sticky_id = upsert_sticky(
            payload,
            manifest,
            before_write=require_frozen_pull,
        )
    except StaleReviewError:
        write_step_summary(payload, stale=True)
        write_github_output({"published": "false", "stale": "true"})
        return

    result = {
        "review_id": review_id,
        "sticky_comment_id": sticky_id,
        "manifest": manifest,
    }
    (state_dir / "publish-result.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    write_step_summary(payload)
    write_github_output(
        {
            "published": "true",
            "stale": "false",
            "review_id": review_id or "",
        }
    )


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser()
    subparsers = value.add_subparsers(dest="command", required=True)

    prepare_parser = subparsers.add_parser("prepare")
    prepare_parser.add_argument("--repository", required=True)
    prepare_parser.add_argument("--pull-request", type=int, required=True)
    prepare_parser.add_argument("--event-head")
    prepare_parser.add_argument("--event-base")
    prepare_parser.add_argument("--state-dir", required=True)
    prepare_parser.add_argument(
        "--resolve-threads",
        choices=("true", "false"),
        default="false",
    )
    prepare_parser.add_argument(
        "--review-depth",
        choices=("standard", "deep"),
        default="standard",
    )
    prepare_parser.add_argument(
        "--premortem",
        choices=("auto", "on", "off"),
        default="auto",
    )
    prepare_parser.set_defaults(func=prepare)

    compile_parser = subparsers.add_parser("compile")
    compile_parser.add_argument("--state-dir", required=True)
    compile_parser.set_defaults(func=compile_command)

    publish_parser = subparsers.add_parser("publish")
    publish_parser.add_argument("--state-dir", required=True)
    publish_parser.set_defaults(func=publish)
    return value


def main() -> int:
    args = parser().parse_args()
    try:
        args.func(args)
    except (PipelineError, json.JSONDecodeError, OSError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
