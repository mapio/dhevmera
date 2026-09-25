# One Markdown wrap width for every repository

## Why

The global instructions set 80 columns with mdformat and both plugins, then let
a project override "the width or the tool in its own `CLAUDE.md` — and some do,
with a pre-commit hook". So the width a file ends up at depends on which
repository it is in, and on whether that repository wrote its exception down:
dhevmera itself had been hand-wrapped at about 90 with no override recorded,
until the documentation split rewrapped it.

## Decided

- **One width, 80, with one tool**: `mdformat --wrap 80` with `mdformat-gfm` and
  `mdformat-frontmatter`. The override sentence goes from
  `dotfiles/claude/instructions.md`.
- **The survey covers svm and parsifal**: every repository whose `CLAUDE.md`
  sets its own width or tool, or whose pre-commit config runs mdformat or
  another Markdown wrapper.
- **QBT repositories appear here by path only**, never with their content.

## Open

- For each repository with a pre-commit hook: keep the hook, set to `--wrap 80`,
  or remove it and rely on the global rule. A hook enforces the rule where the
  instructions only ask.
- Whether existing files in those repositories get rewrapped now, one commit per
  repository, or are left until they are next edited.
- `--number` for ordered lists: mdformat defaults to `1.` throughout; the
  dhevmera skills use `--number` so their steps can be named by number. Whether
  that becomes part of the one rule.

## Steps

1. Survey: `grep` the `CLAUDE.md` files and `.pre-commit-config.yaml` files
   under the repository roots on svm and parsifal for `wrap`, `mdformat` and
   column widths; list what each sets.
1. Decide the open points above, one at a time.
1. Change the rule in `instructions.md`; roam.
1. Align each repository as decided, one commit each.
