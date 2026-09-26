---
name: sepolcro
description: "Ready this session to be cleared or exited: process the interim notes, bring the plan file up to date, report uncommitted work, stop the background work this session started, save what memory should keep. Run by Massimo before /clear; the next session resumes with lazzaro."
disable-model-invocation: true
---

# sepolcro

After this runs, the context is about to be thrown away. Whatever the next
session needs must by then be on disk, and nothing this session started may be
left running unobserved. Work through the steps in order, then give the verdict.

## 1. Interim notes

If `interim-todo.md` exists at the repository root (or the working directory),
read `~/.claude/skills/interim-act/SKILL.md` and follow it until the file is
gone. It cannot be invoked as a skill from here: it sets
`disable-model-invocation`. It comes first because acting on a note can add to
the plan.

## 2. The plan file

`current-plan.md` at the repository root (or the working directory outside a
repository), shaped as `~/.claude/CLAUDE.md` describes.

- Confirm it and `interim-todo.md` are listed in `.git/info/exclude`; add them
  if not.
- Task unfinished: bring it up to date — tick what landed, and rewrite *Restart
  here* for a reader with no memory of this session: the first file to read, the
  command that shows the current state, the next item. Record decisions under
  *Decided* and traps under *Watch out*. No plan yet: write one.
- Task finished and accepted: say so and offer to delete the file.
- Documentation passes deferred while the design was moving go in the plan as
  open items, not done in a hurry now.

## 3. Repository state

Run `git status`, `git stash list` and `git log @{u}..` in every repository this
session touched (in dhevmera, `secrets/` too). Report uncommitted changes,
stashes and unpushed commits, and ask whether to commit them or record them in
the plan as work in progress. Never commit or push on your own.

## 4. Background work

Stop, or confirm finished, everything **this session** started:

- background Bash shells and Monitors. Do not answer this from memory of the
  completion notifications: a shell that never finishes never sends one. List
  what is still alive under this claude process, then stop each by the task
  id the listing prints (`TaskStop`), and list again until it prints nothing:

  ```bash
  for p in $(pgrep -P $PPID); do [ $p = $$ ] || readlink /proc/$p/fd/1; done | grep -o '[^/]*\.output$'
  ```

  The Bash tool's parent is the claude process and every shell's stdout is its
  `tasks/<id>.output` file, so with this shell skipped and the MCP servers
  filtered out by the grep, every line is one of this session's tasks;
- subagents and workflows still running (`TaskStop`);
- cron jobs (`CronList`, `CronDelete`) and a `/loop` wakeup (`ScheduleWakeup`
  with `stop: true`);
- processes it spawned — dev servers, port forwards, watchers.

Leave alone what it did not start: the `empower` ssh masters, systemd units,
other sessions' processes. When unsure whose something is, report it instead.

## 5. Memory

Save what only this session learned and the next one needs — a correction he
gave, a constraint not recorded in the repository — following the memory rules
in `~/.claude/CLAUDE.md`. Progress belongs in the plan file, not in memory.

## 6. Verdict

End with one line: **safe to `/clear`**, or what still stands in the way and
which decision of his it needs. Never safe while `interim-todo.md` holds a note.
