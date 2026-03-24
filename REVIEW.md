# Documentation Review Guidelines

## Always check

- Every new or modified `.md` file under `docs/` has YAML frontmatter with both `title` and `rank`
- Internal links use root-relative paths without extensions: `[text](/pagename)`, not `[text](pagename.html)` or `[text](pagename.md)`
- Multi-file pages (directories under `docs/`) use numeric prefixes for ordering (e.g., `1-intro.md`, `2-details.md`)
- Content follows one-sentence-per-line style for diff readability
- Technical claims are accurate and consistent with other documentation pages

## Content quality

- New documentation is clear, concise, and written for developers
- Pandoc-flavored Markdown is used correctly (not GitHub-flavored Markdown assumptions)
- No broken links to internal pages or external resources
- Code examples are syntactically correct and use appropriate language tags in fenced code blocks

## Previous comments

- Before writing new comments, check all previous review comments and threads on this PR
- If a previous comment has been addressed by the latest changes, resolve that thread
- Do not repeat feedback that has already been addressed

## Skip

- Changes to `public/` that are simply regenerated output from `make`
- Whitespace-only or formatting-only diffs in generated HTML files
- CSS styling changes (these are design decisions, not documentation correctness)
