if command -v sdk >/dev/null 2>&1; then

  log "SDKMAN! already installed: $(sdk version  | grep script | cut -d: -f2)"

else

  log "Downloading and installing SDKMAN!"
  curl -s "https://get.sdkman.io" | bash
  log "Downloading and installing Java 25"
  export ZSH_VERSION=
  source "$HOME/.sdkman/bin/sdkman-init.sh"

  log "Installing Java 25.0.1-tem"
  sdk install java 25.0.1-tem

fi
