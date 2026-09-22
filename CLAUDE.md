# Δημέρα

Config that roams across ephemeral dev boxes. Three entry points: `scripts/install-software`
provisions the machine, `scripts/install-dotfiles` links this repo's files into `$HOME`, and
`scripts/install-units` links the systemd `--user` units this particular host should run.
The first two are host-agnostic; the third is not, which is the whole reason it is separate.

## Deployment is explicit symlinks, not a convention

`scripts/install-dotfiles` is a hand-written bash script. Its one primitive — shared with
`install-units` via `scripts/install-common.sh`, so the semantics below cannot drift between
them — is

```bash
_install <src> <dst>    # rm -rf "$dst" && ln -s "$(realpath src)" "$dst"
```

There is **no** `dotfiles/X` → `$HOME/.X` auto-rule. Every file has its own `_install`
line, so **a new config is inert until you add one** — that is the single most common
mistake when extending this repo. Consequences worth knowing:

- Destinations are `rm -rf`'d with no backup. Symlinks are absolute.
- Missing parent dirs are created `chmod 700`.
- `_install` refuses a source that is itself a symlink, or is unreadable/nonexistent.
- Repo filenames drop the leading dot and may be renamed at the destination
  (`misc/hatch.toml` → `~/.config/hatch/config.toml`, `config/googleauth.json` →
  `~/.secrets.json`).
- `--dry-run` as the first argument sets `RUN=echo`. The next argument is the secrets
  root, defaulting to `/chome/santini/dhevmera` — the ZFS mount (`scripts/mount-zfs`,
  pool `chome`), not `$HOME`. On a normal host pass `"$HOME/dhevmera"`.
- Sentinel: `~/.install-dotfiles.complete`; log: `~/.install-dotfiles.log`.

A handful of steps cannot be a symlink and sit at the end of the script as plain shell —
currently the QBT CA bundle (below). Keep those separated by their own `log` line.

## Public vs secret is the routing rule

**Does the file contain a credential?** If no, it goes in `dotfiles/<topic>/` (topics:
`aichat`, `git`, `gh`, `glab`, `gnupg`, `misc`, `python`, `qbt`, `shell`, `ssh`, `systemd`,
`vscode`). If yes, it goes in `secrets/config/`. Files that mix the two get split when the
tool allows it (`gh`: `config.yml` public, `hosts.yml` secret) and go wholly into `secrets/`
when it does not (`glab`: one `config.yml` carrying both preferences and tokens).

`secrets/` is a **separate git repo**, gitignored by the parent, with **no remote**. It
travels as an encrypted self-extractor:

```text
pack-secrets      # tar | gpg --symmetric AES256/OCB  ->  scripts/unpack-secrets
publish-secrets   # rclone copy that script to od:Archive/Items/
fetch-secrets     # the inverse: rclone copy it back down onto a new host
unpack-secrets    # prompts for the passphrase, extracts, chmod -R 700
```

`pack-secrets` and `fetch-secrets` both **refuse to overwrite** an existing
`scripts/unpack-secrets` — delete it first. That is deliberate on the fetch side too: it
stops a local pack you have not published yet from being replaced by the older copy on the
remote. `unpack-secrets` likewise refuses when `secrets/` already exists, so refreshing an
existing host means moving the old directory aside first, not just re-running it.

`scripts/unpack-secrets` is generated and gitignored. After changing anything under
`secrets/`, commit there, then re-pack and re-publish, or new hosts get the old snapshot.

**Check `git -C secrets status` on every host before packing, not just on the one you are
publishing from.** `pack-secrets` tars the whole directory *including its `.git`*, so an
unpack replaces the receiving host's secrets history wholesale — anything that host held
and the snapshot does not is gone, uncommitted or not. The snapshot is only authoritative
if it is a superset, and that is not automatic: on 2026-09-22 parsifal had
`OPENROUTER_API_KEY` while svm had an uncommitted `[gd-carlotta]` rclone remote, so neither
host could publish without destroying something. Reconcile onto one host first, then pack
from it. Where the same key differs on both — an `[od]` token each host refreshed for
itself — the later `expiry` in the token JSON is the one to keep.

Env-var secrets live in `secrets/config/bash_secrets`, sourced by `shell/bash_profile`.

## Software fragments

