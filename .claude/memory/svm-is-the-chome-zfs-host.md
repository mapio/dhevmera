---
name: svm-is-the-chome-zfs-host
description: svm (santinivm.docenti.di.unimi.it) is the host with the chome ZFS pool; it runs ytwit-bot. parsifal does not.
metadata:
  type: project
---

`svm` — `santinivm.docenti.di.unimi.it` in `dotfiles/ssh/config` — is the host where the
`chome` ZFS pool is mounted, so it is where `dotfiles/systemd/ytwit-bot.service` actually
runs (its `WorkingDirectory` is `/chome/santini/Activities/Programming/ytwit`).

`parsifal` is **not** that host: `/chome` is not mounted there, and as of 2026-09-04 none of
the repo's five units under `dotfiles/systemd/` were symlinked into
`~/.config/systemd/user/` on it. `parsifal-sync.timer` runs *toward* parsifal
(`parsifal.law.di.unimi.it`), it does not run on it.

**Why:** the repo names no hosts for its units, so which box to `daemon-reload` after
changing one is not derivable from the code — and guessing parsifal is the natural wrong
guess, since that is where sessions in this repo tend to run.

**How to apply:** after changing a unit in `dotfiles/systemd/`, the reload/restart goes on
`svm` for `ytwit-bot`. See [[agent-sessions-share-this-host]] for the parsifal side.
