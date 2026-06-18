# Claude CI Composite Actions

Reusable Tier-1 Claude CI actions for MegaETH repositories.

## Actions

- `.github/actions/claude-interactive` - interactive `@claude` handling.
- `.github/actions/claude-pr-review` - pull request review.
- `.github/actions/claude-label-check` - pull request label validation.
- `.github/actions/claude-issue-triage` - newly opened issue triage.

## Inputs

All actions accept:

- `claude_code_oauth_token` - required. Pass `${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}`.
- `allowed_bots` - optional, defaults to `mega-putin`.
- `extra_allowed_tools` - optional, appended to the canonical `--allowedTools` list. Rust repos can pass `Bash(cargo:*)` here.

Prompt-bearing actions (`pr-review`, `label-check`, and `issue-triage`) also accept:

- `extra_prompt` - optional, appended after a blank line for per-repo prompt deltas.

The `interactive` action does not accept `extra_prompt` because `@claude` is native.

## Per-Repo Conventions

The prompt-bearing actions instruct Claude to read and respect a consumer repo's own agent
instruction files when they exist (`REVIEW.md`, `README.md`, `CLAUDE.md`, `AGENTS.md`, and any
other repo-level agent guidance), with those per-repo rules taking precedence over the
canonical inline prompt. Use these files for repo-specific rules; reserve `extra_prompt` for
small deltas that do not belong in a checked-in convention file.

`pr-review` additionally tags every inline comment with a bold severity label
(`**[Critical]**`, `**[Major]**`, `**[Minor]**`, `**[Nit]**`). A consumer repo's `REVIEW.md`
may override or extend this severity scale.

## Consumer Requirements

Consumer jobs should pin these actions to `@main`. A merge to `mega-agents` `main` goes live
for every consumer automatically, with no consumer workflow edits required.
Use `megaeth-labs/mega-agents/.github/actions/claude-interactive@main`,
`megaeth-labs/mega-agents/.github/actions/claude-pr-review@main`,
`megaeth-labs/mega-agents/.github/actions/claude-label-check@main`, or
`megaeth-labs/mega-agents/.github/actions/claude-issue-triage@main`.

Mega-agents dogfoods these actions through the local `./.github/actions/claude-<name>` path, so every
PR to mega-agents smoke-tests them before merge.

Consumer jobs must run `actions/checkout` before these actions. They must also provide the
`CLAUDE_CODE_OAUTH_TOKEN` secret and set role-appropriate job permissions:

- `claude-interactive`: `contents: write`, `pull-requests: write`, `issues: write`, `id-token: write`, `actions: read`
- `claude-pr-review`: `contents: read`, `pull-requests: write`, `id-token: write`, `actions: read`
- `claude-label-check`: `contents: read`, `pull-requests: write`, `id-token: write`
- `claude-issue-triage`: `contents: read`, `issues: write`, `id-token: write`

Before consumer repositories can reference these private actions, maintainers must enable
Settings -> Actions -> General -> Access -> "Accessible from repositories in the megaeth-labs organization".

## Example

```yaml
jobs:
  pr-review:
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      pull-requests: write
      id-token: write
      actions: read
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
          fetch-depth: 1

      - uses: megaeth-labs/mega-agents/.github/actions/claude-pr-review@main
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          extra_allowed_tools: "Bash(cargo:*)"
          extra_prompt: |
            Add repository-specific review instructions here.
```

> Note: a PR that _modifies the calling repo's own_ `claude.yml` will fail the `pr-review`
> job once with `401 ... Workflow validation failed ...` (claude-code-action validates the
> workflow against the default branch). This is expected and clears after the PR merges;
> it does not affect consumers pinned to `@main` in normal operation.