`install-software` **sources** `scripts/install.d/*.sh` in numeric order, so fragments
inherit and must not clobber: `$SUDO`, `log/ok/warn/die`, `ver_ge`, `$ARCH`
(`dpkg --print-architecture`), `$VERSION_CODENAME`, `$NODE_MAJOR`, `$DOCKER_MAJOR`. They
run with `set -eo pipefail` from the process that sourced them, and each guards itself for
idempotence — usually `command -v X >/dev/null 2>&1`, but see `48-gh.sh` for the variant
needed when a distro package must be *upgraded* rather than merely detected.

APT keyrings, sources and pins are centralised in `00-keyrings.sh`, which ends with
`apt-get update`; the matching install goes in its own numbered fragment. Note
`install-software` uses the relative path `./scripts/install.d/`, so **run it from the
repo root**.

Bootstrap chain: `deploy-server` → `hcloud server create --user-data cloud/cloud-init.yaml`
→ `cloud-bootstrap` clones the repo and runs `install-software`. It deliberately does
**not** run `install-dotfiles` or `unpack-secrets`; those stay manual.

### Where a tool gets installed

Three buckets. Pick by **how the tool is distributed**, not by preference:

| bucket | rule | examples |
| --- | --- | --- |
| `/usr` | available as an APT package from a public repo that standard tools can add | `tzdata`, `nodejs`, `docker-ce`, `gh`, `tailscale` |
| `/usr/local` | needs sudo, but is **not** APT-packaged anywhere usable | `starship`, `glab`, `rclone`, `aichat`, VS Code CLI, `devcontainer` |
| `$HOME` | user-scoped, or manages its own toolchain and cannot be system-installed | `rustup` → `.cargo`, SDKMAN! → `.sdkman`, `bun` → `.bun` |

The rule that actually matters is the negative one: **nothing that apt does not own may be
written into `/usr`.** A binary dropped into `/usr/bin` is invisible to `dpkg`, and the
distro's own package for it will collide with it later. Two fragments used to do this and
were fixed — `35-rclone.sh` (upstream `install.sh` hardcodes `/usr/bin`) and
`20-devcontainer.sh` (bare `npm install -g` follows the ambient prefix, which was `/usr`
then and `~/.npm-global` now, so the same script installed to two different places on two
runs). Both now target `/usr/local` explicitly. Do not reintroduce either pattern.

"APT-packaged" means *current enough to use*. Ubuntu ships `rclone` 1.60 against upstream
1.75 and `glab` 1.36 against 1.112, so both fall to `/usr/local` despite technically being
in the archive. `gh` is the counter-example: GitHub runs a real repo, so it belongs in
`/usr` — with a pin, because ESM's ancient build outranks it.

Note `~/.local/bin` sits **earlier on PATH** than `/usr/local/bin` (`~/.profile`,
`shell/bash_profile`), so anything hand-installed there will silently shadow the managed
copy and drift. `install-software` also runs unprivileged (`su - santini -lc`), so
`~/.local/bin` is always *available* as a target — it is rejected on purpose, because these
hosts serve one user but `/usr/local` is the FHS home for locally-installed software. The
accepted costs: sudo is required, and none of this works on Termux.

## Gotchas

- **Vendor installers must never be allowed to edit the shell rc files.** `~/.bashrc` and
  `~/.bash_profile` are symlinks into `dotfiles/shell/`, so any installer that "adds itself
  to your PATH" silently rewrites the *shared* config for every host. `45-rust.sh` passes
  `--no-modify-path` for exactly this reason — without it rustup appended a redundant
  source line and mangled the existing conditional into a dangling `&&`, which swallowed
  the following `export GPG_TTY`. Check any new fragment for the equivalent flag — and when
  there is none, for another way to reach the installer's no-op branch: `60-bun.sh` runs
  bun's installer with `SHELL=/bin/sh`, because it switches on `$(basename "$SHELL")` and
  only its bash/zsh/fish branches write to an rc file.
- **`dotfiles/ssh/config` block order is load-bearing.** `Host *` must stay last, and the
  `Match host pico,*.qbt.cluster` direct-reachability probe must precede the `ProxyJump
  parsifal` fallback. Several commits exist purely to move blocks.
- **No `known_hosts` is ever managed** — the config sets `UserKnownHostsFile /dev/null`
  with `StrictHostKeyChecking no`.
- `~/.ssh/agent-link` and `~/.ssh/sockets/` are runtime state created by
  `refresh-agent-link.sh` (invoked as a `Match exec` predicate). Never commit them. The
  sockets live under `~/.ssh` rather than `/tmp` because `/tmp` is not writable on Termux.
  `scripts/empower` puts its own masters there too, one per host name.
