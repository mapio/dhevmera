if command -v rustc >/dev/null 2>&1; then

  log "Rust already installed: $(rustc --version)"

else

  log "Downloading and installing Rust"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

fi
