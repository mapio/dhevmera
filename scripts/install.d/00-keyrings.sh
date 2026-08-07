log "Configuring keyrings"

$SUDO install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | $SUDO gpg --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | $SUDO gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
# GitHub ships this key already dearmored, so it goes in as-is (piping it through
# 'gpg --dearmor' like the two above would fail on binary input).
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | $SUDO install -m 0644 /dev/stdin /etc/apt/keyrings/githubcli.gpg
# curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
#   | $SUDO gpg --yes --dearmor -o /etc/apt/keyrings/microsoft.gpg
$SUDO chmod a+r /etc/apt/keyrings/*.gpg

log "Configuring sources"

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
  | $SUDO tee /etc/apt/sources.list.d/nodesource.list > /dev/null
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" \
  | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
  | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
#   | $SUDO tee /etc/apt/sources.list.d/vscode.list > /dev/null
$SUDO chmod a+r /etc/apt/sources.list.d/*.list

# Ubuntu's ESM pocket carries an ancient 'gh' at priority 510, which outranks the
# upstream repo's default 500 - without this pin apt happily keeps serving 2.45.

$SUDO install -d -m 0755 /etc/apt/preferences.d
printf 'Package: gh\nPin: origin cli.github.com\nPin-Priority: 600\n' \
  | $SUDO tee /etc/apt/preferences.d/github-cli > /dev/null
$SUDO chmod a+r /etc/apt/preferences.d/github-cli

log "Keyrings and sources configured, updating package lists..."

$SUDO apt-get update -y
