# Documentation Conventions

These rules apply to all documentation layers (user, dev, integration).

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
