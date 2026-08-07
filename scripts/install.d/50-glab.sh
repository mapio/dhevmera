if command -v glab >/dev/null 2>&1; then

  log "GitLab CLI already installed: $(glab --version | head -n1)"

else

  # Not from apt: Ubuntu is stuck on glab 1.36 while upstream is past 1.112. Fetching the
  # release tarball into /usr/local/bin follows 15-code.sh and also keeps us ahead of the
  # distro package on PATH, should anything ever pull it in.
  #
  # Project 34675721 is gitlab-org/cli. The version is scraped with sed rather than jq so
  # this fragment works on hosts that never got cloud-init's package list.

  log "Installing GitLab CLI"

  GLAB_VER=$(curl -fsSL https://gitlab.com/api/v4/projects/34675721/releases/permalink/latest \
    | sed -n 's/.*"tag_name":"v\([^"]*\)".*/\1/p' | head -n1)

  if [ -z "$GLAB_VER" ]; then
    warn "could not determine the latest glab version, skipping"
  else
    # The tarball holds bin/glab at its root, so -C /usr/local lands it in /usr/local/bin.
    curl -#L "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VER}/glab_${GLAB_VER}_linux_${ARCH}.tar.gz" \
      | $SUDO tar zxf - -C /usr/local bin/glab
    $SUDO chmod a+rx /usr/local/bin/glab
    ok "GitLab CLI $GLAB_VER installed"
  fi

fi
