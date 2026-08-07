GH_INSTALLED=$(dpkg-query -W -f='${Version}' gh 2>/dev/null || true)
GH_CANDIDATE=$(apt-cache policy gh 2>/dev/null | awk '/Candidate:/ { print $2 }')

# Not just 'command -v gh': Ubuntu universe/ESM ships gh 2.45 and a plain presence check
# would leave that in place forever. 00-keyrings.sh pins cli.github.com above ESM, so
# comparing against the candidate is what actually pulls us onto the upstream build.

if [ -n "$GH_INSTALLED" ] && [ "$GH_INSTALLED" = "$GH_CANDIDATE" ]; then

  log "GitHub CLI already installed: $(gh --version | head -n1)"

else

  log "Installing GitHub CLI ${GH_CANDIDATE:-(candidate unknown)}"
  $SUDO apt-get install -y gh

fi
