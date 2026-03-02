have_node_ver() {
  command -v node >/dev/null 2>&1 || return 1
  node -p "process.versions.node" 2>/dev/null | tr -d '\r'
}
NODE_VER="$(have_node_ver || true)"

if [ -n "$NODE_VER" ] && [ "$(ver_ge "$NODE_VER" "${NODE_MAJOR}.0.0")" = "1" ]; then

  log "Node already installed: $NODE_VER (>= ${NODE_MAJOR}.0.0)"

else

  log "Installing/upgrading Node (need >= ${NODE_MAJOR}.0.0; have ${NODE_VER:-none})"

  $SUDO apt-get remove -y nodejs npm || true
  $SUDO apt-get install -y nodejs

fi
