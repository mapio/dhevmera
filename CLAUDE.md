# Δημέρα

Config that roams across ephemeral dev boxes. Two entry points: `scripts/install-software`
provisions the machine, `scripts/install-dotfiles` links this repo's files into `$HOME`.

## Deployment is explicit symlinks, not a convention

`scripts/install-dotfiles` is a hand-written bash script. Its one primitive is

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
`git`, `gh`, `glab`, `gnupg`, `misc`, `python`, `qbt`, `shell`, `ssh`, `vscode`). If yes,
it goes in `secrets/config/`. Files that mix the two get split when the tool allows it
(`gh`: `config.yml` public, `hosts.yml` secret) and go wholly into `secrets/` when it does
not (`glab`: one `config.yml` carrying both preferences and tokens).

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
| `/usr/local` | needs sudo, but is **not** APT-packaged anywhere usable | `starship`, `glab`, `rclone`, VS Code CLI, `devcontainer` |
| `$HOME` | user-scoped, or manages its own toolchain and cannot be system-installed | `rustup` → `.cargo`, SDKMAN! → `.sdkman` |

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
  the following `export GPG_TTY`. Check any new fragment for the equivalent flag.
- **`dotfiles/ssh/config` block order is load-bearing.** `Host *` must stay last, and the
  `Match host pico,*.qbt.cluster` direct-reachability probe must precede the `ProxyJump
  parsifal` fallback. Several commits exist purely to move blocks.
- **No `known_hosts` is ever managed** — the config sets `UserKnownHostsFile /dev/null`
  with `StrictHostKeyChecking no`.
- `~/.ssh/agent-link` and `~/.ssh/sockets/` are runtime state created by
  `refresh-agent-link.sh` (invoked as a `Match exec` predicate). Never commit them. The
  sockets live under `~/.ssh` rather than `/tmp` because `/tmp` is not writable on Termux.
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
- `~/.config/qbt/ca-bundle.crt` is **generated**, not linked: glab's `ca_cert` replaces the
  system trust pool instead of extending it, so the bundle must be the public roots plus
  `dotfiles/qbt/gitlab-qbt-cluster.crt`. Only the 2 KB leaf cert is committed.
- `~/.config/git/ignore` on an old host is dead weight — `gitconfig` sets
  `core.excludesfile`, which overrides the XDG default.
- `dotfiles/git/gitconfig` defines an unused-in-this-repo `gitgpg` clean/smudge filter
  bound to `*.gitgpg` by `gitattributes_global` — an alternative to `secrets/` for
  committing an encrypted file into the main repo.
