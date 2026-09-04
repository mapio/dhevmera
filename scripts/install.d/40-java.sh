# Two independent guards, because SDKMAN! and the JDK it manages are installed by separate
# steps and a host can legitimately have the first without the second.

# The guard cannot be 'command -v sdk'. 'sdk' is a shell function that sdkman-init.sh
# defines, so it exists only in an interactive shell that sourced it (shell/bashrc does);
# install-software is a non-interactive script and never does. The check therefore failed
# on every host, so both steps below re-ran on every provisioning run: the installer
# refuses with "You already have SDKMAN installed" and 'sdk install java' re-enters
# sdkman's install path - two wasted round trips, and worse than wasted if another JDK is
# current, since sdkman then asks whether to make this one the default (sdkman_auto_answer
# is false) with nobody there to answer. sdkman-init.sh is the real marker.

if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then

  log "SDKMAN! already installed: $(cat "$HOME/.sdkman/var/version" 2>/dev/null || echo unknown)"

else

  # SDKMAN!'s installer appends its own init snippet to ~/.bashrc, a symlink into this
  # repo (see the vendor-installer gotcha in CLAUDE.md). There is no flag to stop it; it
  # skips the append only when 'sdkman-init.sh' already greps out of the file, which is
  # precisely what shell/bashrc's existing source line provides. Keep that line where it
  # is or every run of this fragment dirties the shared dotfiles for every host.

  log "Downloading and installing SDKMAN!"

  curl -s "https://get.sdkman.io" | bash

fi

if [ -d "$HOME/.sdkman/candidates/java/current" ]; then

  log "Java already installed: $(readlink "$HOME/.sdkman/candidates/java/current" | xargs basename)"

else

  log "Installing Java 25.0.1-tem"

  # In a subshell: sdkman-init.sh exports SDKMAN_DIR and rewrites PATH, and fragments are
  # *sourced* by install-software, so at top level that would leak into every fragment
  # after this one. ZSH_VERSION is cleared because sdkman-init.sh switches on it to pick
  # its completion style, and inheriting a stale value from the caller misleads it.

  (
    export ZSH_VERSION=
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install java 25.0.1-tem
  )

fi
