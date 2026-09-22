---
name: never-reboot-parsifal-or-svm
description: Never reboot parsifal or svm without asking twice and getting explicit confirmation each time.
metadata:
  type: feedback
---

Never reboot `parsifal` or `svm` on your own initiative. Ask, and ask a **second** time
after the first yes, before any reboot actually happens. Massimo's words: "never reboot
parsifal or svm without asking twice".

This covers anything that reboots by implication too — `shutdown -r`, `systemctl reboot`,
a package action that would trigger one, or telling an installer it may restart the
machine. Pending-kernel notices from apt are a **report**, not a reason to act: surface
them and stop there.

**Why:** these two are the durable hosts, not the ephemeral cloud boxes this repo is
otherwise built around. `svm` carries the `chome` ZFS pool and runs the live services
(`ytwit-bot` plus both timers — see [[svm-is-the-chome-zfs-host]]), and its pool needs
`scripts/mount-zfs` and a key load after boot, so a reboot is not self-healing. Both hosts
are also reachable only over ssh, so a bad reboot is not recoverable from here.

**How to apply:** do the work, then report that a reboot is pending and let him choose. If
he asks for one, confirm once more before running it.
