HERDR=/usr/local/bin/herdr

# /usr/local like glab, but through upstream's install.sh, which checks each binary against
# the release manifest's SHA-256. It installs wherever HERDR_INSTALL_DIR says, so it runs
# unprivileged into a scratch dir and only the final copy needs sudo. The path is tested,
# not PATH, because a hand-installed ~/.local/bin/herdr would shadow it.

HERDR_INSTALLED=$({ [ -x "$HERDR" ] && "$HERDR" --version 2>/dev/null | awk '{ print $2 }'; } || true)
HERDR_LATEST=$(curl -fsSL https://herdr.dev/latest.json \
  | sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' | head -n1 || true)

if [ -z "$HERDR_LATEST" ]; then

  warn "could not determine the latest herdr version, skipping"

elif [ -n "$HERDR_INSTALLED" ] && [ "$(ver_ge "$HERDR_INSTALLED" "$HERDR_LATEST")" = 1 ]; then

  log "herdr already installed: $HERDR_INSTALLED"

else

  log "Installing herdr $HERDR_LATEST"

  HERDR_TMP=$(mktemp -d)
  if curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR="$HERDR_TMP" sh; then
    $SUDO install -m 755 "$HERDR_TMP/herdr" "$HERDR"
    ok "herdr $("$HERDR" --version | awk '{ print $2 }') installed"
    # A running herdr server keeps its old binary; clients and server should match.
    [ -z "$HERDR_INSTALLED" ] || warn "restart herdr, or use its live handoff, to run $HERDR_LATEST"
  else
    warn "herdr's install.sh failed, skipping"
  fi
  rm -rf "$HERDR_TMP"

fi
