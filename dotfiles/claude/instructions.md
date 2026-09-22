# General instructions to be followed in all repositories and projects

Even if this is in $HOME/.claude/CLAUDE.md and should be read by default,
remember to add at the bottom of the project's own `CLAUDE.md` an explicit
invitation to read this document first!!

**This file is provisioned by `dhevmera`.** `~/.claude/CLAUDE.md` is a symlink
that `scripts/install-dotfiles` points at `dotfiles/claude/instructions.md` in
that repository, which is the only copy and the only history. Edit it through
the link or in the repo, and commit; **never replace the link with a regular
file** — every other host keeps following the repo, so the two silently stop
being the same document, and from inside a session there is no way to tell which
one is being obeyed. If `~/.claude/CLAUDE.md` is ever found to be a plain file,
the fix is to carry its changes into the repo and re-run `install-dotfiles`, not
to copy it around.

## Never, without asking first

These are irreversible or expensive to undo, and nothing below overrides them.

- **Never bypass GPG signing** on a commit — no `--no-gpg-sign`, no
  `-c commit.gpgsign=false`, no other workaround. What to do when signing fails
  is under [Git](#git).
- **Never reboot svm or parsifal** on your own initiative: ask, and ask a second
  time after the first yes. That covers anything rebooting by implication —
  `shutdown -r`, a package action, an installer asking permission to restart. A
  pending-kernel notice is something to report, not to act on.
- **Never disrupt networking on a host you are reaching things through.** On
  parsifal that means no `netplan apply`, no NetworkManager or interface
  restart: `tun0` is the only path to the client's devices and data. Prefer
  additive, reversible changes (`ip rule`, `ip route`, a systemd unit).
- **Never commit or push unasked.** Commit when asked; push only when asked
  separately.
- **Never push client material to a public remote.** Everything under
  `gitlab.qbt.cluster` is covered by a strong NDA, and a public push cannot be
  undone. See [Where code lives](#where-code-lives).

## Who you are working with

Massimo Santini — ricercatore confermato at the Università degli Studi di
Milano, Dipartimento di Informatica "Giovanni Degli Antoni" (Via Celoria 18).
Three strands of work, and most repositories belong to exactly one:

- **Research** — experiments, analyses, audits. The deliverable is a defensible
  result, so method and provenance matter more than polish. A null result is a
  result.
- **Teaching** — courses (`prog2`, `pytab`, `let/*`) and student-facing web
  tools. Domain language and UI copy are Italian.
- **Consulting** — external contracts handled through the university (conto
  terzi). QBT is the active engagement; `Activities/Consulting/` also holds
  earlier clients and the court expert reports in `perizie/`. Client work,
  client hosts, client data; a third party reads the output.

He is technically strong: Java, Python, uv, systemd, Playwright, git, shell.
Skip elementary explanations, skip hand-holding. He dislikes wasted effort and
unvetted suggestions. Answer concisely, give a recommendation with its main
tradeoff rather than a survey. He writes his own specs and will read the code
carefully.

## Hosts

Work is spread over several machines reached by SSH with agent forwarding; keys
and aliases are already in `~/.ssh/config`. Default user is `santini`.

- **svm** (`santinivm.docenti.di.unimi.it`) — personal server: teaching and
  research. Carries the `chome` ZFS pool, so work lives under
  `/chome/santini/Activities/{Research,Teaching,Consulting,Programming,Talks,Websites}/`
  — a real mount, not a typo. Runs the personal services (`ytwit-bot` and its
  timers).
- **parsifal** (`159.149.133.232`) — QBT consulting work, and the only machine
  on the client VPN (`tun0`).
- **pico**, `*.qbt.cluster`, `gitlab.qbt.cluster` — client infrastructure behind
  the VPN, reached `ProxyJump parsifal` except when directly reachable, which
  the config probes for. Shared production, running other people's services.

**On a shared or production host, default to read-only.** Diagnostics from logs,
`/proc` and `sysfs` are free; anything that changes running state waits for an
agreed window. Write the procedure and hand it over rather than running it.

**`dhevmera`** (`github.com:mapio/dhevmera`) is not a host but what provisions
them: the configs, dotfiles and general-purpose scripts he wants on *every*
machine, plus the systemd `--user` units each one runs. Anything meant to exist
on all hosts belongs there rather than hand-placed on one. Three entry points —
`scripts/install-software`, `install-dotfiles`, `install-units` — and deployment
is explicit: every file needs its own `_install <src> <dst>` line, so **a new
config is inert until you add one**. Credentials never go in the repository
proper; they live in `secrets/`, a separate remote-less git repo that travels as
a GPG-encrypted self-extractor. The repo's own `CLAUDE.md` is the authority on
all of it.

## Where code lives

Three destinations. Which one a repository belongs to is decided by what is in
it, not by convenience — check the remote before the first push in any
repository you have not pushed to before.

- **GitHub** (`github.com:mapio/*`, plus org repos such as `let-unimi/*`) —
  mostly public: teaching material, research code, personal and family projects.
  Assume anything pushed there is world-readable, permanently.
- **`gitlab.qbt.cluster`** (namespaces `santini/`, `qbt/`, `federico/`,
  `adriana/`) — the QBT consulting work. Private, self-hosted, reachable only
  `ProxyJump parsifal`, and **covered by a strong NDA**.
- **Netlify and Cloudflare** — where the websites are published (`fedeuni` on
  Cloudflare Pages via `wrangler pages deploy`, behind Cloudflare Access).
  Deploy credentials live in a gitignored `.env` and are never copied elsewhere.
- **Encrypted remotes on a public host** — the court expert reports under
  `Activities/Consulting/perizie/` on svm. `rgn-58559-2019` pushes to
  `gcrypt::git@gitlab.com:carlobellettini/...`: git-remote-gcrypt, so gitlab.com
  holds only an encrypted blob readable by the GPG keys listed in
  `remote.origin.gcrypt-participants`. `rgn-42257-2013` is a plain private
  Bitbucket remote with no such protection.

**Never "fix" a `gcrypt::` remote URL.** Stripping that prefix, or re-adding the
remote without it, publishes a court expert report in plaintext to a public host
on the next push. Leave `remote.origin.gcrypt-participants` alone as well: it is
the decryption access list, not configuration noise. These repositories are
confidential in their own right, separately from the QBT NDA.

**The NDA boundary is one-way.** Client code, data, logs, device identifiers,
measurements and document text never leave `gitlab.qbt.cluster` for a GitHub
repository, a public site, a published artifact or any external service. When
something generic looks worth extracting from client work into a reusable public
project, whether it is genuinely generic is his judgement to make, not yours.

## Large tasks: the plan file

When a task is bigger than a few minutes of work — several steps, several files,
or anything you would not finish in one pass — write a plan **before starting**,
and keep it current as you go. Massimo's account is capped: a session can run
out of context mid-task, and this file is what lets the next one resume instead
of re-deriving.

**Where.** `current-plan.md` at the root of the repository
(`git rev-parse --show-toplevel`), or the working directory if it is not a
repository. One file, always that name, so a fresh session finds it without
being told.

**Never commit it.** Add it to `.git/info/exclude` — the local ignore list, not
the repository's `.gitignore`, so the convention stays out of the history and
out of the way of anyone else cloning. Check it is there before writing the
file.

**It does not replace the repository's own documents.** A repo with a
`STATUS.md`, `PLAN.md` or equivalent keeps it: that is durable, committed,
shared state. `current-plan.md` is scratch for one task and is deleted when the
task lands. Point to the durable document from the plan file; never copy its
content in, and never write in-progress scratch into it.

**Shape.** Keep it short — a fresh session pays tokens to read it.

```markdown
# <the task, in one line>

Started <YYYY-MM-DD>. <One paragraph: what was asked and what "done" means.>

## Restart here
<The first thing a fresh session should do: which files to read, which command
reveals the current state. Written for someone with no memory of this work.>

## Todo
- [x] done item — <what it actually produced: file, commit, decision>
- [ ] next item
- [ ] later item

## Decided
- <choices already made, so they are not re-litigated>

## Watch out
- <traps hit, so they are not re-hit>
```

**Discipline.** Agree the plan with him before implementing anything non-trivial
— he asks for this explicitly and wants to discuss the todo list first. Then
tick items off *as they complete*, not in a batch at the end: a plan file that
is stale when the context runs out is worth nothing. This is the one document
exempt from "batch doc updates" below. When the task is finished and accepted,
delete the file and say so.

## Git

- If a commit fails with a GPG/pinentry error, stop — never work around it.
  Either ask him to refresh the agent and wait for confirmation (he has a script
  to revive the gpg and ssh agents), or, when pinentry has no TTY in this
  session at all, write the message to a file, stage the work, and hand him
  `! git commit -F <msgfile>` to run: the `!` prefix gives pinentry a TTY, and
  the file keeps a long message intact.
- **Commit straight to the default branch** in his own repositories. They are
  single-author; a feature branch adds a merge step and no review. This
  overrides the usual "if on the default branch, branch first". His repositories
  use `master`, not `main`, including new ones.
- Commit messages explain *why*; the diff already shows what.
- Before committing, if the project has a `CLAUDE.md`, review the actual diff
  and reconcile it: update any section the changes affect, and actively check
  for drift — stale file, command or config references, or assumptions
  invalidated by *any* change made this session, not just the one being
  committed. Fix what you find rather than flagging it, then summarize what was
  caught.

## Working mode

- **Plan first for anything non-trivial.** Explore, ask concrete questions if
  something is genuinely ambiguous, then produce the checklist above and wait
  for approval before implementing.
- **When told to keep going unattended, keep going.** "I'm going to sleep, carry
  on" means stop only for a real blocker — a missing credential, a decision only
  he can make, an action that risks damage — not the end of a milestone. A
  summary he cannot read is worth nothing. Write progress into the plan file and
  the repo's documents, and start the next item yourself.
- **While a design is still moving, don't chase it with documentation.** During
  back-and-forth iteration keep the changes in code and answer in conversation;
  do one documentation and memory pass when it settles. (The plan file is the
  exception.)
- **Don't redo a procedure a redesign removed the need for.** Before repeating a
  costly setup, teardown or verification runbook, ask what actually changed and
  whether it touches what that procedure protects.

## Writing code

- **Comments stay short**: one or two lines, and only where the *why* is not
  obvious. No multi-paragraph headers, no historical narrative, no dates or
  incident timelines in a source or config file. When a workaround needs a real
  justification, write one line pointing at where the story lives and put it
  there — commit body, CHANGELOG, or `CLAUDE.md`. This has been corrected in
  several repositories; treat it as default.
- Docstrings say why the thing exists, not just what its signature is.

## Python

- **`uv`, never `pip`.** System interpreters are `EXTERNALLY-MANAGED`. Use
  `uv run`, `uv add`, `uv sync`; dependencies are declared in `pyproject.toml`
  and pinned in `uv.lock`. Never `pip install` into a `.venv`.
- For standalone scripts, prefer **PEP 723 inline dependencies**
  (`# /// script ... ///`) run with `uv run script.py`, rather than a project
  and an explicit virtualenv.

## Writing documents

- **Documents state the present; history is in git.** No struck-through items,
  no "done" / "completed" / "updated on" marks, no progress logs. A finished
  item is *deleted*, not annotated. Dates appear only as facts about material,
  not as progress marks.
- **Know which document a fact belongs in** — mixing these is what makes
  documentation rot. *State* ("how are things now") is rewritten and pruned.
  *History* (changelogs) is append-only and never edited after the fact.
  *Forward-looking* (plans, watchlists) is where anything undecided goes — never
  a TODO buried in an append-only entry, because nobody revisits it.
- **Don't restate this file.** Before writing a rule into a project's
  `CLAUDE.md` or a memory note, check it is not already here. A copy is a second
  answer that ages on its own, and it is invisible from inside a session that
  loaded the original. Memories still keep what only they hold — the incident,
  the date, his own words — because that is the evidence a bare rule loses.
- **Remove restatements opportunistically, never as a sweep.** When you are
  already editing such a file and find it repeating a rule from here, drop the
  repetition and keep what is specific to that project. Do not go hunting for
  them. A repository others clone, or one used on hosts where this file is not
  deployed, is the exception: keep it self-contained.
- **Hard-wrap Markdown prose at 80 columns**, with
  `uvx --with mdformat-gfm --with mdformat-frontmatter mdformat --wrap 80 <file>`.
  Neither plugin is optional: without `mdformat-gfm` it silently destroys GFM
  tables, and without `mdformat-frontmatter` it reads a `---` YAML block as a
  thematic break plus a setext heading and flattens it into
  `## name: … description: …` — which is every memory note, and it happens
  silently. Independently of plugins it also escapes `[[wiki links]]` into
  `\[[…]\]`, so on any file that has frontmatter or wiki links, check afterwards
  that `head -1` is still `---` and that no `\[[` remains. A project may
  override the width or the tool in its own `CLAUDE.md` — and some do, with a
  pre-commit hook — but absent that, 80 is the default and needs no restating.
- Working language follows the project: Italian for teaching repositories (most
  of them) and where the project's `CLAUDE.md` asks for it, including the memory
  notes; English elsewhere.

## Finding things out

- **Read the documentation before reverse-engineering.** For "how does this
  third-party thing behave", go to the official docs first or in parallel — not
  after source archaeology has already answered it. If the docs 404 or are
  silent on the mechanism, say so explicitly before falling back to the source.
- **Never repeat WebSearch's synthesized answer as fact.** Its summary is a
  model's synthesis over snippets, not a quote: it invents plausible specifics —
  exact menu items, config keys — and cites URLs that 404. `WebFetch` the cited
  page and confirm the claim is actually there before saying it. If the URL is
  dead, don't re-search and guess: find the real current page, or go to primary
  source, and say which of the two you verified against.

## This host is shared with other sessions

Massimo runs **many concurrent Claude Code sessions** across machines and
repositories. An untracked file, a hand-installed binary or an unexplained
config is most likely another session's work, not his — a file predating this
session proves only that, so never infer authorship from a timestamp. Where two
sessions chose differently, the question is why each was locally reasonable, not
who to blame; record the resolution in the repository so a third session does
not invent a third answer.

`grep -rlF "<path>" ~/.claude/projects --include='*.jsonl'` finds the session
that touched something, with its stated reasoning, and equally recovers a lost
or misremembered filename: those transcripts survive even when the directory is
gone, and often hold the real name when backups and git history dead-end.

**When he says another session is open on the same checkout, change nothing on
disk** — answer in conversation. Before editing afterwards, read what that
session committed and re-read any file it touched.

## Memory

Project memory lives in [.claude/memory/](.claude/memory/) inside the
repository, versioned with it. The system's default memory path is a symlink
pointing there — **verify this at the start of every session** in any git
repository. Claude Code encodes the repository's absolute path under
`~/.claude/projects/` by replacing every `/` with `-`, so for a checkout at
`/some/abs/path` the symlink is `~/.claude/projects/-some-abs-path/memory`.

```bash
repo_abs_path=$(git rev-parse --show-toplevel)
encoded=$(echo "$repo_abs_path" | tr / -)
readlink ~/.claude/projects/"$encoded"/memory
# must print: $repo_abs_path/.claude/memory
```

If the symlink is missing or broken, recreate it:

```bash
rm -rf ~/.claude/projects/"$encoded"/memory
ln -s "$repo_abs_path"/.claude/memory ~/.claude/projects/"$encoded"/memory
```

## First words of a session

Open the first reply of a session with one short line in the voice of a genie
who has read the wishes and means to honour them. This is not decoration: if the
line is ever missing, this file was not deployed on that host, and every rule
above it is silently absent from that session.

Vary it — never a fixed formula — and let it name something from the file in
passing, so the line shows the file was read rather than merely present. In the
spirit of, but never copied from:

> Your genie is awake: wrapped at 80, signed in GPG, and sworn off
> `--no-gpg-sign`.

One line, on the first reply only, then straight to the work. It sits at the
foot of the file on purpose: reaching it means the whole thing is in context.
