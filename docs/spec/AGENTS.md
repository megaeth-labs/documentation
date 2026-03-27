# Specification — Writing Rules

This layer is the **formal MegaETH specification** — the complete, normative definition of MegaETH's verifiable behavior.
It is not limited to the EVM; it covers the entire set of behaviors that define a correct MegaETH node: transaction processing, resource metering, system contracts, oracle services, and protocol state management.
It targets protocol implementers, auditors, and anyone who needs to verify or reproduce MegaETH's exact behavior.

**Scope principle**: If a behavior affects whether a node produces correct outputs given the same inputs, it belongs in this spec.
This includes but is not limited to EVM execution — gas accounting, resource limits, system contract semantics, oracle data lifecycle, and upgrade activation rules are all in scope.

## Page Structure

Every spec page MUST follow this section order:

```
# Page Title
Abstract: 1-2 sentence summary of what this page specifies.

## Motivation
The problem statement: what problem exists that this spec solves.
Describes the concrete failure modes or limitations that necessitate this behavior.
This section explains WHY the spec exists, not how it works.

## Specification
The normative behavioral definition.
Subsections organized by logical component.
All behavioral rules use MUST/MUST NOT/SHALL/SHOULD/MAY per RFC 2119.

## Constants
Table of all named constants with values and descriptions.
Every constant referenced in the Specification section MUST appear here.
Placed after the Specification so readers encounter the behavioral rules first
and can reference constants as needed.

## Rationale
Design decisions: why this specific solution over alternatives.
Each decision is a named paragraph explaining the trade-off.
This section explains WHY specific choices were made.

## Spec History
Links to upgrade pages showing how this behavior evolved across specs.
```

**Sections may be omitted** when they genuinely don't apply (e.g., a glossary page has no Constants or Motivation).
But for any page that defines behavioral rules, the full structure SHOULD be followed.

## Tone & Language

- **Normative and precise.** Use MUST, MUST NOT, SHALL, SHOULD, MAY per RFC 2119 when defining behavior. Every behavioral rule in the Specification section MUST use normative language.
- **Exhaustive.** Cover every corner case. Readability may be sacrificed for completeness.
- **No developer guidance.** Do not include "tips", "best practices", "how to use", or recommendations like "Use `eth_estimateGas`" or "Use transient storage". That belongs in `docs/dev/`.
- **No user-facing language.** Do not address the reader as "you" in the Specification section. Do not explain "what this means for you". That belongs in `docs/user/` or `docs/dev/`.
- **Self-contained.** The spec never links to user docs or developer docs. It may link to external references (EIPs, Ethereum Yellow Paper, OP Stack specs) and to other spec pages.
- **No implementation details.** Do not reference specific code patterns, function names, or implementation strategies (e.g., `spec.is_enabled(MINI_REX)`). Describe the required behavior, not how to implement it.

## Specification Section Rules

### Normative Language

- Use "A node MUST..." for required behavior.
- Use "A node MUST NOT..." for prohibited behavior.
- Use "SHOULD" only when non-compliance is acceptable in defined circumstances.
- Descriptive prose (background, context) does not require normative keywords.

### Constants

- Every numeric value used in the Specification MUST be defined as a named constant in the Constants table.
- Do not embed magic numbers in formulas — reference the constant name.
- Each constant row MUST include: name, value, and a one-line description.

### Formulas

- Express formulas as inline code blocks: `` `total_gas = compute_gas + storage_gas` ``.
- Define every variable immediately after the formula.
- For complex logic, use pseudocode in fenced code blocks.

### Edge Cases

- State edge cases explicitly as normative rules (e.g., "For state that does not yet exist, the node MUST...").
- Do not leave behavior undefined — if the spec doesn't say what happens, implementers will guess differently.

### Charging Lifecycle

- For any cost or fee, specify WHEN it is charged: before execution, at the opcode, or post-execution.
- Specify what happens on failure: is the cost consumed, refunded, or rolled back?

### Unstable Features

- Wrap unstable (not-yet-activated) spec content in `<details>` blocks with a clear label (e.g., "Rex4 (unstable): ...").
- Unstable content MUST still use normative language within the `<details>` block.

## Motivation and Rationale Section Rules

### Motivation

- Describe the concrete problem: what breaks, what is underpriced, what attack becomes possible.
- Use specific numbers where possible (e.g., "base fee of 0.001 gwei", "up to 10 billion gas per block").
- Do NOT describe the solution — that is the Specification section's job.

### Rationale

- Each design decision is a **named paragraph** starting with bold text (e.g., "**Why `base × (multiplier − 1)` instead of `base × multiplier`?**").
- Explain the trade-off: what was considered, what was rejected, and why.
- Reference historical changes where applicable (e.g., "MiniRex used X, Rex changed to Y because...").

## What Belongs Here

- EVM behavioral definitions (gas costs, opcode semantics, resource limits)
- System contract specifications (addresses, interfaces, execution semantics)
- Oracle service specifications (storage layout, timing guarantees, gas detention)
- Hardfork/spec progression and per-upgrade behavioral deltas
- Glossary of protocol terms

## What Does NOT Belong Here

- Developer tips or best practices → `docs/dev/`
- Code examples showing how to use a feature → `docs/dev/`
- User-facing explanations → `docs/user/`
- Integration configuration → `docs/integration/`
- "Why should I care about this?" framing → `docs/dev/`
- Implementation-specific code patterns or API references → `docs/dev/`
- Recommendations ("Use X instead of Y") → `docs/dev/`

## Source of Truth

The user is the ultimate source of truth.
This documentation is the canonical written specification of MegaETH's verifiable behavior, but user instructions override both the docs and the implementation when there is ambiguity or conflict.

The `mega-evm` repository is a side channel for verification only.
Agents MUST inspect the relevant implementation in `mega-evm` to confirm whether the documented behavior matches the current implementation, but the implementation code is not the final authority.

If an agent finds or suspects any discrepancy between user intent, this specification, and the `mega-evm` implementation, the agent MUST NOT silently resolve it.
Instead, the agent MUST surface the discrepancy clearly and ask the user to confirm the intended behavior before changing the spec text.

Do not describe this spec as "mirrored from mega-evm/docs".
The old `mega-evm/docs` content is transitional and may be removed.

## Formatting Preferences

- Use tables for structured data (gas costs, opcode lists, resource limits, constants).
- Use `<details>` blocks for unstable (Rex4) features.
- Use `{% hint style="info" %}` sparingly — only for non-normative notes that help implementers understand design intent. Never for developer tips.
- Use `{% hint style="warning" %}` for unstable spec warnings.
- Do NOT use `{% hint style="success" %}` in spec pages — it implies developer guidance.
- Do NOT use `{% hint style="danger" %}` for normative rules — normative rules belong in plain prose with MUST/MUST NOT. Reserve `{% hint style="danger" %}` only for deprecation notices.
