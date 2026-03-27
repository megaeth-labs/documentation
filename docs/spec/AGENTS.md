# Specification — Writing Rules

This layer is the **formal MegaETH specification** — the complete, normative definition of MegaETH's verifiable behavior.
It is not limited to the EVM; it covers the entire set of behaviors that define a correct MegaETH node: transaction processing, resource metering, system contracts, oracle services, and protocol state management.
It targets protocol implementers, auditors, and anyone who needs to verify or reproduce MegaETH's exact behavior.

**Scope principle**: If a behavior affects whether a node produces correct outputs given the same inputs, it belongs in this spec.
This includes but is not limited to EVM execution — gas accounting, resource limits, system contract semantics, oracle data lifecycle, and upgrade activation rules are all in scope.

## Tone & Language

- **Normative and precise.** Use MUST, SHALL, SHOULD, MAY per RFC 2119 when defining behavior.
- **Exhaustive.** Cover every corner case. Readability may be sacrificed for completeness.
- **No developer guidance.** Do not include "tips", "best practices", or "how to use" sections. That belongs in `docs/dev/`.
- **No user-facing language.** Do not explain "what this means for you". That belongs in `docs/user/` or `docs/dev/`.
- **Self-contained.** The spec never links to user docs or developer docs. It may link to external references (EIPs, Ethereum Yellow Paper, OP Stack specs).

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

## Source of Truth

This content is mirrored from `mega-evm/docs/` in the [mega-evm repository](https://github.com/megaeth-labs/mega-evm).
When updating spec content, ensure both locations stay in sync.
The mega-evm repository is the authoritative source.

## Formatting Preferences

- Use tables for structured data (gas costs, opcode lists, resource limits).
- Use `<details>` blocks for unstable (Rex4) features.
- Use `{% hint style="info" %}` for explanatory notes about design rationale.
- Use `{% hint style="warning" %}` for unstable spec warnings.
- Use `{% hint style="danger" %}` for breaking changes or deprecations.
- Use `{% hint style="success" %}` sparingly — only for notes that help implementers, not app developers.
