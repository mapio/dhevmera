# Δημέρα

Config that roams across ephemeral dev boxes. Four entry points:
`scripts/install-software` provisions the machine, `scripts/install-dotfiles`
links this repo's files into `$HOME`, `scripts/install-host` installs what this
particular host carries by tag (systemd `--user` units, ssh key pairs,
`authorized_keys`), and `scripts/setup-claude` sets up Claude Code where it is
installed. The first two are host-agnostic; the others are not.

## Deployment is explicit symlinks, not a convention

`scripts/install-dotfiles` is a hand-written bash script. Its one primitive —
shared with `install-host` and `setup-claude` via `scripts/install-common.sh`,
so the semantics below cannot drift between them — is

```bash
_install <src> <dst>    # rm -rf "$dst" && ln -s "$(realpath src)" "$dst"
```

There is **no** `dotfiles/X` → `$HOME/.X` auto-rule. Every file has its own
`_install` line, so **a new config is inert until you add one** — that is the
single most common mistake when extending this repo. Consequences worth knowing:

- Destinations are `rm -rf`'d with no backup. Symlinks are absolute.
- Missing parent dirs are created `chmod 700`.
- `_install` refuses a source that is itself a symlink, or is
  unreadable/nonexistent.
- Repo filenames drop the leading dot and may be renamed at the destination
  (`misc/hatch.toml` → `~/.config/hatch/config.toml`, `config/googleauth.json` →
  `~/.secrets.json`).
- `--dry-run` sets `RUN=echo`. The secrets root is `secrets/` in the checkout
  the script runs from, on every host; `unpack-secrets` extracts there too.
- Sentinel: `~/.install-dotfiles.complete`; log: `~/.install-dotfiles.log`.

A handful of steps cannot be a symlink and sit at the end of the script as plain
shell — currently the QBT CA bundle (below). Keep those separated by their own
`log` line.

## Public vs secret is the routing rule

**Does the file contain a credential?** If no, it goes in `dotfiles/<topic>/`
(topics: `aichat`, `claude`, `git`, `gh`, `glab`, `gnupg`, `misc`, `python`,
`qbt`, `shell`, `ssh`, `systemd`, `vscode`). If yes, it goes in
`secrets/config/`. Files that mix the two get split when the tool allows it
(`gh`: `config.yml` public, `hosts.yml` secret) and go wholly into `secrets/`
when it does not (`glab`: one `config.yml` carrying both preferences and
tokens).

`secrets/` is a **separate git repo**, gitignored by the parent, with **no
remote**. It travels as an encrypted self-extractor:

```text
pack-secrets      # tar | gpg --symmetric AES256/OCB  ->  scripts/unpack-secrets
publish-secrets   # rclone copy that script to od:Archive/Items/
fetch-secrets     # the inverse: rclone copy it back down onto a new host
unpack-secrets    # prompts for the passphrase, extracts, chmod -R 700
```

`pack-secrets` and `fetch-secrets` both **refuse to overwrite** an existing
`scripts/unpack-secrets` — delete it first. That is deliberate on the fetch side
too: it stops a local pack you have not published yet from being replaced by the
older copy on the remote. `unpack-secrets` likewise refuses when `secrets/`
already exists, so refreshing an existing host means moving the old directory
aside first, not just re-running it.

`scripts/unpack-secrets` is generated and gitignored. After changing anything
under `secrets/`, commit there, then re-pack and re-publish, or new hosts get
the old snapshot.

**Check `git -C secrets status` on every host before packing, not just on the
one you are publishing from.** `pack-secrets` tars the whole directory
*including its `.git`*, so an unpack replaces the receiving host's secrets
history wholesale — anything that host held and the snapshot does not is gone,
uncommitted or not. The snapshot is only authoritative if it is a superset, and
that is not automatic: on 2026-09-22 parsifal had `OPENROUTER_API_KEY` while svm
had an uncommitted `[gd-carlotta]` rclone remote, so neither host could publish
without destroying something. Reconcile onto one host first, then pack from it.
OAuth `token` lines are not part of that comparison: every host refreshes its
own whenever rclone runs, so they always differ and mean nothing. Ignore them
and let the snapshot's copy win.

