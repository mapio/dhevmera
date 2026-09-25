# claude

`instructions.md` is the payload: it is linked to `~/.claude/CLAUDE.md`, and
says so itself at the top, along with what not to do to that link.

It is deliberately not named `CLAUDE.md` here: Claude Code would then load it a
second time, as this directory's own project instructions, whenever anything
under `dotfiles/claude/` were edited.

This file is not linked anywhere. It exists to say why the payload is shaped as
it is.

## Where the rules came from

Assembled on 2026-09-22 from provisions that had accumulated project by project
across svm and parsifal — seven repository `CLAUDE.md` files and roughly sixty
`.claude/memory/` notes. A rule earned promotion by having been stated or
corrected independently in three or more projects; anything genuinely specific
to one project stayed there. Most of the factual detail — remotes, namespaces,
host roles, paths — was verified against the machines rather than recalled.

## Editing the payload

- It is loaded into every session on every project, so its length is a recurring
  cost: about 4.3k tokens as of 2026-09-22. Prefer rewriting a rule to adding
  one, and push anything project-specific back down into that project.
- Length costs adherence more than it costs money. Rules the task itself cues —
  GPG on a commit, `uv` on Python, the plan file on a large task — survive a
  long file well. Rules that fire rarely and have no cue survive it badly. Weigh
  an addition by which kind it is, not by how many lines it takes.
- A rule belongs here only if it holds across projects. One project's convention
  belongs in that project's own `CLAUDE.md` or memory.

## Skills

`skills/<name>/` holds the global skills, each linked into `~/.claude/skills/`.
They are the answer to the length problem above: when a rule is really a
procedure, the instructions keep only the fact that cues it ("`/sepolcro`
readies a session to be cleared"), and the steps sit in a skill, whose body
costs tokens only in the sessions that use it.

`/interim-note` and `/interim-act` split taking an idea from acting on it. Told
mid-flow, an idea tends to fork the work to follow it; left untold, it is
forgotten. Both set `disable-model-invocation`, so `/sepolcro` reads
`interim-act`'s file rather than invoking it.

## The greeting, `lazzaro` and `/sepolcro`

The genie line is a canary for the payload not being deployed, but it cannot
tell that apart from the payload being loaded and ignored — which is what
actually happened on 2026-09-25, in a session opened with a restart. That is the
failure the section above predicts: the greeting is a rarely-fired rule, and a
restart prompt cues the work, not the greeting. `lazzaro` makes the prompt
itself the cue. It is kept out of any skill on purpose, because skill names and
descriptions are listed in every session whether or not the payload loaded, and
a listing would answer the question the word exists to ask. The word is not
truly meaningless — Lazarus suggests resuming — so a session without the file
could guess; the greeting, which must name something from the file, is what it
cannot fake.

`/sepolcro` is the other end: it makes a session safe to clear, so that
`lazzaro` has something to resume. It sets `disable-model-invocation`, which
keeps even its description out of context, so it costs nothing in sessions that
never call it.
