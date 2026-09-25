---
name: secret-ballet
description: "The round trip for changing anything under secrets/ in dhevmera: reconcile across hosts, commit, pack, publish, then fetch, unpack and relink on each other host. Use whenever a credential, token, key or secrets/config file is added, changed or removed - or when asked to pack, publish or refresh the secrets."
---

# secret-ballet

`secrets/` is a separate, remote-less git repo that travels as a GPG
self-extractor. It does not move by push and pull, and the trip is one-way per
run: **an unpack replaces the receiving host's `secrets/` wholesale, `.git`
included.** Anything that host held and the snapshot does not is gone, committed
or not.

That is why this is a ballet and not a command. `README.md` carries the
reasoning; this is the order of steps.

## Before packing anything

**Check every host, not just the one you are publishing from.**

```bash
git -C secrets status --short        # on parsifal, svm and the tablet
```

A host with something uncommitted, or with a key the others lack, cannot simply
receive a snapshot — it would lose it. Reconcile everything onto one host first
and pack from there. The snapshot is only safe when it is a superset.

Ignore OAuth `token` lines when comparing: they differ on every host and are
refreshed on use, so a token-only diff is nothing to reconcile.

## While you are in here anyway

A secrets change that has to travel is the moment to clear anything queued for
exactly that reason, since the round trip is the cost, not the edit. Check
`README.md` for what is waiting, and mention what you took out rather than
proposing it as its own job.

## The sequence

Run all of it from the repo root — these scripts use relative paths.

1. **Edit** under `secrets/config/`, then **commit inside `secrets/`** — it is
   its own repo, and the parent's commits do not cover it.
2. **Pack**: `rm -f scripts/unpack-secrets` first, because `pack-secrets`
   refuses to overwrite one. Then `./scripts/pack-secrets`.
3. **Publish**: `./scripts/publish-secrets` — rclone to `od:Archive/Items/`.
4. **On each other host**: `rm -f scripts/unpack-secrets`, then
   `./scripts/fetch-secrets`. It refuses to overwrite too, and that refusal is a
   real guard on this side: it stops a local pack you have not published from
   being replaced by the older copy on the remote. Read the refusal before
   clearing it.
5. **Unpack**: `mv secrets secrets.old` first — `unpack-secrets` refuses when
   `secrets/` exists — then `./scripts/unpack-secrets` and enter the passphrase.
   A snapshot packed before `unpack-secrets` derived its root still defaults to
   `/chome/santini/dhevmera`: off svm, pass it the repo root. It chmods the tree
   700 itself.
6. **Relink only if the set of files changed.** `_install` links a path, not an
   inode, so an unpack that restores the same filenames leaves every existing
   link resolving correctly and needs nothing. A secret that was *added* or
   *renamed* needs its `_install` line and a run of `./scripts/install-dotfiles`
   from the repo root.
7. **Verify, then delete `secrets.old`.** Not before: it is the only copy of
   what that host had.

Secrets roots: `"$HOME/dhevmera"` on parsifal and the tablet, the default on
svm.

## Traps worth naming

- The tablet is reachable once `empower` has run there. If `ssh tablet` fails,
  ask Massimo to rerun it (it is idempotent) and finish the tablet once he has;
  never work around it.
- `scripts/unpack-secrets` is generated and gitignored. Leaving one lying around
  is what makes the next pack or fetch refuse.
- Nothing under `secrets/` is ever committed to the parent repository, which is
  public.