Env-var secrets live in `secrets/config/bash_secrets`, sourced by
`shell/bash_profile`.

## The global Claude Code instructions ship from here

`dotfiles/claude/instructions.md` is linked by `scripts/setup-claude` to
`~/.claude/CLAUDE.md`, the file Claude Code loads at the start of every session
in every directory on this host, on top of whatever `CLAUDE.md` the project
provides — including this repo's. It roams for the same reason the shell config
does, and the symlink is what keeps it from being edited in place on one host
and silently stale on the others. `dotfiles/claude/README.md` is not linked and
says where its rules came from and what to weigh before adding another.

Global skills ship the same way: `dotfiles/claude/skills/<name>/` is linked to
`~/.claude/skills/<name>`, which Claude Code loads in every project. Each skill
gets its own `_install` line in `setup-claude`, never the whole directory,
because `~/.claude/skills/` also holds entries this repo does not own
(`synced/`). A skill about one repository stays in that repository's
`.claude/skills/`, as `roam` and `secret-ballet` do here.

`scripts/setup-claude [--dry-run] [--prune]` owns everything under `~/.claude`,
so a host without Claude Code, such as the tablet, gets none of it: the script
exits there before touching anything. It links the instructions, the skills and
the status line script, refusing to replace a `~/.claude/CLAUDE.md` that is a
plain file, runs `herdr integration install claude` where herdr is installed,
registers the MCP servers at user scope through the `claude` CLI — manent with
its full tools on a host tagged `pvm`, `--read-only` over ssh to svm elsewhere;
on `qbt`, QBT's OpenObserve server and its skill, both `qbt-openobserve`, which
live in `~/qbt-repos/observability` under the NDA, so only their paths are named
here — and reports skill links left dangling by a skill removed from the repo.
It removes those only under `--prune`, run by hand: a script that installs into
a directory cannot know what else there is still wanted.
`~/.claude/settings.json` is linked whole from
`dotfiles/claude/settings/<tag>.json`, with no merging, so a host may carry at
most one tag that has one; a plain file that differs from it is left alone.
Claude Code writes into that file itself (`/effort`, `/model`), so its changes
show up here as a dirty tree: review them, then commit or revert. Nothing in it
may name client material, since this repo is public.

## Tags tell one host from another

`install-dotfiles` treats every host alike; `install-host` and `setup-claude` do
not, and what they go by is the host's **tags**. A tag is a *role*, not a
hostname: svm carries `pvm` (personal virtual machine) and parsifal carries
`qbt`, because these hosts are ephemeral enough that their names are not worth
encoding, and a role can move to another host or be shared by two. A host
declares its tags, possibly several, in `~/.dhevmera-tags`, one per line, blank
lines and `#` comments ignored. That file is deliberately **not** in this repo:
it is the one piece of config that cannot roam, being precisely what tells this
host from the rest.

The known tags, with what each one means, are `KNOWN_TAGS` in
`scripts/install-common.sh`; any other is fatal in both scripts, which catches a
typo before anything on disk changes. A tag needs no directory of its own: each
script acts on the tags it has a use for — `install-host` on
`dotfiles/systemd/<tag>/` and `dotfiles/ssh/` where they exist, `setup-claude`
on `pvm` and `qbt` — and ignores the rest. Adding a tag is one entry in that
list plus a line in the host's file.

## SSH keys and authorized_keys go by tag

`install-dotfiles` gives every host one key pair, `id_rsa`: the golden key, the
one that lets Massimo in. Every other pair belongs to a tag, with the public
half in `dotfiles/ssh/keys/<tag>/<name>.pub` and the private one flat in
`secrets/ssh/<name>`, and `install-host` links them, refusing to replace a
hand-placed file that holds a different key. `id_ed25519_qbt_sync` is `pvm`'s:
svm's `parsifal-sync.timer` reaches the `parsifal-sync` alias with it, which
forces `qbt-sync-wrapper.sh` on parsifal, and it has no passphrase because an
unattended run cannot answer one. `id_examui` and `id_manent` are `aep`'s, each
forced on svm into a single service. A link into `dotfiles/ssh/` or
`secrets/ssh/` that no tag claims is reported, and removed only under `--prune`.