- **`scripts/empower` runs *from* the tablet, and everything it provides dies with it.**
  Per host it presets the gpg passphrase, then holds an `ssh -M -N -f` master carrying a
  forwarded agent; svm additionally gets a reverse tunnel on 2222 back to the tablet's
  Termux sshd on 8022, and parsifal a SOCKS proxy on 1080. That the tunnel lands on **svm
  only** is the point: svm is the personal machine, while parsifal carries other accounts
  that could reach a loopback port on it. Everywhere else jumps through svm, which is what
  the `tablet` blocks arrange — a `Match exec` probe for a local listener on 2222
  (`ProxyJump none`, i.e. you are on svm) ahead of a `ProxyJump svm` fallback, the same
  shape as the pico blocks. They key on `originalhost`, not `host`: `tablet-ts` (the
  dormant Tailscale route) sets `HostName tablet` earlier in the file, and `Match host`
  matches the substituted name, so it caught that alias too. It works only while the master is
  alive, which is deliberate: the tablet is reachable exactly when it has chosen to
  connect. The `-R` carries `ExitOnForwardFailure=yes`, so an orphan holding 2222 on svm
  fails the whole master rather than quietly producing one with no tunnel in it; clear it
  with `ssh svm fuser -k 2222/tcp`. Passphrases come from `~/.pp`, host-local and
  deliberately not in this repo.
- **Termux's `sshd` is not started for you**, so a tunnel that listens on svm but answers
  `kex_exchange_identification: Connection closed by remote host` means the far end has no
  sshd, not that the forward is broken.
- **Do not put `GITHUB_TOKEN` or `GH_TOKEN` in `bash_secrets`.** The existing
  `OLD_GITHUB_TOKEN` is a deliberate rename: an exported `GITHUB_TOKEN` silently overrides
  `gh`'s stored credentials. `gh` and `glab` both authenticate from their own config files
  here, not from the environment.
- **`glab`'s committed config keeps `check_update`, `show_whats_new`,
  `notify_skill_updates` and `telemetry` false.** That file is a symlink into the secrets
  repo, and each of those features writes a timestamp or version back into it on use,
  leaving the tree permanently dirty. Version bumps come from `50-glab.sh`.
- **`glab` refuses to start unless its config files are mode 600**, and it says so about
  the path in `~/.config/glab-cli/`. Because those are symlinks, the mode that matters is
  the one on the file *in this repo*. **git records only the executable bit**, so chmodding
  the file locally does not travel — a fresh clone lands 644 and glab breaks on that host.
  `install-dotfiles` therefore chmods `dotfiles/glab/aliases.yml` to 600 explicitly; the
  change is invisible to git, so it never dirties the tree. `secrets/config/glab-config.yml`
  needs no such handling: `unpack-secrets` already does `chmod -R 700`.
- **`glab`'s `ca_cert` is an absolute `/home/santini/...` path** — glab does no `~`
  expansion, so it breaks on Termux, where `$HOME` differs. Known, unfixed.
- Only `gitlab.qbt.cluster` is authenticated; the `gitlab.com` host entry has always had an
  empty token, so `glab auth status` exits non-zero with a 401 for it. Expected, not a
  regression.
- **Unit files spell paths out fully resolved, never through a symlink** — `readlink -f` the
  target and paste *that*. There are three layers of convenience link on the pool host and
  the units used to go through all of them: `~/x` is made by `mount-zfs`, so it does not
  exist until that has run; `/chome/santini/x/` is then a directory of shortcut symlinks
  (`qbt` → `../Activities/Consulting/qbt`, `dhevmera` → `../Activities/Programming/dhevmera`,
  and a dozen more); and `/chome/santini/dhevmera` is itself a symlink into `Activities/`.
  So `parsifal-sync.service` now names
  `/chome/santini/Activities/Consulting/qbt/repos/parsifal-sync/sync.py` and
  `backup-cloud.service` names `/chome/santini/Activities/Programming/dhevmera/scripts/…`,
  matching `ytwit-bot.service`, which was already canonical. The links under `x/` do live on
  the pool, so they resolve whenever a unit could run at all — the point is not availability
  but that `x/` is a personal shortcut layout, free to be reshuffled, while the `Activities/`
  paths are the real ones. Note this makes the secrets-root default `/chome/santini/dhevmera`
  a symlink too; it works, it is simply not what a unit should name. For a related reason
  `install-dotfiles` and `install-units` resolve their roots with `pwd -P`: `_install` links
  `realpath` of the source, and a logical root would not match it if the repo were reached
  through a symlink — which would silently defeat the prune's prefix test.
