---
name: doc-freshness
description: Detects new features and changes across MegaETH repos that are not yet documented. Use when checking for documentation gaps, auditing doc coverage after a release, looking for undocumented changes, running a periodic doc sweep, or preparing release notes.
---

# Documentation Freshness & Coverage Check

Check for undocumented changes across MegaETH repositories: $ARGUMENTS

Parse the arguments to determine the time window. Accepted inputs:

- A duration (e.g., `7d`, `14d`, `30d`) — check merged PRs in that window.
- A date (e.g., `2025-03-01`) — check merged PRs since that date.
- A git ref or tag (e.g., `v0.5.0`, `rex3-release`) — check merged PRs since that ref.
- A repo filter (e.g., `mega-evm only`, `mega-reth mega-rpc`) — restrict to specific repos.

Default (no arguments): last 14 days, all tracked repos.

## Tracked Repos

These are the repos whose changes may require documentation updates.

| Repo                     | GitHub                                  | What doc-worthy changes look like                                                                                                                                                                                                                                                                                                                                                                                                   |
| ------------------------ | --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| mega-evm                 | `megaeth-labs/mega-evm`                 | New spec, gas constant changes, new/modified system contracts, opcode behavior changes, new resource limits                                                                                                                                                                                                                                                                                                                         |
| mega-reth                | `megaeth-labs/mega-reth`                | New RPC methods, changed RPC behavior, new config flags, block execution changes, new node features                                                                                                                                                                                                                                                                                                                                 |
| mega-rpc                 | `megaeth-labs/mega-rpc`                 | New routes, changed caching/routing behavior, new error codes, rate limit changes, WebSocket changes. **Note**: mega-rpc implements the MegaETH public endpoint only. Method availability and restrictions found here may not apply to managed RPC providers (e.g., Alchemy), which have their own configurations. When reporting gaps, distinguish between "unavailable on public endpoint" and "unsupported by MegaETH entirely." |
| devops-ansible-inventory | `megaeth-labs/devops-ansible-inventory` | Network parameter changes (chain IDs, RPC URLs, explorer URLs), new network deployments, config changes                                                                                                                                                                                                                                                                                                                             |
| mega-op-contracts        | `megaeth-labs/mega-op-contracts`        | Bridge contract changes, L1/L2 interface changes, system config changes, new dispute game types                                                                                                                                                                                                                                                                                                                                     |
| mega-optimism            | `megaeth-labs/mega-optimism`            | Sequencer behavior changes, payload building changes, L1 settlement changes                                                                                                                                                                                                                                                                                                                                                         |
| dist-docs                | `megaeth-labs/dist-docs`                | Release tags — determines which mega-reth changes are live and doc-worthy. Not scanned for PRs; used only to identify the latest released version.                                                                                                                                                                                                                                                                                  |

## Workflow

### Phase 1: Collect Recent Changes

For each tracked repo, collect merged PRs in the time window.

```bash
gh pr list --repo megaeth-labs/{repo} --state merged --search "merged:>={since_date}" --json number,title,url,mergedAt,labels,body --limit 100
```

If `gh` is not available or the repo is not accessible, fall back to local git log:

```bash
git log --oneline --since="{since_date}" --merges -- .
```

For each PR, record:

- PR number and title
- Merge date
- Labels (if any)
- A one-line summary of what changed (from PR title or body)

### Phase 1.5: Determine Latest Released Version (mega-reth)

For mega-reth, only changes included in the **latest released version** should be considered for new behavior or behavior changes.
PRs merged after the latest release are unreleased and should not drive documentation updates yet.

1. **Check the dist-docs repo** for the latest release tag:
   ```bash
   gh release list --repo megaeth-labs/dist-docs --limit 5
   ```
2. **Identify the release date and tag** (e.g., `v0.6.0`, `2026-03-20`).
3. **Filter mega-reth PRs**: only include PRs merged on or before the release date. PRs merged after the latest release should be excluded from the doc-worthy triage and noted as "Unreleased — pending next release" in the report.

This does not apply to mega-rpc (deployed continuously) or mega-evm (spec changes are doc-worthy regardless of release).

### Phase 2: Triage — Doc-Worthy vs Internal

Classify each PR as **doc-worthy** or **internal-only**. A change is doc-worthy if it affects any of these surfaces:

**Always doc-worthy** (auto-include):

- New or modified RPC method (parameters, return values, error codes)
- Gas constant or limit changes
- New or modified system contract (address, interface, behavior)
- New spec or hardfork introduction
- Network parameter changes (chain ID, RPC URL, block time, explorer URL)
- New user-facing feature or behavior change
- Bridge or L1/L2 interface changes
- Breaking changes to any external API

**Usually doc-worthy** (include if impact is significant):

- New config flags that operators or integrators need to know about
- Performance characteristics that affect developer decisions
- New error codes or changed error behavior
- Deprecations

**Internal-only** (exclude):

- Pure refactoring with no behavioral change
- Test-only changes
- CI/CD pipeline changes
- Internal code reorganization
- Dependency bumps (unless they change behavior)
- Build system changes

When uncertain, include the PR in the report as "Possibly doc-worthy" with a note on why it's ambiguous.