`~/.ssh/authorized_keys` is **generated**, not linked, since sshd's
`StrictModes` would then vet every directory up to a file in the repo: the
golden key first, then `dotfiles/ssh/authorized_keys/<tag>` for each tag. Some
hosts are key-only, so a bad file is a lockout, and the script is built around
not writing one:

- the golden key cannot be dropped by a tag, and is checked against `GOLDEN_FP`
  in the script, so rotating `id_rsa` means editing both;
- every line must parse, with no duplicates — `ssh-keygen -lf` silently skips a
  line it cannot read, so the script compares counts;
- sshd must read `~/.ssh/authorized_keys`, found through `sudo -n sshd -T`, or
  from the config files where there is no sudo (the tablet); the `StrictModes`
  modes are fixed;
- a file the script did not generate is replaced only under `--adopt`, after the
  diff;
- the golden key, from an agent, must log in over loopback *before* the change,
  or nothing is written; the swap is an atomic `mv` with a timestamped backup;
- after the swap the same login is repeated, and a failure puts the backup back
  at once;
- a job — a transient `systemd-run --user` timer, or `setsid nohup` on Termux —
  restores the backup ten minutes on, unless `install-host --confirm` has
  arrived through a new ssh connection from another host. That connection
  working is the proof.

Only a new login makes sshd read the file, so every test bypasses
`~/.ssh/config` and any master connection. The loopback login cannot see a
`Match Address` or `AllowUsers user@from` rule; the confirmation from outside is
what covers it.

## Software fragments

`install-software` **sources** `scripts/install.d/*.sh` in numeric order, so
fragments inherit and must not clobber: `$SUDO`, `log/ok/warn/die`, `ver_ge`,
`$ARCH` (`dpkg --print-architecture`), `$VERSION_CODENAME`, `$NODE_MAJOR`,
`$DOCKER_MAJOR`. They run with `set -eo pipefail` from the process that sourced
them, and each guards itself for idempotence — usually
`command -v X >/dev/null 2>&1`, but see `48-gh.sh` for the variant needed when a
distro package must be *upgraded* rather than merely detected.

APT keyrings, sources and pins are centralised in `00-keyrings.sh`, which ends
with `apt-get update`; the matching install goes in its own numbered fragment.
Note `install-software` uses the relative path `./scripts/install.d/`, so **run
it from the repo root**.

`/chome` is *cloud home*: on the ephemeral hosts it is an encrypted external
volume, attached after the base image boots and mounted by `scripts/mount-zfs`
(`zpool import` plus a `zfs load-key`), which is why `zfsutils-linux` is in
`cloud-init.yaml`. svm keeps the same paths without any of that — no pool, no
mount, `/chome` is an ordinary directory on its root filesystem — so nothing
there needs unlocking after a reboot.

Bootstrap chain: `deploy-server` →
`hcloud server create --user-data cloud/cloud-init.yaml` → `cloud-bootstrap`
clones the repo and runs `install-software`. It deliberately does **not** run
`install-dotfiles` or `unpack-secrets`; those stay manual.

### Where a tool gets installed

Three buckets. Pick by **how the tool is distributed**, not by preference:

| bucket       | rule                                                                       | examples                                                                     |
| ------------ | -------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `/usr`       | available as an APT package from a public repo that standard tools can add | `tzdata`, `nodejs`, `docker-ce`, `gh`, `tailscale`                           |
| `/usr/local` | needs sudo, but is **not** APT-packaged anywhere usable                    | `starship`, `glab`, `rclone`, `aichat`, `herdr`, VS Code CLI, `devcontainer` |
| `$HOME`      | user-scoped, or manages its own toolchain and cannot be system-installed   | `rustup` → `.cargo`, SDKMAN! → `.sdkman`, `bun` → `.bun`                     |

