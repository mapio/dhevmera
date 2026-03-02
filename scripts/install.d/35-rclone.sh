if command -v rclone >/dev/null 2>&1; then

  log "Rclone already installed: $(rclone --version | head -n1)"
  
else

  log "Downloading and installing Rclone"
  curl https://rclone.org/install.sh | sudo bash

fi
