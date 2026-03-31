---
name: doc-correctness
description: Verifies documentation claims against implementation source code, configurations, and deployments. Use when cross-checking doc accuracy, auditing constants and addresses, verifying RPC behavior docs, checking spec correctness, or validating network parameters against source.
---

# Documentation Correctness Verification

Verify factual claims in the documentation against implementation sources: $ARGUMENTS

Parse the arguments to determine scope. Accepted inputs:
- A single page path (e.g., `docs/spec/evm/dual-gas-model.md`) — verify claims on that page.
- A layer directory (e.g., `docs/spec/`) — verify all pages in that layer.
- A claim family (e.g., `gas`, `system-contracts`, `rpc`, `network`, `upgrades`, `security`) — verify all claims of that type across all pages.
- `all` — verify every page listed in `docs/SUMMARY.md`.

Default (no arguments): verify all pages.

## Knowledge Base

Before verifying, consult the knowledge base for architectural context and source file pointers.

1. **Read the index first**: Use `/locate-repo mega-agents` to find the knowledge base, then read `knowledge/INDEX.md` for the master table of contents with tags.
2. **Load repo digests** for candidate repos from `knowledge/repo-references/{repo-name}.md` to understand where specific constants, configs, and interfaces live.

## Claim Families

Every verifiable claim in the docs falls into one of these families. Each family has a primary source of truth.

| Family | What to verify | Primary repo | Key source locations |
|---|---|---|---|
| Gas | Gas costs, limits, compute gas caps, storage gas bases, detention caps, refund rules | mega-evm | `crates/mega-evm/src/constants.rs`, gas schedule code in `evm/` |
| System Contracts | Addresses, Solidity interfaces, execution semantics, deployment specs | mega-evm | `crates/system-contracts/contracts/`, Rust bindings, address constants |
| RPC | Method parameters, return fields, error codes, behavioral differences from Ethereum | mega-rpc, mega-reth | mega-rpc Workers routes (`src/`), mega-reth RPC handlers (`crates/megaeth/rpc/`). **Note**: mega-rpc is the implementation of MegaETH's official public RPC endpoint only. Methods unavailable on the public endpoint may still be available through managed RPC providers (e.g., Alchemy). When verifying RPC method availability, distinguish between "unavailable on public endpoint" and "unsupported by MegaETH entirely." |
| Network | Chain IDs, RPC URLs, block times, currency symbols, explorer URLs | devops-ansible-inventory | Inventory files and deployment configs |
| Upgrades | Spec progression, per-upgrade behavioral deltas, activation order, backward compatibility | mega-evm | `crates/mega-evm/src/evm/spec.rs`, `block/hardfork.rs`, `docs/upgrades/` |
| Security | Security Considerations sections: claimed attack vectors, invariants, risk consequences | mega-evm, mega-reth | Same as the claim's primary family (Gas → gas sources, RPC → rpc sources, etc.) |

## Verification Workflow

### Phase 1: Claim Extraction

Read the target page(s) and extract every verifiable claim. A claim is any statement that can be checked against source code or configuration:

- **Numeric values**: gas costs, limits, caps, multipliers, addresses, chain IDs, port numbers.
- **Behavioral rules**: "X always/never happens", "Y reverts when Z", "A is charged before B".
- **Interface definitions**: function signatures, event signatures, error codes, parameter names.
- **Relationships**: "Spec X introduced feature Y", "Contract Z is available since Rex2".
- **Configuration values**: RPC URLs, block times, currency symbols.
- **Security claims**: Attack vectors, invariants, and risk consequences stated in Security Considerations sections (e.g., "if a node fails to charge X, an attacker can Y").

For each claim, record:
- The exact text from the doc.
- The page path and section.
- The claim family (Gas / System Contracts / RPC / Network / Upgrades / Security).

### Phase 2: Source Resolution

For each claim, locate the authoritative source:

