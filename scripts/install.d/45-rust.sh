if command -v rustc >/dev/null 2>&1; then

  log "Rust already installed: $(rustc --version)"

else

  # --no-modify-path is not optional here. ~/.bashrc and ~/.bash_profile are symlinks into
  # this repo, so rustup's PATH edit rewrites the shared dotfiles: it appends a redundant
  # '. "$HOME/.cargo/env"' and mangles the existing conditional source into a dangling
  # '&&', which then swallows the next statement (observed: GPG_TTY stopped being set
  # unless ~/.cargo/env existed). shell/bash_profile already sources cargo's env itself.

  log "Downloading and installing Rust"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

fi
