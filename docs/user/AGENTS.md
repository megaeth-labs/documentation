# User Guide — Writing Rules

This layer targets **end users**: people using wallets, DeFi apps, and interacting with MegaETH through UIs.
They are not developers. They do not read code.

## Tone & Language

- **Plain language only.** No jargon. No code blocks. No Solidity. No terminal commands.
- **Explain acronyms** on first use: "RPC (Remote Procedure Call)" — but prefer avoiding them entirely.
- **Action-oriented.** Tell users what to do, not how things work internally.
- **Use `{% stepper %}` blocks** for multi-step instructions (wallet setup, bridging, etc.).

## What Belongs Here

- How to connect a wallet to MegaETH (mainnet, testnet)
- How to get testnet tokens (faucet)
- How to bridge assets
- Network status and chain parameters (chain ID, currency symbol)
- General FAQ about using MegaETH as an end user

## What Does NOT Belong Here

- Code examples, Solidity, TypeScript, or CLI commands → `docs/dev/`
- EVM differences, gas model details, resource limits → `docs/dev/`
- RPC provider setup, indexer configuration → `docs/dev/tooling.md`
- Normative spec language (MUST, SHALL) → `mega-evm/docs/`

## Formatting Preferences

- Prefer `{% stepper %}` for sequential instructions.
- Prefer `{% hint style="info" %}` for tips and notes.
- Prefer `{% hint style="warning" %}` for common mistakes.
- Use screenshots or diagrams where helpful (store in `docs/.gitbook/assets/`).
- Keep pages short. If a page exceeds ~500 words, consider splitting.

## FAQ

The user FAQ (`user/faq.md`) covers questions like:
- "What wallet works with MegaETH?"
- "Why is my transaction pending?"
- "How much does a transaction cost?"
- "How do I bridge from Ethereum?"

Do NOT include developer-level questions (gas estimation, contract deployment, EVM compatibility).