### Phase 3: Coverage Search

For each doc-worthy change, search the documentation for existing coverage.

1. **Read `docs/SUMMARY.md`** to understand the page inventory.
2. **Search for the feature/method/constant name** across `docs/` using grep.
3. **Check the most likely target page(s)** based on the change type:

| Change type         | Check these pages first                                                                        |
| ------------------- | ---------------------------------------------------------------------------------------------- |
| Gas constant/limit  | `docs/spec/evm/dual-gas-model.md`, `docs/spec/evm/resource-limits.md`, `docs/dev/gas-model.md` |
| New system contract | `docs/spec/system-contracts/`, `docs/dev/system-contracts.md`                                  |
| RPC method          | `docs/dev/rpc/`, `docs/integration/rpc-providers.md`                                           |
| Network params      | `docs/integration/connect.md`, `docs/user/mainnet.md`, `docs/user/testnet.md`                  |
| Spec/upgrade        | `docs/spec/upgrades/`, `docs/spec/hardfork-spec.md`                                            |
| Bridge/L1           | `docs/integration/bridges.md`, `docs/dev/architecture.md`                                      |
| Wallet-facing       | `docs/integration/wallets.md`, `docs/user/`                                                    |

4. **Classify coverage**:
   - **Covered**: The change is already documented accurately.
   - **Partially covered**: The feature is mentioned but the specific change is not reflected (e.g., old values, missing new parameters).
   - **Not covered**: No mention found in any documentation page.
   - **Wrong layer**: The change is documented but in the wrong layer (e.g., spec-level detail in user docs).

### Phase 4: Prioritize Gaps

Assign priority to each gap:

| Priority | Criteria                                                                                               |
| -------- | ------------------------------------------------------------------------------------------------------ |
| **P0**   | Breaking change, incorrect values live in docs, security-relevant, or user-facing feature with no docs |
| **P1**   | New feature or behavior change that developers/integrators need to know about                          |
| **P2**   | Minor parameter change, non-breaking addition, or enhancement to existing feature                      |

### Phase 5: Report

Produce the report in the output format below.

## Output Format

```markdown
# Documentation Freshness Report

**Time window**: {since} to {now}
**Date**: {date}
**Repos scanned**: {list}
**PRs reviewed**: {total count}
**Doc-worthy changes**: {count}
**Coverage gaps found**: {count}

## Summary

| Repo                     | PRs | Doc-worthy | Covered | Gaps |
| ------------------------ | --- | ---------- | ------- | ---- |
| mega-evm                 | N   | N          | N       | N    |
| mega-reth                | N   | N          | N       | N    |
| mega-rpc                 | N   | N          | N       | N    |
| devops-ansible-inventory | N   | N          | N       | N    |
| mega-op-contracts        | N   | N          | N       | N    |
| mega-optimism            | N   | N          | N       | N    |

## Gaps (ordered by priority)

### F-001: {short description}

- **Priority**: P0 | P1 | P2
- **Source**: {repo} PR #{number} — {title} ({url})
- **Merged**: {date}
- **What changed**: {description of the change}
- **Coverage**: Not covered | Partially covered | Wrong layer
- **Target layer**: {User | Dev | Integration | Spec}
- **Target page**: {suggested page path — existing page to update, or new page to create}
- **What "done" looks like**: {acceptance criteria — what the doc update should contain}

### F-002: ...

## Covered Changes (no action needed)

<details>
<summary>N changes already documented (click to expand)</summary>

| #   | Repo   | PR        | Change    | Documented in     |
| --- | ------ | --------- | --------- | ----------------- |
| 1   | {repo} | #{number} | {summary} | `{doc page path}` |
| 2   | ...    | ...       | ...       | ...               |

</details>

## Internal-Only Changes (excluded)

<details>
<summary>N internal changes excluded (click to expand)</summary>

| #   | Repo   | PR                  | Why excluded                            |
| --- | ------ | ------------------- | --------------------------------------- |
| 1   | {repo} | #{number} — {title} | {reason: refactor, test-only, CI, etc.} |
| 2   | ...    | ...                 | ...                                     |

</details>

## Handoff

Impacted claim families for `/doc-correctness` verification:

- {family}: {list of specific claims to re-verify}

Impacted pages for `/doc-readability` review:

- {page path}: {reason — new content added, section rewritten, etc.}
```

## Rules

- Always check PR titles AND bodies when triaging. Some PRs have uninformative titles but detailed bodies.
- When a PR touches both doc-worthy and internal code, classify based on the doc-worthy parts.
- If a repo is not accessible via `gh`, note it in the report and skip that repo. Do not fail the entire report.
- Do NOT create or edit documentation pages yourself. This skill produces a gap report, not content.
- When suggesting target pages, prefer updating existing pages over creating new ones. Only suggest a new page when no existing page is a natural fit.
- Include the PR URL for every finding so the user can quickly review the actual change.
- If the time window returns more than 100 PRs for a single repo, note this and suggest narrowing the window.

## Related Skills

- After identifying gaps, run `/doc-correctness` on the impacted claim families to verify existing content is still accurate.
- After doc updates are made, run `/doc-readability` on the updated pages to ensure layer-appropriate tone.
