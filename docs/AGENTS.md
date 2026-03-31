# Documentation Conventions

These rules apply across the documentation site.

## Tone by Level

The documentation has two tonal registers depending on where a page lives:

- **Top-level pages** (`docs/architecture.md`, `docs/mini-block.md`, `docs/README.md`) use a **narrative, explanatory tone**.
  Build an argument. Walk the reader through reasoning. Explain *why* things are the way they are.
  These pages read like a well-written technical blog post — engaging, flowing prose that tells a story.

- **Layer pages** (`user/`, `dev/`, `spec/`) use a **terse, reference tone**.
  Short declarative sentences. Sentence fragments in table cells. Facts first, explanation second.
  Optimized for scanning and quick lookup. Each layer's `AGENTS.md` has additional tone rules.

When in doubt: top-level pages prioritize readability, layer pages prioritize density.

## Writing Principles

- **Self-contained pages.**
  The reader should understand the page without clicking away.
  Inline the key information (fields, values, behavior) on the page itself; link to type definitions or specs only for completeness.
- **Information where the reader needs it.**
  Don't accumulate notes in a separate section at the bottom.
  Put each note next to the field, parameter, or concept it describes — inside a table cell, parenthetical, or inline clause.
- **Terse over verbose** (layer pages).
  Use sentence fragments in table cells.
  Cut filler words: "When it usually happens" → "Cause"; "Fix the request before retrying" → "Fix the request".
- **MegaETH-first.**
  Describe what MegaETH does, not what Ethereum does plus a list of deltas.
  If behavior differs from Ethereum, note it inline where relevant — don't create separate "Differences" sections.
- **Kill indirection.**
  Show the thing, don't point to the thing.
  If a type has 5 key fields, list them in a table on the page rather than writing "see `TransactionCall`".
- **Every section earns its place.**
  Don't add structural sections (e.g., "Standard", "Differences", "Reader notes") unless they carry information the reader can't get from the rest of the page.
  If a section just restates what's already in the tables, delete it.
- **Active voice.**
  Make clear who performs the action.
  "The node charges storage gas" not "Storage gas is charged by the node."
- **Present tense.**
  Describe current behavior in present tense.
  "The node reverts the transaction" not "The node will revert the transaction."
  Use past tense only for historical events (e.g., Spec History sections).
- **No marketing language.**
  State facts. No superlatives, no hype, no exclamation marks.
  "MegaETH processes transactions in under 10ms" not "MegaETH is the fastest blockchain ever built!"
- **Conditions before instructions.**
  Put the condition or purpose first, then the action.
  "To estimate gas, call `eth_estimateGas`" not "Call `eth_estimateGas` to estimate gas."
  "If the transaction exceeds 10M gas, use a managed provider" not "Use a managed provider if the transaction exceeds 10M gas."
- **Descriptive link text.**
  Links must describe the destination.
  "[Gas Model](gas-model.md)" not "[click here](gas-model.md)" or "[this page](gas-model.md)."
  Never use "here", "this link", "this page", or "read more" as link text.

## Terminology

Use these exact forms consistently. Do not alternate between variants.

| Term | Correct | Incorrect |
|------|---------|-----------|
| Project name | MegaETH | megaETH, Mega ETH, megaeth, MEGAETH |
| EVM implementation | MegaEVM | MegaEvm, mega-evm, Mega EVM |
| Mainnet (proper noun) | MegaETH Mainnet | MegaETH mainnet, main net, main-net |
| Testnet (proper noun) | MegaETH Testnet | MegaETH testnet, test net, test-net |
| Currency ticker | ETH | eth, Eth |
| Currency name | ether | Ether, ETH (when referring to the currency, not the ticker) |
| Block type | mini-block | miniblock, mini block, MiniBlock |
| Onchain / offchain | onchain, offchain | on-chain, off-chain, on chain |
| Smart contract | smart contract | Smart Contract, smartcontract |
| Gas dimensions | compute gas, storage gas | Compute Gas, Storage Gas, Compute gas |
| Spec names | MiniRex, Rex, Rex1, Rex2, Rex3, Rex4 | minirex, MINIREX, mini-rex, rex-3 |
| State trie | SALT | Salt, salt |

**Capitalization rules:**
- Spec names are proper nouns — always capitalized as shown.
- Gas dimension names are common nouns — always lowercase in running text.
- "Mainnet" and "Testnet" are capitalized when referring to MegaETH's specific networks (proper nouns), lowercase when used generically ("run a testnet").
- Acronyms: spell out on first use with the acronym in parentheses, then use the acronym consistently. Example: "Remote Procedure Call (RPC)" — then "RPC" throughout.

## Formatting

- **GitBook Markdown**: Use GitBook-flavored Markdown with custom blocks. See `/skill.md` for full syntax reference.
- **One sentence, one line**: Each sentence goes on its own line for better diffs.
- **Frontmatter**: Every page must have YAML frontmatter with at least `description` for SEO.
- **Headings**: Use `#` for the page title (H1), `##` for sections (H2), `###` for subsections (H3). One H1 per page. Use sentence case: "Gas forwarding rules" not "Gas Forwarding Rules." Capitalize only proper nouns (MegaETH, Ethereum, Rex3).
- **Serial commas**: Use serial (Oxford) commas in lists of three or more: "compute gas, storage gas, and detention gas."

## Cross-Linking

### Within the same layer

Use relative paths: `[Gas Model](gas-model.md)` or `[RPC Methods](rpc/overview.md)`.

### Between layers

Use relative paths from the current file: `[Connect](../user/connect.md)` or `[EVM Differences](../dev/execution/overview.md)`.

### To the EVM Specification

The EVM spec is in `docs/spec/`. Use relative paths:
`[Dual Gas Model](../spec/evm/dual-gas-model.md)`.

### Direction rule

- **User docs → Developer docs**: "For technical details, see [Developer Docs](../dev/...)."
- **Developer docs → EVM Spec**: "For the formal specification, see [Dual Gas Model](../spec/evm/dual-gas-model.md)."
- **EVM Spec → nothing**: The spec is self-contained. It never links to user or developer docs.

## Content Reuse

If the same information appears in multiple layers (e.g., chain ID, RPC URLs), create a shared reference and link to it rather than duplicating.
Candidates for shared content: network parameters, contract addresses, chain IDs.

## GitBook Custom Blocks (Most Used)

```markdown
{% hint style="info" %}
Informational callout.
{% endhint %}

{% hint style="warning" %}
Warning callout.
{% endhint %}

{% hint style="danger" %}
Danger callout.
{% endhint %}

{% hint style="success" %}
Success callout.
{% endhint %}

{% tabs %}
{% tab title="Tab 1" %}
Content for tab 1.
{% endtab %}
{% tab title="Tab 2" %}
Content for tab 2.
{% endtab %}
{% endtabs %}

{% stepper %}
{% step %}
## Step title
Step content.
{% endstep %}
{% endstepper %}
```

## Images

Store images in `docs/.gitbook/assets/` and reference them as:
```markdown
![Alt text](../.gitbook/assets/image-name.png)
```
