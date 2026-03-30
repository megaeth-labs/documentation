# Developer Docs — Writing Rules

This layer targets **dapp and contract developers**: people writing Solidity, deploying contracts, and building applications on MegaETH.
They know Ethereum. They write code. They need to understand what's different.

## Tone & Language

- **Technical but practical.** Explain *what developers need to know*, not the full protocol specification.
- **Include code examples.** Solidity, TypeScript (ethers.js/viem), and `cast` CLI where relevant.
- **Use `{% tabs %}` blocks** for multi-language code examples.
- **Use `{% hint %}` blocks** for warnings (gas pitfalls), tips (best practices), and danger (breaking changes).
- **Link to the EVM spec for formal definitions.** Don't duplicate normative content — summarize and link.

## What Belongs Here

- EVM differences from Ethereum (consolidated reference)
- Gas model guide (dual gas, storage gas, practical estimation)
- System contract usage (Oracle, Timestamp, KeylessDeploy — with Solidity interfaces and examples)
- Architecture overview (sequencer, full nodes, provers)
- Mini-blocks (what they are, how they affect dapps)
- Realtime API (WebSocket subscriptions, enhanced RPC methods)
- RPC reference (method table, error codes)
- Developer FAQ (gas estimation, contract deployment, debugging)

## What Does NOT Belong Here

- End-user wallet setup, faucet instructions → `docs/user/`
- RPC provider setup, indexer integration → `docs/integration/`
- Normative specifications with MUST/SHALL language → `mega-evm/docs/`
- Full storage gas cost derivation formulas → `mega-evm/docs/` (summarize here, link there)

## Content Pattern: Summarize + Link

For every concept that has a formal spec in `mega-evm/docs/`:

1. **Summarize** the practical implications (1-3 paragraphs)
2. **Include** a key values table if applicable
3. **Add** code examples showing how to work with it
4. **Link** to the spec: "For the formal specification, see [Dual Gas Model](https://docs.megaeth.com/evm-spec/evm/dual-gas-model)."

Example pattern:
```markdown
## Storage Gas

MegaETH charges additional storage gas on top of standard EVM compute gas for operations that grow on-chain state.

| Operation | Storage Gas |
|-----------|-------------|
| SSTORE (0 → non-0) | 20,000 × (multiplier − 1) |
| Contract creation | 32,000 × (multiplier − 1) |

{% hint style="success" %}
Use `eth_estimateGas` on a MegaETH RPC endpoint for accurate gas estimates.
Do not attempt to compute gas costs manually.
{% endhint %}

For the complete storage gas schedule, see the [formal specification](https://docs.megaeth.com/evm-spec/evm/dual-gas-model).
```

## Formatting Preferences

- Use `{% tabs %}` for multi-language code (Solidity / TypeScript / cast).
- Use `{% hint style="danger" %}` for breaking changes and migration notes.
- Use `{% hint style="success" %}` for practical tips and best practices.
- Use tables for reference data (gas costs, resource limits, contract addresses).
- Use `<details>` for optional deep-dives that most developers can skip.
- Use `<details>` with a `<summary>` label like `"Rex4 (unstable): ..."` for upcoming behavior changes in unstable specs, mirroring the convention used in the [EVM specification](../spec/AGENTS.md). This keeps the main content focused on the current stable spec while giving developers early visibility into upcoming changes.

## FAQ

The developer FAQ (`dev/faq.md`) covers questions like:
- "How do I estimate gas on MegaETH?"
- "Why did my transaction fail with OutOfGas even though I had enough gas?"
- "Does MegaETH support EIP-1559?"
- "How do I read the high-precision timestamp in my contract?"
- "What's the maximum contract size?"

Do NOT include user-level questions (wallet setup, bridging) or integration-level questions (indexer config, RPC provider setup).
