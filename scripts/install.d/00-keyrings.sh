log "Configuring keyrings"

$SUDO install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | $SUDO gpg --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | $SUDO gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
# curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
#   | $SUDO gpg --yes --dearmor -o /etc/apt/keyrings/microsoft.gpg
$SUDO chmod a+r /etc/apt/keyrings/*.gpg

log "Configuring sources"

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
  | $SUDO tee /etc/apt/sources.list.d/nodesource.list > /dev/null
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" \
  | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
#   | $SUDO tee /etc/apt/sources.list.d/vscode.list > /dev/null
$SUDO chmod a+r /etc/apt/sources.list.d/*.list

log "Keyrings and sources configured, updating package lists..."

$SUDO apt-get update -y
