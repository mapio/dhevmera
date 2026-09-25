---
name: feedback-simple-over-tooling
description: When a config grows per-host differences, review it and split it into plain per-tag files first; no merge or analysis tooling unless asked
metadata:
  type: feedback
---

On 2026-09-25, asked how dhevmera should manage `~/.claude/settings.json`, I
proposed a merge tool (fragments per tag, owned-entry tracking, a `--promote`
option). He stopped it: "NO it is not time to write such a complex
merge/analyze tool; I think we can review the present setups and put them in
files distinct by tag and symlink". The review then removed most of the
content, which made the tool unnecessary anyway.

**Why:** complexity he did not ask for is wasted effort, and the review is what
reveals how little actually needs managing.

**How to apply:** for a config that differs per host, first review it piece by
piece with him, then propose one file per tag, linked by `setup-claude` or
`install-host`. Suggest tooling only once plain files demonstrably fail.
