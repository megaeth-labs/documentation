# Documentation Audit Report

Audited against rules in `docs/AGENTS.md`, `docs/dev/AGENTS.md`, `docs/user/AGENTS.md`.

## Legend

- **HIGH** — Violates a codified rule or contains factual errors
- **MEDIUM** — Doesn't match the spirit of the principles; improvement opportunity
- **LOW** — Cosmetic or minor

---

## HIGH — Rule Violations

### 1. `architecture.md` — Stale "Testnet" framing

Lines 36–53 describe "Current Testnet Phase" and "Upcoming Phases" — MegaETH launched mainnet.
This is factually stale and violates **MegaETH-first** (describes hypothetical future state rather than current reality).

**Fix**: Rewrite to describe the current mainnet architecture. Move testnet-era content to a historical note or remove it.

### 2. `faq.md` — Stale/wrong answers

- **Line 51**: `eth_call` gas limit says "10,000,000 (increased on 28/03/2025 from 5,000,000)" — the date qualifier violates **terse over verbose** and the historical note adds no value. Also on line 53, it says "on-chain transactions, which is 1,000,000,000" but `resource-limits.md` says 10,000,000,000 (10B). **One of these is wrong.**
- **Line 171–181**: WETH address given as `0x4eB2Bd7beE16F38B1F4a0A5796Fffd028b6040e9`, but `contracts.md` lists WETH at `0x4200000000000000000000000000000000000006` (the OP Stack canonical WETH). **Contradiction.**
- **Line 173**: "Where can I find standard token contract addresses?" points to a "community-run wiki" — we now have `contracts.md`. **Stale redirect.**

### 3. `realtime-api.md` — "Request"/"Response" section pattern

Lines 228–281 for `realtime_sendRawTransaction` and lines 292–363 for `eth_callAfter` use **"### Request" / "### Successful Response" / "### Error Codes"** headings instead of the codified **Parameters / Returns / Errors** pattern.
While these aren't in the `rpc/` directory, they document RPC methods and should follow the same skeleton for consistency.

### ~~4. `overview.md` — Bridge section duplicates `contracts.md`~~ ✅ FIXED

Replaced duplicated L1 Contracts table with a link to `contracts.md`.

---

## MEDIUM — Improvement Opportunities

### ~~5. `evm-differences.md` — Could be more MegaETH-first~~ WONTFIX

Comparison table is deliberate — the whole page is about contrasting with Ethereum.

### ~~6. `system-contracts.md` — Duplicates volatile data explanation~~ ✅ FIXED

Removed the "Volatile Data and Compute Gas Limit" subsection. The warning hint under "Timestamp Snapshot Semantics" already covers this concisely with a link to `volatile-data.md`.

### 7. `miniblocks.md` — Opening could be more concrete

Line 9: "Mini-blocks are specific to MegaETH and anchor an ecosystem of applications, tools, and infrastructure purpose-built for minimum end-to-end latency." — Marketing-speak, not a practical description. Violates **terse over verbose**.

**Fix**: "Mini-blocks are MegaETH-specific blocks produced every ~10ms, enabling sub-second transaction confirmations."

### ~~8. `gas-model.md` — "Tips for Developers" section~~ ✅ FIXED

Deleted the standalone section. Inlined each tip where relevant:
- "Account for storage gas" → after Transaction Intrinsic Costs table
- "Prefer transient storage" + "Reuse storage slots" → end of Storage Gas Costs section
- "Use native gas estimation APIs" → folded into existing hint in Bucket Multiplier section

### 9. `realtime-api.md` — "Overview of Changes" numbered list

Lines 27–35 list 6 changes as a numbered list mixing different types of information.
The numbering implies ordering that doesn't exist.
Consider a table or restructure.

### ~~10. `debugging.md` — Method availability contradicts RPC reference~~ ✅ FIXED

- `debugging.md`: Reworded to "available through managed RPC providers but not on the public MegaETH RPC endpoint."
- `rpc/README.md`: Added hint above the table clarifying it reflects the public endpoint, with a link to `debugging.md` for debug method usage via managed providers.

---

## LOW — Cosmetic / Minor

### ~~11. `volatile-data.md` line 8 — broken anchor link~~ ✅ FIXED

Changed `#native-oracle` → `#reading-oracle-data`.

### ~~12. `system-contracts.md` line 130 — broken anchor link~~ ✅ FIXED

The broken link was in the "Volatile Data and Compute Gas Limit" subsection, which was removed in fix #6.

### 13. Integration layer — mostly empty stubs

`wallets.md`, `indexers.md`, `oracles.md`, `bridges.md`, `rpc-providers.md` are all "under construction" stubs.
Not a rule violation, but a coverage gap.

### 14. Missing frontmatter check needed

Most pages have `description` frontmatter (good). Verify all pages comply with the rule "every page must have YAML frontmatter with at least `description`."

---

## Summary

| Priority | Count | Key Items |
|----------|-------|-----------|
| HIGH     | 3 (1 fixed) | Stale architecture page, contradictory gas limits in FAQ, WETH address conflict, ~~duplicated L1 contracts~~ ✅ |
| MEDIUM   | 6     | Ethereum-centric comparison table, duplicated volatile data explanation, marketing-speak opening, method availability contradictions |
| LOW      | 4     | Broken anchors, empty integration pages, minor formatting |
