if command -v starship >/dev/null 2>&1; then

  log "Starship already installed: $(starship --version | head -n1)"

else

  log "Installing Starship prompt"
  TEMP_FILE=$(mktemp)
  curl -#Lo "$TEMP_FILE" https://starship.rs/install.sh
  chmod +x "$TEMP_FILE"
  $SUDO "$TEMP_FILE" --yes
  rm -f "$TEMP_FILE"

fi
