# Documentation: a README for humans, CLAUDE.md for sessions

## Why

`README.md` is three lines, while `CLAUDE.md` has grown to some 480 lines,
nearly all of it reference for whoever maintains the repo: the deployment model,
the secrets routing, tags, ssh keys, software buckets and the gotchas. Only a
handful of lines are about working with Claude. So the human documentation lives
in the file named for the assistant, and the one named for humans is empty.

Meanwhile `scripts/` holds eighteen commands, several with options
(`install-host` has five), written down only in each script's header, where
there is one, and in `CLAUDE.md`, which explains *why* rather than *how to
call*.

## Decided

- **`README.md` is the manual**: what the repo is, the command index, the
  deployment model, secrets, tags, ssh keys and units, where software goes, and
  the short gotchas.
- **Topic-heavy notes move beside their files**, as `dotfiles/claude/README.md`
  already does: aichat's model choice into `dotfiles/aichat/README.md`, the ssh
  config order, `empower` and Termux into `dotfiles/ssh/README.md`.
- **`CLAUDE.md` imports the manual** with `@README.md`, then holds only what is
  for sessions: memory here is public, so no QBT notes; `roam` and
  `secret-ballet` defer to the README; read `~/.claude/CLAUDE.md` first.
- **Topic READMEs load on demand**: each topic directory gets a one-line
  `CLAUDE.md` containing `@README.md`, which Claude Code loads the first time a
  session reads a file there (verified in code.claude.com/docs/en/memory).
  Sessions not touching that directory pay nothing.
- **The command index is one line per command**, grouped as entry points,
  bootstrap, secrets, backup, maintenance and tablet, with no option lists: a
  copy would drift from the script.
- **Options live in each script's header comment**, printed by `--help` (or
  `-h`), exit 0. A usage error prints the usage line and points at `--help`.
- **`--help` is one line per script**, no shared helper, so standalone scripts
  and the tablet's copies need nothing sourced:
  `case "$1" in -h|--help) sed -n '2,/^[^#]/s/^# \{0,1\}//p' "$0"; exit 0 ;; esac`.
  It prints the comment block that follows the shebang, so that block must come
  first, before `set -eo pipefail`.
- **`install-dotfiles` is aligned with `install-host`**: flags in any order, and
  the secrets root is `$REPO/secrets`, derived from the script's own location as
  the other two entry points do. The positional root and its svm default go, and
  so does `<secrets root>` in `roam`, `secret-ballet` and `CLAUDE.md`.
- **`unpack-secrets` follows suit through its generator**: `pack-secrets` writes
  its header, `--help` line and derived root. It shipping the old svm default
  until the next pack is accepted; no secret-ballet just for this.
- **Two commits for the split**: first a pure move at the current hand-wrapped
  ~90 columns, so it reviews as a move; then `mdformat --wrap 80` over
  `README.md`, `CLAUDE.md` and the topic READMEs, landing on the global default.
- **`install.d/` fragments are not in the index**: they are sourced by
  `install-software`, not commands.

## Steps

1. Split `CLAUDE.md`: human content into `README.md` and the two topic READMEs,
   session notes kept in `CLAUDE.md` under the `@README.md` import, stubs in
   `dotfiles/aichat/` and `dotfiles/ssh/`. Move text, do not rewrite it, so the
   diff is reviewable as a move. Commit.
1. `mdformat --wrap 80` over the moved files, checking that no `\[[` appears and
   backticked `@` paths stay literal. Commit.
1. Align `install-dotfiles` and the `unpack-secrets` generator on the derived
   secrets root.
1. Write or complete the header comment of each script: purpose, synopsis,
   options, where it runs. Most have none today.
1. Add the `--help` line to each script.
1. Write the command index in `README.md`.
1. Check the skills and `dotfiles/claude/README.md` for references to sections
   that moved; roam.
