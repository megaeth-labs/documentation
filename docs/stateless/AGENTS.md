# Stateless Validator — Writing Rules

This layer targets **node operators** running the upstream [`stateless-validator`](https://github.com/megaeth-labs/stateless-validator) Rust client.
Readers are comfortable on the Linux command line, know how to read a systemd unit, and want authoritative reference material they can copy-paste into a deployment.

## Tone & Language

- **Reference tone.** Short declarative sentences, facts first.
- **Copy-pasteable commands.** Every shell block should run as shown against a real deployment (modulo placeholders).
- **Verify against source.** Every CLI flag, env var, default value, and metric name must match the upstream repo. Before editing the flag or metric tables, fetch the current `bin/stateless-validator/src/app.rs` (where `CommandLineArgs` is defined), `crates/stateless-common/src/logging.rs`, and `bin/stateless-validator/src/metrics.rs` and compare.
- **Placeholders use angle brackets.** `<TRUSTED_BLOCK_HASH>`, `<HOST>` — not `0x1234...` or `...`.
- **No marketing.** State what the validator does; skip "honest", "trust-minimized", "fastest".

## What Belongs Here

- Installation from source, system requirements, and supported platforms.
- CLI flag and environment variable reference, mirrored from the upstream `clap` definitions.
- Log configuration (filters, formats, rotation) from `LogArgs`.
- Prometheus metric reference from `metrics::names`.
- Background deployment patterns (systemd, Docker, PID-file scripts).
- Trust model and pairing with `op-node` / replica nodes.
- Troubleshooting the operator's day-to-day failure modes (lag, reorgs, RPC errors).

## What Does NOT Belong Here

- End-user wallet or bridging instructions → `docs/user/`.
- Dapp / contract developer guidance → `docs/dev/`.
- Normative protocol specification → [mega-evm repo](https://github.com/megaeth-labs/mega-evm).
- Internal architecture of the validator crate (module layout, trait design) → the upstream repo README.

## Formatting Preferences

- Use `{% hint style="info" %}` for optional guidance (e.g., "prefer systemd over `nohup`").
- Use `{% hint style="warning" %}` for operator-facing hazards (e.g., resetting the anchor wipes the DB).
- Use tables for every flag / env-var / metric reference.
- Use fenced code blocks with language identifiers (` ```bash `, ` ```ini `, ` ```text `).

## Before Changing a Flag, Env Var, or Metric

1. Pull the current upstream file (`gh api repos/megaeth-labs/stateless-validator/contents/<path>`).
2. Diff the upstream field names and defaults against the table on the page.
3. Update the table — including the defaults, required-ness, and description.
4. If the flag or metric was added or removed upstream, record the change in the PR description so reviewers can spot-check.
