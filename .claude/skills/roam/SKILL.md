---
name: roam
description: "Land a dhevmera change on every host: commit, push, pull on the others, relink what the change deploys, and verify the links. Use whenever anything under dotfiles/, scripts/ or .claude/ has been changed and should take effect beyond the machine it was edited on - or when asked to roam, deploy, or sync the config."
---

# roam

A change to this repository does nothing on the other hosts until it is pushed,
pulled and relinked there. This is that sequence. `CLAUDE.md` says *why* each
step is shaped as it is; do not restate it here, read it when a step surprises
you.

## The hosts

| host     | repo                                                  | secrets root for the scripts        |
| -------- | ----------------------------------------------------- | ----------------------------------- |
| parsifal | `~/dhevmera`                                          | `"$HOME/dhevmera"`                  |
| svm      | `/chome/santini/Activities/Programming/dhevmera`      | default (`/chome/santini/dhevmera`) |
| tablet   | `~/dhevmera` (Termux, `$HOME` is not `/home/santini`) | `"$HOME/dhevmera"`                  |

svm's repo is also reachable as `/chome/santini/dhevmera`, a symlink. Pull
through whichever you like, but anything that records a path — a symlink target,
a unit file — spells out the resolved `Activities/` one.

The tablet answers once `scripts/empower` has run there: it leaves detached
masters behind and exits. If `ssh tablet` fails, a master has been lost (reboot,
network change): ask Massimo to rerun `empower`, which is idempotent, do the
other hosts meanwhile, and finish the tablet once he says it has run. Never try
to route around it.

## The sequence

1. **Commit** on the host the change was made on. Signed — a GPG failure stops
   the ballet, it is never worked around.
2. **Push** to `origin`.
3. **Pull** on each other host: `git -C <repo> pull --ff-only`. If it is not a
   fast-forward, that host has its own commits; stop and reconcile before going
   on.
4. **Relink**, but only if the change added, renamed or moved something that
   `install-dotfiles` deploys. Editing a file already linked needs no relink —
   the symlink is to the file, so the pull alone did it. When a relink is
   needed, run `./scripts/install-dotfiles <secrets root>` from the repo root on
   that host, or make the single `ln -sfn` by hand when only one destination is
   affected.
5. **Tagged things are separate.** `install-dotfiles` does not touch them. A
   change under `dotfiles/systemd/` or `dotfiles/ssh/{keys,authorized_keys}/`
   needs `./scripts/install-host` on the hosts carrying that tag.
   - Units: it reloads and lists what differs from the repo; `--activate` applies
     that. Ask before `--activate` where a restart would interrupt a running
     service. Never `disable` or `reenable` a unit this repo deploys.
   - authorized_keys: when it changed, confirm it from another host within ten
     minutes, over a new connection:
     `ssh -o ControlMaster=no -o ControlPath=none <host> <repo>/scripts/install-host --confirm`.
     If it reverted instead, stop and tell Massimo.
   - Never pass `--adopt` or `--prune` without asking him first.
6. **Claude setup.** `install-dotfiles` does not touch `~/.claude` either. A
   change that adds, removes or renames a skill, or touches
   `scripts/setup-claude`, needs `./scripts/setup-claude` on each host with
   Claude Code (not the tablet). If it reports a stale skill link, ask Massimo
   before re-running it with `--prune`; never prune on your own.

## Verify before declaring it done

Per host (the tablet has no `~/.claude`, so only the first line applies there):

```bash
find ~/.config/systemd/user -xtype l    # dangling unit links; want no output
ls -la ~/.claude/CLAUDE.md              # a symlink into the repo, never a plain file
ls -la ~/.claude/settings.json          # likewise, where a tag of the host has one
find ~/.claude/skills -xtype l          # dangling skill links; want no output
for d in dotfiles/claude/skills/*/; do    # from the repo root; want no output
  [ "$(readlink ~/.claude/skills/"$(basename "$d")")" = "$(pwd -P)/${d%/}" ] || echo "unlinked: $d"
done
readlink ~/.claude/projects/"$(pwd -P | sed 's/[^A-Za-z0-9]/-/g')"/memory    # from the repo root
```

Then compare what the hosts actually see, rather than trusting that a pull did
it:

```bash
md5sum ~/.claude/CLAUDE.md
(cd ~/.claude/skills && for d in "$OLDPWD"/dotfiles/claude/skills/*/; do md5sum "$(basename "$d")"/*; done)
```

The same digest on every host is the only proof that matters. A file that
differs between hosts is invisible from inside a session — that is the whole
failure mode this repository is arranged to prevent.

## Not this skill's job

Changes under `secrets/` do not travel by push and pull. They have their own
ballet; use the `secret-ballet` skill.
