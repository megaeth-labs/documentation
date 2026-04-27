# AGENTS.md

This file provides guidance to AI agents (e.g., Claude Code, Codex, Cursor, etc.) when working with content in this repository.

## Project Overview

MegaETH Documentation — the official documentation site for MegaETH, hosted at [docs.megaeth.com](https://docs.megaeth.com).
Documentation is written in GitBook-flavored Markdown and deployed via GitBook with Git Sync.
For GitBook syntax, custom blocks, configuration, and best practices, follow the [official GitBook skill file](https://raw.githubusercontent.com/GitbookIO/public-docs/refs/heads/main/skill.md).

## Documentation Architecture

The site is organized into layers, each targeting a different audience:

| Layer                   | Directory                                                 | Audience                        | Tone                               |
| ----------------------- | --------------------------------------------------------- | ------------------------------- | ---------------------------------- |
| **User Guide**          | `docs/user/`                                              | End users (wallets, DeFi users) | Plain language, no code            |
| **Developer Docs**      | `docs/dev/`                                               | Dapp/contract builders          | Practical guidance, code examples  |
| **Stateless Validator** | `docs/stateless/`                                         | Node operators                  | Reference, copy-paste commands     |
| **Specification**       | [mega-evm repo](https://github.com/megaeth-labs/mega-evm) | Protocol implementers, auditors | Normative (MUST/SHALL), exhaustive |

Each layer has its own `AGENTS.md` with layer-specific writing rules.
The Specification layer is maintained in the [mega-evm repository](https://github.com/megaeth-labs/mega-evm) and synced into the same GitBook site via Git Sync.
It does not live in this repo — do not create or edit `docs/spec/` files here.

## Project Structure

```
.
├── .gitbook.yaml              # GitBook config (root: ./docs/)
├── AGENTS.md                  # This file — repo-level guidance
├── CLAUDE.md                  # Claude-specific overrides
├── docs/                      # Documentation source (GitBook-flavored Markdown)
│   ├── AGENTS.md              # Docs-wide conventions (cross-linking, formatting)
│   ├── README.md              # Site landing page
│   ├── SUMMARY.md             # Table of contents / navigation
│   ├── user/                  # User Guide layer
│   │   ├── AGENTS.md          # User layer writing rules
│   │   └── *.md
│   ├── dev/                   # Developer Docs layer
│   │   ├── AGENTS.md          # Developer layer writing rules
│   │   ├── send-tx/           # Submitting transactions
│   │   ├── read/              # Reading from MegaETH (RPC, realtime API)
│   │   │   └── rpc/           # RPC method reference pages
│   │   └── execution/         # EVM differences, gas model, resource limits
│   └── stateless/             # Stateless Validator layer
│       ├── AGENTS.md          # Stateless layer writing rules
│       └── *.md
├── .sisyphus/plans/           # Restructure planning docs
└── .github/workflows/
    └── claude.yml             # Claude Code Action: PR review, interactive assistance
```

## Version Control

The main branch is `main` and it is protected.
All changes should be made via PRs on GitHub.

### Branch naming convention

The naming convention for git branches is `{developer}/{category}/{description}`, where:

- `{developer}` is the (nick)name of the developer.
- `{category}` should indicate the type of modification, e.g., `doc`, `fix`, `ci`, `style`.
- `{description}` is a short description of the changes (a few words, hyphen-separated).

Example: `william/doc/add-gas-model-guide`, `alice/fix/broken-internal-link`.

## Workflows

### Editing documentation

1. Edit or create Markdown files under `docs/`.
2. Follow the layer-specific `AGENTS.md` rules for the directory you're editing.
3. Update `docs/SUMMARY.md` if adding or removing pages.
4. Commit source changes only.

### Adding a new page

1. Create the `.md` file in the appropriate layer directory (`user/`, `dev/`, or `spec/`).
2. Add a `description` field in YAML frontmatter for SEO.
3. Add the page to `docs/SUMMARY.md` in the correct section.
4. Commit.

### Committing changes

When requested to commit changes, first review all changes in the working tree, regardless of whether they are staged.
Only commit source Markdown and configuration changes.
Keep commit messages simple — no co-author information or "generated with" footers.

### Creating PRs

When a PR creation is requested, the agent should:

1. Check if the repo is on a branch other than `main`; if not, create and checkout a new branch and inform the user.
2. Commit all source changes.
3. Push to the remote.
4. Use the `gh` CLI tool to create a PR with a `Summary` section at the top of the description.

## Caveats for Agents

- **Use GitBook-flavored Markdown.**
  Follow the GitBook skill file linked above for the full syntax reference including custom blocks (`{% hint %}`, `{% tabs %}`, `{% stepper %}`, etc.).
- **Keep SUMMARY.md in sync.**
  Every page must be listed in `docs/SUMMARY.md`. GitBook uses this file for navigation.
- **Use relative links with .md extensions.**
  Internal links should be `[text](../dev/gas-model.md)`, not `[text](/dev/gas-model)`.
- **Respect layer boundaries.**
  Each layer has its own `AGENTS.md` with specific writing rules. Read the layer's `AGENTS.md` before editing content in that directory.
- **One sentence, one line.**
  When writing Markdown files, put each sentence on a separate line.
  This improves diff readability and makes reviews easier.
- **Cross-link to the EVM spec with absolute URLs.**
  The EVM spec is maintained in the mega-evm repo and synced into a separate GitBook space — it does not exist as a file in this repo.
  Use absolute URLs with the base `https://docs.megaeth.com/spec/`: `[Dual Gas Model](https://docs.megaeth.com/spec/megaevm/dual-gas-model)`.
  EVM pages use the `megaevm/` prefix (not `evm/`), system contracts use `system-contracts/`.
- **Keep commit messages simple.**
  No co-author information or "generated with" footers.