- **`aichat` is configured for OpenRouter's free tier, and its key is an env var.**
  `dotfiles/aichat/config.yaml` is public because the client it declares carries no
  `api_key`: aichat falls back to `<client name>_API_KEY`, so the credential is
  `OPENROUTER_API_KEY` in `bash_secrets` — the split that the routing rule above asks for.
  An openai-compatible client treats `api_key` as *optional*, so a host that never filled
  that slot gets no missing-key diagnostic: aichat simply sends no `Authorization` header
  and OpenRouter answers 401 `No cookie auth credentials found`. That is the message.
  A client's own `models:` list **replaces** the one aichat ships for that provider, and
  aichat's built-in openrouter list is entirely paid models, so enumerating only `:free`
  ids is what keeps `.model` — and anything picked from it — free. Unlisted models still
  work when named in full (`aichat -m openrouter:vendor/model:free`), just without context
  or pricing metadata. The roster churns every few weeks; regenerate it from
  `https://openrouter.ai/api/v1/models`, keeping ids that end in `:free`.
- **Being listed as free is not the same as being usable**, which is why the 16 listed are
  not the 21 the API returns. `thinkingmachines/inkling{,-small}:free` answer 403 `only
  available on agentic harnesses`; `nvidia/nemotron-3.5-content-safety:free` is a
  classifier that replies `User Safety: safe` to anything; the `ling-3.0-flash-{sante,fin}`
  pair is domain-tuned. Free endpoints also share an upstream pool, so a 429 `temporarily
  rate-limited upstream` is routine and means pick another model — Google, Qwen, Z-AI and
  Poolside refused every attempt across an afternoon, while the two NEX and the NVIDIA
  models never did. Of the free ones `nex-agi/nex-n2.5-mini:free` is the pick — three
  command-recall prompts answered correctly in 0.6–4.5s, with no fencing to strip — and
  `nvidia/nemotron-3-super-120b-a12b:free` is behind it. Avoid `openrouter/free`, the
  auto-router: it is reliable but routes at random, and one of three test prompts came back
  `User Safety: safe` from the classifier above.
- **A `:free` id is one endpoint, so a 429 on it has no workaround but waiting.** Dropping
  the suffix is the escape: `qwen/qwen3.8-27b:free` resolves to ModelRun alone, while
  `qwen/qwen3.8-27b` fans out over seventeen providers with failover, at $0.10/M in and
  $1.80/M out. Check with `https://openrouter.ai/api/v1/models/<id>/endpoints`. Do not read
  the 429's own advice too literally: "route to another provider" cannot apply where there
  is only one, and "add your own key" means BYOK — a paid account with a provider
  OpenRouter integrates, billed there, plus 5% to OpenRouter (waived under $25k/month). It
  does not raise a free variant's ceiling, because that ceiling is the free provider's
  shared pool.
- **The `patch` block exists to silence `<think>`.** Nearly every free model is a reasoning
  model, and aichat wraps returned reasoning in `<think>` tags, which on some models ran to
  forty lines before the one-line answer. `reasoning: {exclude: true}` in the request body
  drops it at the source. `aichat --code` is the other half of that: it strips think tags
  and extracts just the code block.
