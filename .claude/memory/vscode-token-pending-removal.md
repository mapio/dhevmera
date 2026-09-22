---
name: vscode-token-pending-removal
description: VSCODE_TOKEN is dead in secrets/config/bash_secrets and should be dropped the next time secrets change for another reason
metadata:
  type: project
---

`VSCODE_TOKEN` in `secrets/config/bash_secrets` has no reader left: `scripts/start-vscode`
was the only one and was removed on 2026-09-22 (commit f786ffd). Massimo knows, and chose
to leave it — deleting it on its own would cost a `pack-secrets`, `publish-secrets`, then
`fetch-secrets` and `unpack-secrets` on all three hosts, which is not worth it for one dead
line.

**Why:** his words were "I'm too lazy to repack/publish/fetch/unpack" — the cost is the
round trip, not the edit.

**How to apply:** the next time `secrets/` changes for a reason that has to travel anyway,
remove that line in the same pass and mention it, rather than proposing it as its own job.
The note is also in CLAUDE.md beside the `GITHUB_TOKEN` bullet. See
[[reaching-the-tablet]] for what a secrets refresh involves.
