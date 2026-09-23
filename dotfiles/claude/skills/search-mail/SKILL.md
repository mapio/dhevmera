---
name: search-mail
description: "Find and read Massimo's email: search the header index on mercurio from any host and print messages into the session. Use whenever a task needs something from his mail - a message, a thread, an attachment name, who said what when - or when asked to search, find or check mail."
---

# search-mail

The mailbox is `~/Maildir` on mercurio. Two tools read it, for two audiences:

- `~/mail-scripts/maildir_search.py` on mercurio is **his**: it hard-links the
  matches into the `Search` IMAP folder for his mail client, prints nothing
  useful to a session, and wipes that folder on every run. Its `--help` is the
  authority on its flags.
- `mail-query.py`, next to this file, is **yours**: it reads the same header
  index read-only and prints to stdout. It is piped over ssh, so nothing is
  deployed on mercurio (Python 3.9 there, stdlib only).

## Searching

```bash
ssh mercurio python3 - --from segreteria --since 2026-09-01 < ~/.claude/skills/search-mail/mail-query.py
```

Filters, all optional and ANDed: `--from`, `--to` (To/Cc/Bcc), `--subject` are
substrings; `--folder` is a LIKE pattern on the label (`INBOX`, `Sent`,
`Archived/2024`, `Archived/%`); `--since`/`--until` are inclusive `YYYY-MM-DD`;
`--limit` defaults to 50. Output is newest first, one message per line,
tab-separated: date, folder, filename, From, Subject. `--recipients` adds
To/Cc/Bcc as a sixth column, for who else was on a message.

Expect each message more than once: a copy in `INBOX`, one in `Archived/<year>`
and, for his own mail, one in `Sent`. Collapse copies by date and subject; never
drop a folder to deduplicate, because received mail often survives only in
`Archived/<year>`.

## Reading one

Pass the folder and filename from a search line. The filename carries `:` and
`,` so quote it twice, once for each shell:

```bash
ssh mercurio python3 - --show INBOX "'<filename>'" < ~/.claude/skills/search-mail/mail-query.py
```

It prints the main headers, the plain-text body (HTML if that is all there is)
and the attachment names. A stale filename still resolves: it matches on the
part before `:2,`, which is what changes when a message is read or answered.

## Freshness

The index is updated only when `maildir_search.py` runs. If what you are looking
for may be newer than the last run, ask him before refreshing it yourself,
because a run also replaces whatever he has in `Search`. If he says yes, run it
with the narrowest query that matches, so `Search` ends up holding something he
can use:

```bash
ssh mercurio '~/mail-scripts/maildir_search.py --from segreteria --since 2026-09-01'
```

## Boundaries

- Read-only. Never move, flag, delete or write into `~/Maildir`, and never write
  to the index except through `maildir_search.py`.
- Mail is private and some of it is QBT material under NDA. Quote only what the
  task needs, and never send any of it to an external service or a published
  artifact.
- The scripts come from the `mail-scripts` repo on svm
  (`Activities/Programming/`) through its `deploy`. Never edit them on mercurio.
