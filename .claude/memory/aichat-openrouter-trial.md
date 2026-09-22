---
name: aichat-openrouter-trial
description: aichat runs on OpenRouter with deepseek-v4-flash as the paid default; Massimo wants to review how it goes around 2026-10-22
metadata:
  type: project
---

`aichat` was added to dhevmera on 2026-09-22 for recalling the syntax of awkward commands
(jq, find, awk) — not for large tasks. It talks to OpenRouter, and Massimo put credit on
the account that day so the default could be the paid `deepseek/deepseek-v4-flash`
($0.0886/M in) rather than a free model. His words: "let's see how it goes in a month",
so **around 2026-10-22 it is worth asking** whether it earns its keep — check actual spend
with `curl -H "Authorization: Bearer $OPENROUTER_API_KEY" https://openrouter.ai/api/v1/key`
(the `usage` fields) against how often he reaches for it.

**Why:** the choice was made on one afternoon of testing, and both the price and the free
roster move. The free models stay listed in the config as the fallback if the paid default
disappoints or the spend surprises.

**How to apply:** if the review happens, the benchmarked alternative is the *paid*
`nex-agi/nex-n2.5-mini` — half the price, two to five times faster, equally correct on
three shell-recall prompts. He chose deepseek anyway, for headroom on harder questions;
that is the thing to test before switching. `nex-agi/nex-n2.5-mini:free` was the best of
the free roster. See [[keep-inline-comments-short]] for
how to write up anything that comes out of it.
