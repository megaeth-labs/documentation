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

## Linting

CI runs two checks on all Markdown files:

| Tool | What it checks | Config |
| ---- | -------------- | ------ |
| [lychee](https://lychee.cli.rs/) | Internal links resolve to existing files | `lychee.toml` |
| [markdownlint](https://github.com/DavidAnson/markdownlint-cli2) | Markdown structure (blank lines, heading style, bare URLs) | `.markdownlint-cli2.yaml` |

To run locally:

```bash
# Install
brew install lychee
npm install -g markdownlint-cli2

# Run
lychee '**/*.md'
markdownlint-cli2
```

## Contributing

1. Edit or create Markdown files under `docs/`.
2. Update `docs/SUMMARY.md` if adding or removing pages.
3. Run `lychee '**/*.md'` and `markdownlint-cli2` to verify before pushing.
4. See `AGENTS.md` for writing conventions and layer-specific rules.