The rule that actually matters is the negative one: **nothing that apt does not
own may be written into `/usr`.** A binary dropped into `/usr/bin` is invisible
to `dpkg`, and the distro's own package for it will collide with it later. Two
fragments used to do this and were fixed — `35-rclone.sh` (upstream `install.sh`
hardcodes `/usr/bin`) and `20-devcontainer.sh` (bare `npm install -g` follows
the ambient prefix, which was `/usr` then and `~/.npm-global` now, so the same
script installed to two different places on two runs). Both now target
`/usr/local` explicitly. Do not reintroduce either pattern.

"APT-packaged" means *current enough to use*. Ubuntu ships `rclone` 1.60 against
upstream 1.75 and `glab` 1.36 against 1.112, so both fall to `/usr/local`
despite technically being in the archive. `gh` is the counter-example: GitHub
runs a real repo, so it belongs in `/usr` — with a pin, because ESM's ancient
build outranks it.

Note `~/.local/bin` sits **earlier on PATH** than `/usr/local/bin`
(`~/.profile`, `shell/bash_profile`), so anything hand-installed there will
silently shadow the managed copy and drift. `install-software` also runs
unprivileged (`su - santini -lc`), so `~/.local/bin` is always *available* as a
target — it is rejected on purpose, because these hosts serve one user but
`/usr/local` is the FHS home for locally-installed software. The accepted costs:
sudo is required, and none of this works on Termux.

## Gotchas

- **Vendor installers must never be allowed to edit the shell rc files.**
  `~/.bashrc` and `~/.bash_profile` are symlinks into `dotfiles/shell/`, so any
  installer that "adds itself to your PATH" silently rewrites the *shared*
  config for every host. `45-rust.sh` passes `--no-modify-path` for exactly this
  reason — without it rustup appended a redundant source line and mangled the
  existing conditional into a dangling `&&`, which swallowed the following
  `export GPG_TTY`. Check any new fragment for the equivalent flag — and when
  there is none, for another way to reach the installer's no-op branch:
  `60-bun.sh` runs bun's installer with `SHELL=/bin/sh`, because it switches on
  `$(basename "$SHELL")` and only its bash/zsh/fish branches write to an rc
  file.
- **`scripts/update-system` guards the VS Code CLI on `/usr/local/bin/code`, not
  on `code` being on PATH.** Both svm and parsifal have a `code`, but they are
  different things: svm's is the standalone CLI hand-installed into `/usr/local`
  by `15-code.sh`, which apt cannot update and this script therefore does;
  parsifal's is `/usr/bin/code` → `/usr/share/code/`, the full editor, which the
  CLI tarball would overwrite. The path test says the thing that actually
  matters — *hand-installed under `/usr/local`* — and needs no hostname. It also
  stops and restarts `code-tunnel.service` around the swap, but only where that
  unit is active. On Termux the script runs `pkg upgrade` and never reaches
  either. `--all` updates svm and parsifal too, by piping the script to them
  over ssh rather than invoking their own clone — so one version runs everywhere
  and nothing has to know that svm keeps its copy under `/chome`. It is never
  forwarded, or the remotes would hand it straight back. Run it from the tablet,
  as with `empower`.
- **Do not put `GITHUB_TOKEN` or `GH_TOKEN` in `bash_secrets`.** The existing
  `OLD_GITHUB_TOKEN` is a deliberate rename: an exported `GITHUB_TOKEN` silently
  overrides `gh`'s stored credentials. `gh` and `glab` both authenticate from
  their own config files here, not from the environment.
- **`glab`'s committed config keeps `check_update`, `show_whats_new`,
  `notify_skill_updates` and `telemetry` false.** That file is a symlink into
  the secrets repo, and each of those features writes a timestamp or version
  back into it on use, leaving the tree permanently dirty. Version bumps come
  from `50-glab.sh`.
