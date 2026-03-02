log "Setting timezone to Europe/Rome..."

$SUDO ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
echo "$TZ" | $SUDO tee /etc/timezone > /dev/null

log "Installing tzdata to configure timezone without prompts..."

$SUDO apt-get install -y --no-install-recommends tzdata
$SUDO dpkg-reconfigure -f noninteractive tzdata
