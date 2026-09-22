---
name: aichat-openrouter-trial
description: aichat runs on OpenRouter with deepseek-v4-flash as the paid default; Massimo wants to review how it goes around 2026-10-22
metadata:
  type: project
---

`aichat` was added to dhevmera on 2026-09-22 for recalling the syntax of awkward
commands (jq, find, awk) — not for large tasks. It talks to OpenRouter, and
Massimo put credit on the account that day so the default could be the paid
`deepseek/deepseek-v4-flash` rather than a free model. His words: "let's see how
it goes in a month", so **around 2026-10-22 it is worth asking** whether it
earns its keep — check actual spend with
`curl -H "Authorization: Bearer $OPENROUTER_API_KEY" https://openrouter.ai/api/v1/key`
(the `usage` fields) against how often he reaches for it.

**Why:** the choice was made on one afternoon of testing, and both the price and
the free roster move.

**How to apply:** `CLAUDE.md` carries what that afternoon measured, including
the cheaper and faster alternative he passed over for headroom on harder
questions. That trade is the thing to re-test before switching; do not reopen it
on price alone.
