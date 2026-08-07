if command -v devcontainer >/dev/null 2>&1; then

  log "Devcontainer CLI already installed: $(devcontainer --version 2>/dev/null | head -n1)"

else

  # --prefix is not optional here. A bare 'npm install -g' follows whatever prefix the
  # ambient npm config happens to carry - it was /usr when this first ran, and is
  # ~/.npm-global now - so the same fragment installed to two different places on two
  # runs. Pinning it to /usr/local makes it deterministic and keeps npm out of /usr.

  log "Installing devcontainer CLI"

  $SUDO npm install -g --prefix /usr/local @devcontainers/cli

fi
