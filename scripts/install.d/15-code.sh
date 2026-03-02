if command -v code >/dev/null 2>&1; then

  log "VS Code CLI already installed: $(code --version | head -n1)"

else

  log "Installing VS Code CLI"
  curl -#L "https://code.visualstudio.com/sha/download?os=cli-alpine-x64" | $SUDO tar zxf - -C /usr/local/bin

fi