- **`glab` refuses to start unless its config files are mode 600**, and it says
  so about the path in `~/.config/glab-cli/`. Because those are symlinks, the
  mode that matters is the one on the file *in this repo*. **git records only
  the executable bit**, so chmodding the file locally does not travel — a fresh
  clone lands 644 and glab breaks on that host. `install-dotfiles` therefore
  chmods `dotfiles/glab/aliases.yml` to 600 explicitly; the change is invisible
  to git, so it never dirties the tree. `secrets/config/glab-config.yml` needs
  no such handling: `unpack-secrets` already does `chmod -R 700`.
- **`glab`'s `ca_cert` is an absolute `/home/santini/...` path** — glab does no
  `~` expansion, so it breaks on Termux, where `$HOME` differs. Known, unfixed.
- Only `gitlab.qbt.cluster` is authenticated; the `gitlab.com` host entry has
  always had an empty token, so `glab auth status` exits non-zero with a 401 for
  it. Expected, not a regression.
- **Unit files spell paths out fully resolved, never through a symlink** —
  `readlink -f` the target and paste *that*. There are three layers of
  convenience link on svm and the units used to go through all of them: `~/x` →
  `/chome/santini/x`, which on a cloud host is not there until the volume is
  mounted; `/chome/santini/x/` is then a directory of shortcut symlinks (`qbt` →
  `../Activities/Consulting/qbt`, `dhevmera` →
  `../Activities/Programming/dhevmera`, and a dozen more); and
  `/chome/santini/dhevmera` is itself a symlink into `Activities/`. So
  `parsifal-sync.service` now names
  `/chome/santini/Activities/Consulting/qbt/repos/parsifal-sync/sync.py` and
  `backup-cloud.service` names
  `/chome/santini/Activities/Programming/dhevmera/scripts/…`, matching
  `ytwit-bot.service`, which was already canonical. Those links sit beside the
  `Activities/` tree, so they resolve whenever a unit could run at all — the
  point is not availability but that `x/` is a personal shortcut layout, free to
  be reshuffled, while the `Activities/` paths are the real ones. For a related
  reason the install scripts resolve their roots with `pwd -P`: `_install` links
  `realpath` of the source, and a logical root would not match it if the repo
  were reached through a symlink — which would silently defeat the prune's
  prefix test.
- **herdr lives in `/usr/local/bin`, so it cannot update itself.**
  `herdr update` rewrites its own binary in place, which needs root there;
  `67-herdr.sh` installs it and `update-system` upgrades it, both through
  upstream's `install.sh` run unprivileged into a scratch dir
  (`HERDR_INSTALL_DIR`), which keeps its SHA-256 check and never runs a
  downloaded script as root. A running herdr server keeps its old binary, so an
  upgrade means restarting herdr or using its live handoff. herdr owns its
  Claude hook: `setup-claude`, and `update-system` after an upgrade, run
  `herdr integration install claude`, which writes the hook script at herdr's
  own version and ensures its `SessionStart` entry in `settings.json`, through
  the link. The tag files keep that entry because herdr would write it back
  anyway; with it present the write is a byte-identical no-op, and a diff to it
  after an upgrade is herdr's, to commit rather than edit. The tablet's
  `~/.local/bin/herdr` stays hand-placed: `install.sh` refuses Termux, and
  `install-software` does not run there.
- `~/.config/qbt/ca-bundle.crt` is **generated**, not linked: glab's `ca_cert`
  replaces the system trust pool instead of extending it, so the bundle must be
  the public roots plus `dotfiles/qbt/gitlab-qbt-cluster.crt`. Only the 2 KB
  leaf cert is committed.
- `~/.config/git/ignore` on an old host is dead weight — `gitconfig` sets
  `core.excludesfile`, which overrides the XDG default.
- `dotfiles/git/gitconfig` defines an unused-in-this-repo `gitgpg` clean/smudge
  filter bound to `*.gitgpg` by `gitattributes_global` — an alternative to
  `secrets/` for committing an encrypted file into the main repo.
