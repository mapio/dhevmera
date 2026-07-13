#!/usr/bin/env bash
# Match-exec predicate for ssh/config: keeps ~/.ssh/agent-link pointed at a live
# forwarded SSH agent socket. Exit 0 (and IdentityAgent applies) when a working
# agent is found; exit 1 to fall through to the default agent otherwise - this is
# what lets the same config work unmodified on machines with their own local
# agent (no /tmp/ssh-*/ forwarded sockets to find).
set -u

mkdir -p -m 700 ~/.ssh/sockets

LINK=~/.ssh/agent-link

if [ -S "$LINK" ] && SSH_AUTH_SOCK="$LINK" ssh-add -l >/dev/null 2>&1; then
  exit 0
fi

for d in $(ls -dt /tmp/ssh-*/ 2>/dev/null); do
  for s in "$d"agent.*; do
    [ -S "$s" ] || continue
    if SSH_AUTH_SOCK="$s" ssh-add -l >/dev/null 2>&1; then
      ln -sf "$s" "$LINK"
      exit 0
    fi
  done
done

exit 1
