---
name: rclone-config-compare
description: How to compare rclone.conf copies across hosts and the tablet — ignore OAuth tokens, compare everything else
metadata:
  type: feedback
---

When comparing `rclone.conf` copies (svm, parsifal, Termux, the RSAF export in
the tablet's Downloads), **ignore `token` lines entirely** — no expiry
comparison, no "keep the newer token" step when reconciling. Compare only the
other properties: which remotes exist, their type, host/url/user/remote and the
other options, and whether the secret-bearing values (`pass`, `password`,
`password2`, `key_pem`, …) match.

**Why:** Massimo, 2026-09-24: "don't fiddle with tokens, they are refreshed when
using rclone, stop worrying about tokens, look just at other properties". Every
host refreshes its own token on use, so token diffs are always present and mean
nothing.

**How to apply:**

- Read the file itself, never `rclone config show`: since 1.75 it prints crypt
  passwords as `*** ENCRYPTED ***`.
- Compare secret values by hash (e.g. `sha256sum | cut -c1-8`), never print
  them. Obscured values are reversible (`rclone reveal`), so they are plaintext
  for this purpose. Redact with a pattern that also catches lines with a diff
  prefix (`^[^=]*(token|pass|secret|key)[^=]*=`); an anchored `^token` once let
  a token through in a `diff` context line.
- An obscured value's length gives its plaintext length: base64url of a 16-byte
  IV plus the ciphertext, so 22 characters means an empty value.
- RSAF adds its own keys (`` `rsaf:thumbnails` ``, `md5sum_command`,
  `sha1sum_command`); those are not real differences.
