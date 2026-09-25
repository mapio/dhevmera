# ssh, `empower` and the tablet

- **`dotfiles/ssh/config` block order is load-bearing.** `Host *` must stay
  last, and the `Match host pico,*.qbt.cluster` direct-reachability probe must
  precede the `ProxyJump parsifal` fallback. Several commits exist purely to
  move blocks.
- **No `known_hosts` is ever managed** — the config sets
  `UserKnownHostsFile /dev/null` with `StrictHostKeyChecking no`.
- `~/.ssh/agent-link` and `~/.ssh/sockets/` are runtime state created by
  `refresh-agent-link.sh` (invoked as a `Match exec` predicate). Never commit
  them. The sockets live under `~/.ssh` rather than `/tmp` because `/tmp` is not
  writable on Termux. `scripts/empower` puts its own masters there too, one per
  host name.
- **`scripts/empower` runs *from* the tablet, sets up its masters and exits.**
  Per host it presets the gpg passphrase, then leaves a detached `ssh -M -N -f`
  master carrying a forwarded agent; svm additionally gets a reverse tunnel on
  2222 back to the tablet's Termux sshd on 8022, and parsifal a SOCKS proxy on
  1080\. That the tunnel lands on **svm only** is the point: svm is the personal
  machine, while parsifal carries other accounts that could reach a loopback
  port on it. Everywhere else jumps through svm, which is what the `tablet`
  blocks arrange — a `Match exec` probe for a local listener on 2222
  (`ProxyJump none`, i.e. you are on svm) ahead of a `ProxyJump svm` fallback,
  the same shape as the pico blocks. They key on `originalhost`, not `host`:
  `tablet-ts` (the dormant Tailscale route) sets `HostName tablet` earlier in
  the file, and `Match host` matches the substituted name, so it caught that
  alias too. Reaching the tablet needs `empower` to have run once, not to be
  running: the masters outlive it. They do not outlive a tablet reboot or a lost
  connection, and since `empower` is idempotent the remedy for either is to run
  it again — so when the tablet does not answer, ask for a rerun rather than
  treating it as unreachable. Passphrases come from `~/.pp`, host-local and
  deliberately not in this repo.
- **Termux's `sshd` is not started for you**, so a tunnel that listens on svm
  but answers `kex_exchange_identification: Connection closed by remote host`
  means the far end has no sshd, not that the forward is broken.
- **Android forbids reading `/proc/net/tcp`**, so nothing in Termux can map a
  listening port back to a pid — `lsof` returns empty, `fuser` and `netstat` say
  permission denied. `empower` therefore retires an orphaned master by finding
  it with `pgrep -f "^ssh -S $CONTROL_DIR/<host> "` rather than by hunting
  whatever holds the port. The `^` is load-bearing: unanchored, the pattern also
  matches the shell running the script, and `pkill` then kills the caller. Six
  orphaned masters had accumulated on the tablet before this worked, each one a
  run whose `-D 1080` lost the bind and carried on regardless.
- **`ExitOnForwardFailure` does not cover `-D` or `-L`**, whatever the man page
  implies: measured on the tablet, a dynamic forward whose bind fails prints
  `Address already in use`, and ssh exits 0 with the master alive and no forward
  in it — with or without `-f`, and the same for `-L`. It does work for `-R`. So
  `empower` does not trust the flag: it probes for the forward itself, both
  before declaring a master `already up` and after starting one, and a master
  that fails the probe is retired on the next run rather than being left to look
  healthy forever. svm's tunnel is probed as a bound listener on svm rather than
  end to end, so a tablet with no `sshd` does not read as a broken forward. The
  probe alone is not enough, though: it only proves *something* holds the port,
  and an unrelated listener squatting 1080 satisfies it. What settles it is
  ssh's own stderr — `Address already in use` / `cannot listen to port`, which
  it prints and then carries on regardless — so that is what the start path
  greps for, and a master that trips it is retired immediately rather than left
  for the next run to mistake for a healthy one. A master can also outlive its
  connection when the tablet sleeps or changes network: `-O check` still passes,
  since it only asks the local process, and a session through it stalls until
  `ServerAlive` gives up, which is how a rerun used to hang. So a master is only
  called up after a `true` run through it returns within `timeout 10`. Retiring
  such a master frees nothing on svm, though: its FIN never arrives, and with
  `ClientAliveInterval 0` sshd keeps the `-R` listener on 2222 until TCP
  keepalive gives up, about two hours on, refusing the new master's forward in
  the meantime. So on `remote port forwarding failed` `empower` kills the holder
  with `sudo -n fuser -k 2222/tcp` and retries once. The `sudo` is not optional:
  sshd's session processes are non-dumpable, so their `/proc/<pid>/fd` belongs
  to root and an unprivileged `fuser` finds nothing and exits 1.
