# Integration Guide — Writing Rules

This layer targets **infrastructure and ecosystem partners**: wallet developers, indexer operators, oracle providers, bridge teams, and RPC providers integrating with MegaETH.
They build *for* MegaETH, not *on* MegaETH. They need configuration details and behavioral quirks.

## Tone & Language

- **Integration-focused.** Configuration, endpoints, behavioral differences from standard Ethereum.
- **Use `{% tabs %}` blocks** for multi-platform configurations (e.g., mainnet vs testnet, different providers).
- **Include concrete values.** Chain IDs, RPC URLs, WebSocket endpoints, contract addresses — always provide copy-pasteable values.
- **Call out behavioral differences.** If MegaETH behaves differently from Ethereum in a way that affects integrators, flag it explicitly with `{% hint style="warning" %}`.

## What Belongs Here

- Network connection details (RPC URLs, chain IDs, WebSocket endpoints)
- Wallet developer guide (gas estimation quirks, 98/100 forwarding rule, resource limits impact)
- Indexer integration (how mini blocks affect indexing, subscription patterns, block finality)
- Oracle provider integration (supported oracles, configuration)
- Bridge integration (supported bridges, setup)
- RPC provider considerations (realtime API support, custom methods)
- Tooling and infrastructure partner listing

## What Does NOT Belong Here

- End-user wallet setup → `docs/user/`
- Solidity contract development, dapp tutorials → `docs/dev/`
- Normative protocol specifications → `mega-evm/docs/`

## Formatting Preferences

- Use `{% tabs %}` for mainnet vs testnet configuration values.
- Use tables for endpoint lists, contract addresses, chain parameters.
- Use `{% hint style="warning" %}` for behavioral differences from Ethereum that affect integrators.
- Use `{% hint style="info" %}` for configuration notes and tips.
- Keep pages actionable — every page should answer "how do I integrate X with MegaETH?"

## FAQ

The integration FAQ (`integration/faq.md`) covers questions like:
- "What chain ID does MegaETH use?"
- "Does MegaETH support standard Ethereum JSON-RPC?"
- "How do mini blocks affect my indexer?"
- "Do I need to handle the 98/100 gas forwarding rule in my wallet?"
- "Which oracles are available on MegaETH?"

Do NOT include user-level questions or developer-level smart contract questions.