- **The default is paid on purpose.** `deepseek/deepseek-v4-flash` is $0.0886/M in and
  $0.1772/M out, so a syntax question costs a fraction of a cent, and paid ids carry no
  platform request cap at all — `:free` ids are capped at 20 requests/minute and 50/day,
  rising to 1000/day once the account has ever purchased 10 credits, which this one now
  has. `curl -H "Authorization: Bearer $OPENROUTER_API_KEY`
  `https://openrouter.ai/api/v1/key` reports both the counter and `is_free_tier`. No
  DeepSeek model has a free variant; every one of them is paid. It does fence its answers
  in ```bash, which the free NEX models do not — `aichat --code` strips that.
- **It is not the cheapest that would do**, which was a deliberate choice rather than an
  oversight: 27 paid text models undercut it, and on the same three recall prompts the paid
  `nex-agi/nex-n2.5-mini` ($0.063/M blended against $0.133) answered all three correctly,
  two to five times faster, without fencing. The gap is under a cent a month at any
  plausible usage, so it was settled on headroom for harder questions, not on price. Two
  results worth keeping if this is ever revisited: `mistralai/mistral-nemo`, the cheapest
  of all, invented a `jq` merge that does not work, and `qwen/qwen3.7-flash` is correct but
  takes 20–30 seconds a question.
- `~/.config/qbt/ca-bundle.crt` is **generated**, not linked: glab's `ca_cert` replaces the
  system trust pool instead of extending it, so the bundle must be the public roots plus
  `dotfiles/qbt/gitlab-qbt-cluster.crt`. Only the 2 KB leaf cert is committed.
- `~/.config/git/ignore` on an old host is dead weight — `gitconfig` sets
  `core.excludesfile`, which overrides the XDG default.
- `dotfiles/git/gitconfig` defines an unused-in-this-repo `gitgpg` clean/smudge filter
  bound to `*.gitgpg` by `gitattributes_global` — an alternative to `secrets/` for
  committing an encrypted file into the main repo.
- **systemd units are per-host, and `install-dotfiles` does not touch them.** Every other
  config here is wanted on every host that clones the repo; a service is not, because it
  needs what it runs to exist — `backup-cloud`'s `ExecStart` and `ytwit-bot`'s
  `WorkingDirectory` are both under `/chome`, present on one machine only. So units are
  filed by **tag** in `dotfiles/systemd/<tag>/` and linked by `scripts/install-units`.
  A tag is a *role*, not a hostname: `svm` is an ssh alias and not that box's real
  hostname, and these hosts are ephemeral enough that hostnames are not worth encoding.
  A host declares the tags it carries — possibly several, whose unit sets are unioned — in
  `~/.dhevmera-tags`, one per line; `install-units [--dry-run] [tag...]` overrides that
  from the command line. `~/.dhevmera-tags` is deliberately **not** in this repo: it is the
  one piece of config that cannot roam, being precisely what tells this host from the rest.
  An unknown tag, or one unit name claimed by two tags, is fatal — and checked before
  anything on disk is replaced.
- **`install-units` prunes**, so dropping a unit from the repo or moving it to a tag this
  host does not carry actually removes it from `~/.config/systemd/user/`. Three conditions
  gate every removal, confining it to links the script itself made: the entry is a symlink
  (a regular file there was hand-written and is never touched), its target is inside
  `dotfiles/systemd/`, and its basename is not among the units just installed. The target
  test is a string prefix on the raw link rather than `realpath`, so a unit already deleted
  from the repo — a dangling link, precisely the case worth pruning — is still recognised.
  Pruning does **not** undo a previous `enable`: that leaves its own link under
  `*.target.wants/`, which is systemd's to manage, so the script prints the
  `systemctl --user disable` lines instead of touching them.
- **`install-units` links only; it does not reload or enable anything.** After adding or
  changing a unit, run `systemctl --user daemon-reload` and
  `systemctl --user enable --now <name>.timer` yourself, per host — same spirit as the
  crontab entries, which this repo also never scripts. The script prints the exact commands,
  listing only units that carry an `[Install]` section: `backup-cloud.service` and
  `parsifal-sync.service` have none on purpose, since it is their `.timer` that gets enabled
  and they are pulled in as its target. A `--user` timer only fires on schedule while logged
  in unless lingering is on (`loginctl enable-linger santini`); `backup-cloud.timer`
  (replacing the old `backup-cloud` cron line) and `parsifal-sync.timer` (replacing the old
  `parsifal-sync` cron line) both rely on that being enabled.
- **Never `systemctl --user disable` or `reenable` a unit this repo deploys — use plain
  `enable`.** Everything `install-units` puts in `~/.config/systemd/user/` is a *linked*
  unit (a symlink pointing outside the unit directories, which is why `is-enabled` reports
  `linked` rather than `disabled` for the two oneshots). For a linked unit `disable` removes
  **the symlink itself**, not merely the enablement, so `reenable` deletes the unit and then
  fails to re-enable what is no longer there — leaving it neither linked nor enabled. This
  happened on svm during the move to tags: `ytwit-bot.service`, `backup-cloud.timer` and
  `parsifal-sync.timer` all lost their symlinks in one command. Recovery is `install-units`
  followed by `systemctl --user enable <name>`. Note `disable` does *not* stop a running
  unit, so the damage is silent until the next boot.
- **`enable` writes `*.target.wants/<name>` pointing straight at the file in this repo**, not
  at the copy in `~/.config/systemd/user/`. Those links are systemd's, outside what
  `install-units` manages, so it cannot repair them: **moving a unit between tags, or any
  change to its path in the repo, dangles the `.wants` link and needs a manual
  `systemctl --user enable` afterwards.** `install-units` relinking the unit is not enough —
  it fixes the entry in `~/.config/systemd/user/` while the enablement still points at the
  old path. Check with `find ~/.config/systemd/user -xtype l`, which should print nothing.
