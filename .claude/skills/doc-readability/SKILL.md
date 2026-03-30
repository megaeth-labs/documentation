---
name: doc-readability
description: Evaluates documentation readability, tone, structure, and audience-appropriateness per layer. Use when reviewing doc quality, auditing tone consistency, checking formatting compliance, reviewing a page before publishing, or running a readability audit across a documentation layer.
---

# Documentation Readability Evaluation

Evaluate readability and layer-appropriateness for: $ARGUMENTS

Parse the arguments to determine scope. Accepted inputs:
- A single page path (e.g., `docs/dev/gas-model.md`) — evaluate that page.
- A layer directory (e.g., `docs/dev/`, `docs/spec/`) — evaluate all pages in that layer.
- `all` — evaluate every page listed in `docs/SUMMARY.md`.
- A glob pattern (e.g., `docs/integration/*.md`) — evaluate matching pages.

Default (no arguments): evaluate all pages.

## Setup

1. **Read the writing rules.** Before evaluating any page, load the applicable rules:
   - Always read `docs/AGENTS.md` (cross-layer conventions).
   - Read the layer-specific `AGENTS.md` for the page being evaluated (`docs/user/AGENTS.md`, `docs/dev/AGENTS.md`, `docs/integration/AGENTS.md`, or `docs/spec/AGENTS.md`).
2. **Read `docs/SUMMARY.md`** to understand the full page inventory and navigation structure.
3. **Detect each page's layer** from its path prefix (`docs/user/`, `docs/dev/`, `docs/integration/`, `docs/spec/`).

## Evaluation Checklist

For each page, run through these checks in order. Not every check applies to every layer — the layer matrix below defines which checks apply where.

### 1. Structural Lint

- [ ] **Frontmatter**: YAML frontmatter present with at least a `description` field.
- [ ] **Heading hierarchy**: Exactly one H1 (`#`). Sections use H2 (`##`), subsections H3 (`###`). No heading level skips (e.g., H1 → H3).
- [ ] **One sentence per line**: Each sentence on its own line for diff readability. Flag paragraphs where multiple sentences share a line.
- [ ] **Page in SUMMARY.md**: The page appears in `docs/SUMMARY.md`. Flag orphaned pages.

### 2. Layer-Appropriate Content

- [ ] **Code blocks**: Check presence/absence per layer rules.
- [ ] **Normative language (MUST/SHALL/SHOULD/MAY)**: Check usage per layer rules.
- [ ] **Second-person pronouns ("you", "your")**: Check usage per layer rules.
- [ ] **Content placement**: Flag content that belongs in a different layer (developer tips in spec, code in user guide, normative rules in dev docs, etc.).

### 3. Block Usage

- [ ] **Hint blocks**: Correct `{% hint style="..." %}` usage per layer rules.
- [ ] **Stepper blocks**: `{% stepper %}` used for multi-step procedures (User layer).
- [ ] **Tab blocks**: `{% tabs %}` used for multi-language code or multi-network configs.
- [ ] **Details blocks**: `<details>` used for unstable spec content (Spec layer).

### 4. Tone and Readability

- [ ] **Audience match**: Language complexity appropriate for the target audience.
- [ ] **Jargon**: Unexplained technical terms in User layer. Missing glossary links in Spec layer.
- [ ] **Action orientation**: User layer instructions are actionable ("Connect your wallet..."), not passive ("The wallet can be connected...").
- [ ] **Summarize + link pattern**: Dev layer pages that reference spec behavior use the pattern: summarize practical implications → key values table → code examples → link to spec page.

### 5. Cross-Linking

- [ ] **Link direction**: Spec pages MUST NOT link to user or dev docs. Dev pages SHOULD NOT link to user docs. User pages MAY link to dev docs.
- [ ] **Relative paths with `.md`**: All internal links use relative paths with `.md` extensions (e.g., `../dev/gas-model.md`, NOT `/dev/gas-model`).
- [ ] **Anchor targets**: Any `#fragment` link target is a markdown heading, not bold text.
- [ ] **Glossary linking**: First mention of MegaETH-specific terms links to glossary entry (Spec layer). No over-linking on subsequent uses.

## Layer Matrix

| Check | User | Dev | Integration | Spec |
|---|---|---|---|---|
| Code blocks | Forbidden | Required for features with usage patterns | Required for configs | Pseudocode only |
| "you" / second person | Encouraged | OK | OK | Forbidden in Specification sections |
| MUST/SHALL/SHOULD | Inappropriate | Avoid unless quoting spec | Avoid | Required for behavioral rules |
| Stepper blocks | Required for multi-step | Optional | Optional | Not used |
| Summarize + link to spec | N/A | Required when referencing spec behavior | Optional | N/A |
| Copy-pasteable values | N/A | Nice-to-have | Required (chain IDs, URLs, addresses) | N/A |
| `{% hint style="success" %}` | OK (tips) | OK (best practices) | OK | Forbidden |
| `{% hint style="danger" %}` | OK (warnings) | OK (breaking changes) | OK | Deprecation notices only |
| Glossary first-use linking | Not required | Not required | Not required | Required |
| Page length | Flag >500 words, consider splitting | No hard limit | No hard limit | No hard limit |

## Output Format

Produce a Markdown report with this structure:

```markdown
# Readability Evaluation Report

**Scope**: {what was evaluated — page path, layer, or "all"}
**Date**: {date}
**Pages evaluated**: {count}

## Summary

| Layer | Pages | Pass | Fail | Findings |
|---|---|---|---|---|
| User | N | N | N | N |
| Dev | N | N | N | N |
| Integration | N | N | N | N |
| Spec | N | N | N | N |

## Findings

### R-001: {short description}
- **Severity**: Blocker | Major | Minor
- **Layer**: {layer}
- **Page**: {path}
- **Rule**: {which check failed}
- **Evidence**: {excerpt or description}
- **Suggested fix**: {concrete edit}

### R-002: ...

## Quick Edit Checklist

- [ ] {Concrete edit 1 — file:line or file:section}
- [ ] {Concrete edit 2}
- [ ] ...
```

**Severity definitions**:
- **Blocker**: Content in the wrong layer, code blocks in User layer, normative language in User layer, spec linking to dev/user docs.
- **Major**: Missing frontmatter, heading hierarchy violations, wrong hint block style for the layer, missing summarize+link pattern in Dev.
- **Minor**: Multi-sentence lines, missing glossary links, suboptimal block usage, minor tone drift.

## Rules

- Evaluate against the AGENTS.md rules as written. Do not invent additional style rules.
- When a page has zero findings, still include it in the summary table as "Pass".
- If evaluating a batch, sort findings by severity (Blocker first), then by layer, then by page.
- Do NOT fix the issues yourself unless the user explicitly asks. This skill produces a report, not edits.
- If a finding is ambiguous (could be intentional), note it as Minor with "Review: may be intentional".

## Related Skills

- After readability evaluation, run `/doc-correctness` to verify factual claims.
- After doc updates, run `/doc-freshness` to check for coverage gaps.
