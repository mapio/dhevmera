---
name: reaching-the-tablet
description: The tablet (Termux, SM-X930) is reachable as ssh tablet, but only while empower's master from the tablet to svm is alive
metadata:
  type: reference
---

The tablet is a Samsung SM-X930 running Termux (`u0_a402`, prefix
`/data/data/com.termux/files/usr`, repo at `~/dhevmera`). Reach it with `ssh tablet`
from svm or parsifal — from parsifal that transparently jumps through svm, because svm
alone carries the reverse tunnel.

**It only works while `scripts/empower` has a live master from the tablet to svm.** That
is deliberate, not a bug: the tablet is reachable exactly when Massimo has chosen to
connect it. If `tablet` refuses, the master is gone and he has to re-run `empower`
there; nothing on this side can restore it.

`kex_exchange_identification: Connection reset by peer` means the tunnel is fine but
Termux's `sshd` is not running on the tablet — Termux does not start it for you. Do not
read that as a broken forward; it cost a wrong diagnosis on 2026-09-22.

See [[svm-is-the-chome-zfs-host]].