1. **Match the claim family** to the repo and source locations in the table above.
2. **Consult the knowledge base** (`knowledge/INDEX.md`) for more specific pointers by tag.
3. **Locate the repo locally** using `/locate-repo {repo-name}`.
4. **Find the specific source**: search for the constant name, function signature, address, or behavioral code path.
   - For constants: grep for the constant name or numeric value in the primary source files.
   - For interfaces: read the Solidity contract source or Rust ABI bindings.
   - For RPC behavior: check the route handler or method implementation.
   - For network config: check inventory/deployment files.
   - For upgrade claims: check `spec.rs` and `hardfork.rs` for the spec gate.

**Budget**: Do not spend more than ~5 targeted file reads per claim. If the source cannot be found after 5 reads, mark the claim as Ambiguous and note what was searched.

### Phase 3: Verification

For each claim, compare the doc text against the source and assign a disposition:

| Disposition | Meaning |
|---|---|
| **Verified** | Doc matches source exactly. Record: file path, line number, commit hash. |
| **Incorrect** | Doc contradicts source. Record: what the doc says, what the source says, and the source location. |
| **Stale** | Doc was correct for a previous spec/version but is outdated. Record: which spec introduced the change. |
| **Ambiguous** | Source is unclear or claim cannot be verified with available information. Record: what was searched and why it's unclear. |
| **Version-dependent** | Claim is correct for some specs but not others, and the doc doesn't specify which. Record: which specs it applies to. |

### Phase 4: Report

Produce the report in the output format below.

## Output Format

```markdown
# Correctness Verification Report

**Scope**: {what was verified — page path, layer, claim family, or "all"}
**Date**: {date}
**Claims checked**: {count}

## Summary

| Disposition | Count |
|---|---|
| Verified | N |
| Incorrect | N |
| Stale | N |
| Ambiguous | N |
| Version-dependent | N |

## Findings (Incorrect / Stale / Ambiguous / Version-dependent only)

### C-001: {short description}
- **Severity**: Blocker | Major | Minor
- **Disposition**: {Incorrect | Stale | Ambiguous | Version-dependent}
- **Claim family**: {Gas | System Contracts | RPC | Network | Upgrades}
- **Page**: {path}
- **Section**: {heading}
- **Doc says**: "{exact text from doc}"
- **Source says**: "{what the source actually shows}"
- **Source location**: `{repo}/{file}:{line}` (commit `{short hash}`)
- **Suggested correction**: {concrete edit to the doc text}

### C-002: ...

## Verified Claims

<details>
<summary>N claims verified (click to expand)</summary>

| # | Page | Claim | Source | Line |
|---|---|---|---|---|
| 1 | {path} | {claim summary} | `{repo}/{file}` | {line} |
| 2 | ... | ... | ... | ... |

</details>

## Source Resolution Trace

Repos consulted:
- {repo} at `{local path}` (commit `{short hash}`)
- ...

Knowledge docs used:
- `knowledge/{file}.md` — {why it was consulted}
- ...
```

**Severity definitions**:
- **Blocker**: Incorrect numeric values (gas costs, limits, addresses), wrong spec attribution, wrong interface signature — would cause implementation bugs if someone followed the doc.
- **Major**: Stale values from a previous spec, missing version qualification, misleading behavioral description.
- **Minor**: Ambiguous claim that could be misread, minor wording imprecision that doesn't change meaning.

## Rules

- Verify against the actual source code, not against other documentation pages. Docs can be wrong; code is the ground truth (unless the user says otherwise).
- Always record the commit hash of the source you verified against so the verification is reproducible.
- If a claim references a specific spec (e.g., "In Rex3, the limit is X"), verify it was indeed Rex3 that introduced it, not an earlier or later spec.
- Do NOT fix the issues yourself unless the user explicitly asks. This skill produces a report, not edits.
- If the knowledge base INDEX does not cover a claim's domain, note it as a gap in the Source Resolution Trace.
- When verifying gas constants, check both the constant definition AND its usage context (is it per-transaction? per-opcode? per-block?).
- When verifying Security Considerations claims, confirm that the stated attack vector or invariant is real — check that the code actually enforces the invariant or that violating the stated rule would indeed cause the described consequence.

## Related Skills

- Run `/doc-freshness` first to identify which areas recently changed and need re-verification.
- After corrections, run `/doc-readability` to ensure rewrites maintain layer-appropriate tone.
