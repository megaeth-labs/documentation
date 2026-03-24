# AGENTS.md

This file provides guidance to AI agents (e.g., Claude Code, Codex, Cursor, etc.) when working with content in this repository.

## Project Overview

MegaETH Documentation — the official user-facing documentation site for MegaETH, hosted at [docs.megaeth.com](https://docs.megaeth.com).
Documentation is written in Pandoc-flavored Markdown and converted to a static website via Pandoc and Make.
The site is deployed automatically via Cloudflare Pages from the `public/` directory.
CI automatically rebuilds `public/` on every PR and push to `main` — contributors do not need to run `make` or commit build output.

## Build Commands

```bash
# Build the website (outputs to public/)
make

# Clean build artifacts
make clean
```

Prerequisites: [Pandoc](https://pandoc.org/) and Make must be installed.
The entire toolchain is Pandoc + GNU Make + standard Unix tools (`echo`, `cat`, `sort`, `cut`, `cp`).

## Project Structure

```
.
├── docs/                  # Source Markdown (Pandoc-flavored, YAML frontmatter)
│   ├── *.md               # Single-file pages
│   ├── *.md.hidden        # Draft pages excluded from build
│   └── rpc/               # Multi-file page → public/rpc.html
│       ├── 1-method.md    # Part 1 (carries title + rank frontmatter)
│       └── 2-error-codes.md  # Part 2 (no title/rank — inherited from part 1)
├── template/
│   ├── template.html      # Pandoc HTML5 template (logo, TOC, navbar slot, footer)
│   ├── style.css          # Site-wide stylesheet
│   └── navitem.txt        # 1-line template: rank\t<li> entry for navbar sorting
├── manifest/              # Intermediate build artifacts (auto-generated, committed)
│   ├── *.txt              # Per-page navbar entries (rank\t<li>...</li>)
│   └── navbar.html        # Assembled <nav> injected into every page
├── public/                # Built HTML output — COMMITTED TO GIT, never ignored
├── Makefile               # Build system
├── AGENTS.md              # This file
├── CLAUDE.md              # Agent guidance (mirrors AGENTS.md)
└── .github/workflows/
    ├── claude.yml         # Claude Code Action: PR review, interactive assistance
    └── build-check.yml    # Auto-rebuilds public/ on PRs and pushes to main
```

## Page Inventory

| Rank | Title | Source | Type |
|------|-------|--------|------|
| 0 | Overview | `docs/index.md` | Single-file |
| 1 | Mainnet | `docs/frontier.md` | Single-file |
| 2 | Testnet | `docs/testnet.md` | Single-file |
| 5 | MegaEVM | `docs/megaevm.md` | Single-file |
| 10 | Architecture | `docs/architecture.md` | Single-file |
| 20 | Mini Blocks | `docs/miniblocks.md` | Single-file |
| 30 | Realtime API | `docs/realtime-api.md` | Single-file |
| 50 | RPC | `docs/rpc/` | Multi-file |
| 1000 | Faucet | `docs/faucet.md` | Single-file (embedded HTML/JS) |
| — | FAQ | `docs/faq.md.hidden` | Hidden draft (rank 900) |
| — | Tooling | `docs/infra.md.hidden` | Hidden draft (rank 40) |

Rank gaps are intentional — insert new pages between existing ranks without renumbering.

## Architecture

### Markdown Source Format

Each doc page is a Pandoc-flavored Markdown file under `docs/` with YAML frontmatter:

```yaml
---
title: Page Title
rank: 10
---
```

- `title` — displayed in the page `<h1>` header and navbar link text.
- `rank` — integer sort key controlling navbar ordering (lower = earlier).

Optional frontmatter fields (not used by build):

- `owners:` / `owner:` — editorial metadata indicating content ownership.
- `header-includes:` — Pandoc hook to inject content into `<head>` (used in `faucet.md` for a Cloudflare Turnstile `<script>` tag).

### Single-File vs Multi-File Pages

- **Single-file page**: `docs/foo.md` → `public/foo.html`.
- **Multi-file page**: `docs/foo/1-intro.md`, `docs/foo/2-details.md`, etc. are combined (via `--file-scope`) into a single `public/foo.html`.
  Files are concatenated in alphabetical order — use numeric prefixes for ordering.
  Only the **first file** (alphabetically) needs `title` and `rank` frontmatter; subsequent files inherit it for navbar purposes.

### Hidden Pages

Files ending in `.md.hidden` (e.g., `docs/faq.md.hidden`) are excluded from the Makefile's `$(wildcard docs/*.md)` and are never built.
When hiding a page, also remove any internal links to it from visible pages.

### Build Pipeline

1. **Manifest generation** — For each doc page, Pandoc extracts `rank` and `title` via `template/navitem.txt` to produce `manifest/*.txt` — a single line: `rank\t<li><a href="/page.html">Title</a></li>`.
2. **Navbar assembly** — All manifest entries are numerically sorted by rank (`sort -k1 -n`) then the rank column is stripped (`cut -f2`), producing `manifest/navbar.html`.
3. **Page rendering** — Each page is rendered through `template/template.html` with `--toc`, `--standalone`, `--shift-heading-level-by=1`, and the navbar injected via `--include-before-body`.
4. **CSS copy** — `template/style.css` is copied to `public/style.css`.

### Heading Level Shift

The `--shift-heading-level-by=1` flag means `#` (H1) in Markdown becomes `<h2>` in HTML output.
The template renders the frontmatter `title` as the page's `<h1>`.
Use `#` as the top-level section heading in your Markdown — it will render correctly as H2.

### Internal Links

Use root-relative paths **without** file extensions: `[link text](/pagename)`.
These resolve to `/pagename.html` on the deployed site.
Example: `[MegaEVM](/megaevm)`, `[Testnet](/testnet)`.

### CI / GitHub Actions

`.github/workflows/claude.yml` configures Claude Code Action with two jobs:

| Job | Trigger | Purpose |
|-----|---------|---------|
| `interactive` | `@claude` mention in PR/issue comments | Interactive Claude assistance (can write + commit) |
| `pr-review` | PR opened/updated | Automated code review with inline comments |

`.github/workflows/build-check.yml` automatically rebuilds `public/` and `manifest/` on every PR and push to `main`, committing the output back to the branch.

## Version Control

The main branch is `main` and it is protected.
All changes should be made via PRs on GitHub.

### Branch naming convention

The naming convention for git branches is `{developer}/{category}/{description}`, where:

- `{developer}` is the (nick)name of the developer.
- `{category}` should indicate the type of modification, e.g., `doc`, `fix`, `ci`, `style`.
- `{description}` is a short description of the changes (a few words, hyphen-separated).

Example: `william/doc/clarify-block-limit-overfill`, `alice/fix/broken-navbar-link`.

## Workflows

### Editing documentation

1. Edit or create Markdown files under `docs/`.
2. Commit the source changes.
3. CI will automatically rebuild `public/` and commit the output.

### Adding a new page

1. Create `docs/newpage.md` with `title` and `rank` frontmatter.
2. Pick a rank that slots into the desired navbar position (see Page Inventory).
3. Commit the new file — CI handles the build.

### Adding a multi-file page

1. Create `docs/newpage/1-intro.md` with `title` and `rank` frontmatter.
2. Create `docs/newpage/2-details.md` (no `title`/`rank` needed).
3. Commit — CI produces `public/newpage.html`.

### Committing changes

When requested to commit changes, first review all changes in the working tree, regardless of whether they are staged.
Do **not** commit `public/` or `manifest/` files — CI rebuilds these automatically.
Only commit source Markdown, templates, and configuration changes.

### Creating PRs

When a PR creation is requested, the agent should:

1. Check if the repo is on a branch other than `main`; if not, create and checkout a new branch and inform the user.
2. Commit all source changes (do **not** run `make` or commit built output).
3. Push to the remote.
4. Use the `gh` CLI tool to create a PR with a `Summary` section at the top of the description.

PRs will be merged on GitHub.
The PR description should clearly describe what documentation was added or changed.

## Caveats for Agents

- **Do not commit `public/` or `manifest/` manually.**
  CI automatically rebuilds and commits these on every PR and push to `main`.
  Do not run `make` before committing — only commit source changes.
- **Never gitignore `public/`.**
  The built website output must be committed so Cloudflare Pages can serve it.
- **Use Pandoc-flavored Markdown.**
  This is not GitHub-flavored Markdown.
  Pandoc supports definition lists, footnotes, fenced divs, and raw blocks (`{=html}`).
  When in doubt, check the [Pandoc manual](https://pandoc.org/MANUAL.html).
- **Include YAML frontmatter in every doc page.**
  Every `.md` file under `docs/` must have `title` and `rank` in its frontmatter.
  Exception: in multi-file pages, only the first file (alphabetically) needs `title` and `rank`.
  Missing `rank` will result in unpredictable navbar ordering.
- **Use root-relative links without extensions.**
  Internal links should be `[text](/pagename)`, not `[text](pagename.html)` or `[text](pagename.md)`.
- **Order multi-file pages with numeric prefixes.**
  Files in a directory page (e.g., `docs/rpc/`) are concatenated alphabetically.
  Use prefixes like `1-intro.md`, `2-details.md` to control section order.
- **One sentence, one line.**
  When writing Markdown files, put each sentence on a separate line.
  This improves diff readability and makes reviews easier.
- **Remove links to hidden pages.**
  When hiding a page (renaming to `.md.hidden`), check all visible pages for links to it.
- **Keep commit messages simple.**
  No co-author information or "generated with" footers.
