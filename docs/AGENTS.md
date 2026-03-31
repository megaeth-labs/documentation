# Documentation Conventions

These rules apply across the documentation site.

## Tone by Level

The documentation has two tonal registers depending on where a page lives:

- **Top-level pages** (`docs/architecture.md`, `docs/mini-block.md`, `docs/README.md`) use a **narrative, explanatory tone**.
  Build an argument. Walk the reader through reasoning. Explain *why* things are the way they are.
  These pages read like a well-written technical blog post — engaging, flowing prose that tells a story.

- **Layer pages** (`user/`, `dev/`, `integration/`, `spec/`) use a **terse, reference tone**.
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

## Formatting

- **GitBook Markdown**: Use GitBook-flavored Markdown with custom blocks. See `/skill.md` for full syntax reference.
- **One sentence, one line**: Each sentence goes on its own line for better diffs.
- **Frontmatter**: Every page must have YAML frontmatter with at least `description` for SEO.
- **Headings**: Use `#` for the page title (H1), `##` for sections (H2), `###` for subsections (H3). One H1 per page.

## Cross-Linking

### Within the same layer

Use relative paths: `[Gas Model](gas-model.md)` or `[RPC Methods](rpc/README.md)`.

### Between layers

Use relative paths from the current file: `[Connect](../user/connect.md)` or `[EVM Differences](../dev/evm-differences.md)`.

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
