---
name: gpg-passphrase-needs-real-terminal
description: pack-secrets and unpack-secrets must be run by Massimo in his own terminal; the ! prefix in a session does not give gpg a usable TTY
metadata:
  type: feedback
---

On 2026-09-25 I suggested `! ./scripts/pack-secrets` for the secret ballet. It
hung: gpg's symmetric passphrase prompt had no usable TTY, he backgrounded it
("bad idea to run from here i have no pty"), gpg cancelled, and it left a
partial `scripts/unpack-secrets` of 439 bytes with no payload. That partial file
would have made the next pack refuse, so it had to be removed first. The global
instructions then said `!` gave pinentry a TTY for `git commit`; he chose to
drop the `!` route there altogether.

**How to apply:** in the `secret-ballet` skill's steps, hand him the exact
command for his own terminal (pack on the packing host,
`mv secrets secrets.old && ./scripts/unpack-secrets [root]` on each receiver).
After any failed pack, check `scripts/unpack-secrets` for a `BEGIN PGP MESSAGE`
block before trusting it.
