# Review Guidelines

## Always check

- Markdown files have YAML frontmatter with `description` field
- Internal links use correct relative paths with `.md` extensions
- New pages are listed in `docs/SUMMARY.md`
- One sentence per line (improves diff readability)
- GitBook custom blocks (`{% hint %}`, `{% tabs %}`, etc.) are correctly opened and closed

## Content quality

- Writing follows the layer-specific `AGENTS.md` rules for the directory being edited
- Heading hierarchy is correct (no skipped levels)
- Code examples use appropriate language tags in fenced code blocks
- Cross-references between layers use correct relative paths
- External spec links use absolute GitBook URLs (not relative paths to `docs/spec/`)

## Previous comments

- Before writing new comments, check all previous review comments and threads on this PR
- If a previous comment has been addressed by the latest changes, resolve that thread
- Do not repeat feedback that has already been addressed

## Skip

- Whitespace-only or formatting-only diffs
- Changes to `.claude/` skill files
