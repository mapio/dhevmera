@README.md

## For Claude sessions

- **Memory here is public.** `.claude/memory/` is versioned in this repo and
  therefore world-readable, so the routing rule governs it too: a note about QBT
  work belongs in that project's memory, never in this one.
- `.claude/skills/` names the two procedures this layout implies but nothing
  here states as a sequence: **`roam`** lands a change on every host,
  **`secret-ballet`** is the pack, publish, fetch, unpack round trip. They hold
  the order of steps and defer to `README.md` for why each step is shaped as it
  is; keep it that way, or they become a second copy that ages.
- `dotfiles/ssh/` and `dotfiles/aichat/` keep their notes in a `README.md` of
  their own, which the one-line `CLAUDE.md` beside it imports when a file there
  is read.

## Read the global instructions first

**`~/.claude/CLAUDE.md`** — the general rules for every repository, deployed
from `dotfiles/claude/instructions.md` in this one. Nothing here repeats it.
