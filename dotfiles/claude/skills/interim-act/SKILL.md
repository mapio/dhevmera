---
name: interim-act
description: "Work through the notes in interim-todo.md one at a time: act on each now, turn it into a committed plan/<topic>.md, send it to the repository it is about, or drop it. Run by Massimo when the flow pauses; /sepolcro runs it first."
disable-model-invocation: true
---

# interim-act

`/interim-note` parked his ideas in `interim-todo.md` without discussion. Now is
the discussion. Every note ends up resolved or planned; none is left behind.

## Steps

1. Read `interim-todo.md` at the repository root (or the working directory
   outside a repository). Missing or empty: say so in one line and stop.
1. Take the notes in file order, **one at a time**. For each, ask with
   `AskUserQuestion`, never in prose: the question quotes the note verbatim,
   with its context line, and adds your one-line reading of what he meant. The
   header is `Note <i>/<n>`. The options are the four outcomes below, the one
   you recommend first and marked `(Recommended)`:
   - **Act now** — do it here and now.
   - **Plan it** — write `plan/<topic>.md` in this repository, do nothing else.
   - **Other repo** — it belongs to another repository: plan it there.
   - **Drop** — stale or superseded. Recommend it when the work since has
     already covered the note, but never drop without his pick.
1. Carry out the outcome he picked:
   - **Act now**: ask any clarification you need, again through
     `AskUserQuestion`, one question at a time. Then act, under the usual rules:
     a non-trivial item gets its todo agreed first, and grows into a plan if it
     turns out bigger than it looked.
   - **Plan it** / **Other repo**: agree the topic name and what the plan must
     settle, through the same tool. Then write `plan/<topic>.md` in the
     repository the note is about: what is wanted and why, what is decided, what
     is open, the proposed steps. It is a forward-looking, committed document,
     so it states the present and carries no progress marks. Do not start on it.
     Ask whether to commit it now; committing needs his yes as always. Respect
     the NDA boundary: a note about client work is planned only in a client
     repository, and client material never goes into a public one.
   - **Drop**: nothing to do.
1. Only once the outcome is carried out, delete that note from the file, so a
   session that dies midway leaves the rest in place. Delete the file when it is
   empty.
1. Notes he adds while this runs are processed too, after the others.
1. End with one line per note: its first words and what became of it.
