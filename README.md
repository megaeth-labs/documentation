# MegaETH Documentation

Official documentation for MegaETH, hosted at [docs.megaeth.com](https://docs.megaeth.com).

Documentation is written in GitBook-flavored Markdown and deployed via GitBook with Git Sync.

## Structure

```
docs/                  Documentation source
├── README.md          Landing page
├── SUMMARY.md         Table of contents / navigation
├── architecture.md    Architecture overview
├── mini-block.md      Mini-block design
├── user/              User Guide (wallets, bridging, getting started)
└── dev/               Developer Docs (gas model, RPC, debugging)
    ├── send-tx/       Submitting transactions
    ├── read/          Reading from MegaETH (RPC, realtime API)
    └── execution/     EVM differences, gas model, resource limits
```

## Linting & Formatting

CI runs three checks on all Markdown files:

| Tool                                                            | What it checks                                             | Config                    |
| --------------------------------------------------------------- | ---------------------------------------------------------- | ------------------------- |
| [lychee](https://lychee.cli.rs/)                                | Internal links resolve to existing files                   | `lychee.toml`             |
| [markdownlint](https://github.com/DavidAnson/markdownlint-cli2) | Markdown structure (blank lines, heading style, bare URLs) | `.markdownlint-cli2.yaml` |
| [Prettier](https://prettier.io/)                                | Consistent formatting (tables, spacing, indentation)       | `.prettierrc.yaml`        |

To run locally:

```bash
# Install tools via mise (one-time setup)
mise install

# Run all checks
mise run lint

# Auto-fix formatting
mise run fmt
```

## Contributing

1. Edit or create Markdown files under `docs/`.
2. Update `docs/SUMMARY.md` if adding or removing pages.
3. Run `mise run fmt` to format, then `mise run lint` to verify.
4. See `AGENTS.md` for writing conventions and layer-specific rules.