- **systemd units are per-host, and `install-dotfiles` does not touch them.**
  Every other config here is wanted on every host that clones the repo; a
  service is not, because it needs what it runs to exist — `backup-cloud`'s
  `ExecStart` and `ytwit-bot`'s `WorkingDirectory` are both under `/chome`,
  present on one machine only. So units are filed by
  [tag](#tags-tell-one-host-from-another) in `dotfiles/systemd/<tag>/` and
  linked by `scripts/install-host`. A host carrying several tags gets the union
  of their units; `install-host [--dry-run] [--activate] [tag...]` overrides
  `~/.dhevmera-tags` from the command line. One unit name claimed by two tags is
  fatal — and checked before anything on disk is replaced.
- **`install-host` prunes**, so dropping a unit from the repo or moving it to a
  tag this host does not carry actually removes it from
  `~/.config/systemd/user/`. Three conditions gate every removal, confining it
  to links the script itself made: the entry is a symlink (a regular file there
  was hand-written and is never touched), its target is inside
  `dotfiles/systemd/`, and its basename is not among the units just installed.
  The target test is a string prefix on the raw link rather than `realpath`, so
  a unit already deleted from the repo — a dangling link, precisely the case
  worth pruning — is still recognised. Pruning does **not** undo a previous
  `enable`: that leaves its own link under `*.target.wants/`, which is systemd's
  to manage, so the script prints the `systemctl --user disable` lines instead
  of touching them.
- **`install-host` always reloads; it changes running state only under
  `--activate`.** A linked unit is not a running one, so after linking it runs
  `systemctl --user daemon-reload`, which starts, stops and restarts nothing,
  and then compares what systemd runs with the repo: a unit not enabled, a
  `.wants` link missing or pointing elsewhere, an enabled unit not active, a
  service still running an older definition. Each mismatch is printed with its
  command; `--activate` runs them — plain `enable`, `start`, `restart`, never
  `disable` or `reenable`. Two things are left alone. A timer needs no action:
  the reload alone reschedules it (measured), and the oneshot it pulls in uses
  the new definition on its next run. And if a unit the script does not own is
  loaded with a pending edit, it does not reload at all, since that would apply
  someone else's change. After the reload systemd no longer says which running
  services are stale, so the script notes them first in
  `~/.install-host.restart` and drops each once it has restarted; unit-file
  mtimes would not do, being newer than the start on any fresh checkout. Only
  unit files are compared: a code change in what a unit runs is that repo's to
  deploy. Only units with an `[Install]` section are enabled:
  `backup-cloud.service`, `parsifal-sync.service` and `manent-verify.service`
  have none on purpose, since it is their `.timer` that gets enabled and they
  are pulled in as its target. A `--user` timer only fires on schedule while
  logged in unless lingering is on (`loginctl enable-linger santini`), which the
  script warns about and never sets: `backup-cloud.timer`, `parsifal-sync.timer`
  and `manent-verify.timer` all rely on it.
- **Never `systemctl --user disable` or `reenable` a unit this repo deploys —
  use plain `enable`.** Everything `install-host` puts in
  `~/.config/systemd/user/` is a *linked* unit (a symlink pointing outside the
  unit directories, which is why `is-enabled` reports `linked` rather than
  `disabled` for the three oneshots). For a linked unit `disable` removes **the
  symlink itself**, not merely the enablement, so `reenable` deletes the unit
  and then fails to re-enable what is no longer there — leaving it neither
  linked nor enabled. This happened on svm during the move to tags:
  `ytwit-bot.service`, `backup-cloud.timer` and `parsifal-sync.timer` all lost
  their symlinks in one command. Recovery is `install-host --activate`. Note
  `disable` does *not* stop a running unit, so the damage is silent until the
  next boot.
- **`enable` writes `*.target.wants/<name>` pointing straight at the file in
  this repo**, not at the copy in `~/.config/systemd/user/`. So **moving a unit
  between tags, or any change to its path in the repo, dangles the `.wants`
  link**: relinking the unit fixes the entry in `~/.config/systemd/user/` while
  the enablement still points at the old path. `install-host` reports it, and
  `--activate` repairs it with a plain `enable`.
- **The ssh config, `empower` and the tablet** have their own notes in
  [`dotfiles/ssh/README.md`](dotfiles/ssh/README.md), and **aichat's model
  choice** in [`dotfiles/aichat/README.md`](dotfiles/aichat/README.md).
