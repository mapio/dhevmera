docker_server_ver() {
  command -v docker >/dev/null 2>&1 || return 1
  docker version --format '{{.Server.Version}}' 2>/dev/null | tr -d '\r'
}
DOCKER_VER="$(docker_server_ver || true)"

if [ -n "$DOCKER_VER" ] && [ "$(ver_ge "$DOCKER_VER" "${DOCKER_MAJOR}.0.0")" = "1" ]; then

  log "Docker already installed: $DOCKER_VER (>= ${DOCKER_MAJOR}.0.0)"

else

  log "Installing/upgrading Docker (need >= ${DOCKER_MAJOR}.0.0; have ${DOCKER_VER:-none})"

  $SUDO apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
  $SUDO apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  $SUDO systemctl enable docker
  $SUDO systemctl start docker

fi
