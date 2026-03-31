---
description: AI coding skills and tools for building on MegaETH with Claude Code, Cursor, Windsurf, and other AI assistants.
---

# Build with AI

AI coding assistants can help you build on MegaETH faster — deploying contracts, integrating payments, interacting with DeFi protocols, and more.
The community maintains a curated list of **AI coding skills** that teach your assistant MegaETH-specific patterns: the dual gas model, instant receipts via `realtime_sendRawTransaction`, mini-block subscriptions, and system contract usage.

Skills follow the [SKILL.md](https://docs.anthropic.com/en/docs/claude-code/skills) and [AGENTS.md](https://docs.agentsmd.dev) conventions and work with tools like Claude Code, Cursor, Windsurf, and OpenClaw.

## Available Skills

| Category | Skills |
| -------- | ------ |
| **General** | End-to-end MegaETH development — Foundry setup, gas model, WebSocket subscriptions, debugging |
| **Payments** | x402 HTTP payments, USDm stablecoin integration, Permit2 flows |
| **DeFi** | Kumbaya DEX (Uniswap V3 fork) — swaps, quoting, liquidity, multi-hop routing |
| **Identity & Content** | .Mega Domains (naming service), WARREN (on-chain permanent web CMS) |
| **Agents** | ERC-8004 Trustless Agents — on-chain identity, reputation, and validation |

For the full list with installation links and detailed descriptions, see the **[awesome-megaeth-ai](https://github.com/megaeth-labs/awesome-megaeth-ai)** repository.

## Getting Started

Most skills are single files you drop into your project. For example, with Claude Code:

```bash
# Add a MegaETH dev skill to your project
curl -o .claude/skills/megaeth-dev.md \
  https://raw.githubusercontent.com/0xBreadguy/megaeth-ai-developer-skills/main/SKILL.md
```

Your AI assistant will automatically pick up the skill and use it when relevant.

{% hint style="info" %}
These skills are community-contributed and are not endorsed by MegaETH Labs.
Always review skill content before adding it to your project.
{% endhint %}
