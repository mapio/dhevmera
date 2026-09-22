---
name: secrets
description: "The round trip for changing anything under secrets/ in dhevmera: reconcile across hosts, commit, pack, publish, then fetch, unpack and relink on each other host. Use whenever a credential, token, key or secrets/config file is added, changed or removed - or when asked to pack, publish or refresh the secrets."
---

# secrets

`secrets/` is a separate, remote-less git repo that travels as a GPG
self-extractor. It does not move by push and pull, and the trip is one-way per
run: **an unpack replaces the receiving host's `secrets/` wholesale, `.git`
included.** Anything that host held and the snapshot does not is gone, committed
or not.

That is why this is a ballet and not a command. `CLAUDE.md` carries the
reasoning; this is the order of steps.

## Before packing anything

**Check every host, not just the one you are publishing from.**

```bash
git -C secrets status --short        # on parsifal, svm and the tablet
```

A host with something uncommitted, or with a key the others lack, cannot simply
receive a snapshot — it would lose it. Reconcile everything onto one host first
and pack from there. The snapshot is only safe when it is a superset.

Where the same key exists on two hosts with different values — an `[od]` token
each host refreshed for itself — the later `expiry` in the token JSON is the one
to keep.

## While you are in here anyway

A secrets change that has to travel is the moment to clear anything queued for
exactly that reason, since the round trip is the cost, not the edit. Check
`CLAUDE.md` for what is waiting, and mention what you took out rather than
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
   `secrets/` exists — then `./scripts/unpack-secrets <secrets root>` and enter
   the passphrase. It chmods the tree 700 itself.
6. **Relink only if the set of files changed.** `_install` links a path, not an
   inode, so an unpack that restores the same filenames leaves every existing
   link resolving correctly and needs nothing. A secret that was *added* or
   *renamed* needs its `_install` line and a run of
   `./scripts/install-dotfiles <secrets root>` from the repo root.
7. **Verify, then delete `secrets.old`.** Not before: it is the only copy of
   what that host had.

Secrets roots: `"$HOME/dhevmera"` on parsifal and the tablet, the default on
svm.

## Traps worth naming

- The tablet is reachable only while `empower`'s master is up. If it is not, say
  so and leave it — it will be a host running older credentials until the next
  trip, which is a fact to report, not to work around.
- `scripts/unpack-secrets` is generated and gitignored. Leaving one lying around
  is what makes the next pack or fetch refuse.
- Nothing under `secrets/` is ever committed to the parent repository, which is
  public.
