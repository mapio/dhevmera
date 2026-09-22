---
name: keep-inline-comments-short
description: Massimo dislikes large blocks of comments in scripts and config files; the long "why" belongs in commit messages and CLAUDE.md
metadata:
  type: feedback
---

Keep comments in scripts and config files terse — a line or two for the load-bearing
"why", not a paragraph. Stated on 2026-09-22 while committing the aichat work: he
stripped the explanatory block I had added to `secrets/config/bash_secrets` and said
"I don't like large chunks of comments in scripts or conf files".

**Why:** the detailed reasoning already has two homes in this repo — commit messages,
which carry full multi-paragraph bodies, and `CLAUDE.md`, whose gotcha list is where a
future reader actually looks. Repeating it inline is duplication that then rots.

**How to apply:** write the long explanation in the commit body and, if it is a trap
worth remembering, as a CLAUDE.md bullet; leave the file itself with a short pointer.
Note some older fragments (`40-java.sh`, `45-rust.sh`) predate this and are heavily
commented — do not take them as the target style. See [[dhevmera-doc-conventions]].
