if command -v bun >/dev/null 2>&1; then

  log "Bun already installed: $(bun --version)"

else

  # $HOME bucket, like rustup and SDKMAN!: bun is not APT-packaged anywhere usable, it is
  # a single self-updating binary under ~/.bun that manages its own upgrades ('bun
  # upgrade'), so there is nothing for /usr/local to own. shell/bash_profile already puts
  # ~/.bun/bin on PATH, which is also what makes the guard above work on later runs.

  log "Downloading and installing Bun"

  # The installer unzips its release archive; unzip is not in the base image.

  if ! command -v unzip >/dev/null 2>&1; then
    $SUDO apt-get install -y unzip
  fi

  # SHELL=/bin/sh does the job of rust's --no-modify-path (see 45-rust.sh). bun's
  # installer has no such flag: it switches on $(basename "$SHELL") and, for bash,
  # appends its own '# bun' PATH block to the first writable of ~/.bash_profile and
  # ~/.bashrc - both symlinks into this repo, so the edit lands in the shared dotfiles
  # for every host (it did, on the run that prompted this fragment). Only the bash, zsh
  # and fish branches write anything; any other $SHELL just prints the two export lines
  # it would have added, which bash_profile already covers.

  curl -fsSL https://bun.sh/install | SHELL=/bin/sh bash

fi
