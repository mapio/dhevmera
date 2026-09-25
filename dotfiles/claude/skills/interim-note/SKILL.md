---
name: interim-note
description: "Jot down, verbatim, an idea Massimo has mid-flow, in interim-todo.md, without acting on it or letting it change the work in progress. Run by him as /interim-note <text>; /interim-act processes the notes later."
disable-model-invocation: true
---

# interim-note

He has an idea while you are in the middle of something. Telling you risks
forking the work to follow it; not telling you risks losing it. This skill is
the third way: the idea goes on disk and the work carries on untouched.

The note is the text he passed after the command.

## Steps

1. The file is `interim-todo.md` at the repository root
   (`git rev-parse --show-toplevel`), or the working directory outside a
   repository. In a repository, make sure `interim-todo.md` is listed in
   `.git/info/exclude`, as `current-plan.md` is; add it if not.

1. Append one item, in a single write, before doing anything else:

   ```markdown
   - <his text, verbatim>
     (<YYYY-MM-DD HH:MM>, during: <the step or file in flight, a few words>)
   ```

   Verbatim means verbatim: no rewording, no fixing typos, no reformatting. The
   context line is the only thing you add, so that a "this" or "that" in the
   note can still be resolved after the context has moved on. Use a quoted
   heredoc delimiter so nothing in his text is expanded.

1. Reply with one line, `Noted (#<number of items in the file>).`, then resume
   the interrupted step exactly where it stopped.

## Never

- Act on the note, even when it would take seconds.
- Ask about it, comment on it, or say how you would handle it.
- Let it change the work in flight, even when it seems to bear on it. He chose
  to park it; `/interim-act` is where it gets discussed.
