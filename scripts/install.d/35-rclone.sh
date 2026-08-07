if command -v rclone >/dev/null 2>&1; then

  log "Rclone already installed: $(rclone --version | head -n1)"

else

  # Deliberately not 'curl https://rclone.org/install.sh | sudo bash': that drops an
  # unmanaged binary straight into /usr/bin, where dpkg knows nothing about it and the
  # distro's own rclone package would collide with it. Ubuntu ships 1.60 against
  # upstream's 1.75, so apt is not an option either - which puts rclone in /usr/local.

  log "Downloading and installing Rclone"

  if ! command -v unzip >/dev/null 2>&1; then
    $SUDO apt-get install -y unzip
  fi

  TEMP_DIR=$(mktemp -d)
  curl -#Lo "$TEMP_DIR/rclone.zip" "https://downloads.rclone.org/rclone-current-linux-${ARCH}.zip"
  # The zip nests everything under rclone-vX.Y.Z-linux-<arch>/, so -j flattens it away.
  $SUDO unzip -j -o "$TEMP_DIR/rclone.zip" '*/rclone' -d /usr/local/bin
  $SUDO chmod a+rx /usr/local/bin/rclone
  rm -rf "$TEMP_DIR"

  ok "Rclone installed: $(/usr/local/bin/rclone --version | head -n1)"

fi
