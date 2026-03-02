if command -v tailscale >/dev/null 2>&1; then

  log "Tailscale already installed: $(tailscale version | head -n1)"

else

  log "Installing Tailscale"
  curl -fsSL https://tailscale.com/install.sh | sh

fi
