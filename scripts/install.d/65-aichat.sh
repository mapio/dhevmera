if command -v aichat >/dev/null 2>&1; then

  log "aichat already installed: $(aichat --version | head -n1)"

else

  # /usr/local like glab: no usable APT package, only static musl tarballs on GitHub.
  # Release assets are named by rust target triple, not by dpkg architecture.

  log "Installing aichat"

  case "$ARCH" in
    amd64) AICHAT_TARGET=x86_64-unknown-linux-musl ;;
    arm64) AICHAT_TARGET=aarch64-unknown-linux-musl ;;
    armhf) AICHAT_TARGET=armv7-unknown-linux-musleabihf ;;
    *)     AICHAT_TARGET= ;;
  esac

  # '|| true' because fragments are sourced under 'set -eo pipefail' and the
  # unauthenticated GitHub API is rate limited per IP: a 403 would abort the whole run
  # instead of reaching the warn below.

  AICHAT_VER=$(curl -fsSL https://api.github.com/repos/sigoden/aichat/releases/latest \
    | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -n1 || true)

  if [ -z "$AICHAT_TARGET" ]; then
    warn "no aichat release for architecture '$ARCH', skipping"
  elif [ -z "$AICHAT_VER" ]; then
    warn "could not determine the latest aichat version, skipping"
  else
    # The tarball is flat, holding just 'aichat'. --no-same-owner because upstream built
    # it as uid 1001, which tar would otherwise restore verbatim.
    curl -#L "https://github.com/sigoden/aichat/releases/download/v${AICHAT_VER}/aichat-v${AICHAT_VER}-${AICHAT_TARGET}.tar.gz" \
      | $SUDO tar zxf - --no-same-owner -C /usr/local/bin aichat
    $SUDO chmod a+rx /usr/local/bin/aichat
    ok "aichat $AICHAT_VER installed"
  fi

fi
