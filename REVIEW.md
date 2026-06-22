# Review Guidelines

The centralized `pr-review` action already applies the baseline rubric (review mindset, priority order, generic checks, the "what not to flag" list, the severity scale, and previous-thread triage). This file only adds the checks **specific to this docs repo**; defer to the baseline otherwise.

## Always check

- Markdown files have YAML frontmatter with a `description` field
- Internal links use correct relative paths with `.md` extensions
- New pages are listed in `docs/SUMMARY.md`
- One sentence per line (improves diff readability)
- GitBook custom blocks (`{% hint %}`, `{% tabs %}`, etc.) are correctly opened and closed

## Content quality

- Writing follows the layer-specific `AGENTS.md` rules for the directory being edited
- Heading hierarchy is correct (no skipped levels)
- Code examples use appropriate language tags in fenced code blocks
- Each fact has exactly one authoritative home; detailed pages keep the implementation details, and overview or architecture pages link to them instead of restating details that will drift
- Cross-references between layers use correct relative paths
- External spec links use absolute GitBook URLs (not relative paths to `docs/spec/`)

## Skip

- Whitespace-only or formatting-only diffs
- Changes to `.claude/` skill files
