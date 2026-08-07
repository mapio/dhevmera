if command -v netlify >/dev/null 2>&1; then

  log "Netlify CLI already installed: $(netlify --version 2>/dev/null | head -n1)"

else

  # --prefix for the same reason as 20-devcontainer.sh: a bare 'npm install -g' follows the
  # ambient prefix and would drop an npm-managed tree into /usr, which dpkg does not own.
  #
  # Nothing of netlify's is roamed. ~/.config/netlify/config.json holds only a telemetry
  # flag and a per-install cliId, and auth is per-project: the sites that need it export
  # NETLIFY_AUTH_TOKEN from a direnv-loaded .env, so there is no global credential here.

  log "Installing Netlify CLI"

  $SUDO npm install -g --prefix /usr/local netlify-cli

fi
