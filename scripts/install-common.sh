# Sourced by install-dotfiles and install-units. Defines only colours and helpers - no
# side effects - so each caller can set up its own logfile and fd 3 first.
#
# _install lives here rather than in either script because it is *the* deployment
# primitive this repo documents: refuses a symlinked or unreadable source, replaces the
# destination outright, creates missing parents 700. Two copies of that would drift.

if [ -t 3 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; RESET=''
fi

log()      { printf "\n%b\n\n" "${BLUE}${BOLD}==> $*${RESET}"; }
ok()       { printf "%b\n" "${GREEN}✔ $*${RESET}"; }
warn()     { printf "%b\n" "${YELLOW}⚠ $*${RESET}"; }
die()      { printf "%b\n" "${RED}✖ $*${RESET}" >&2; exit 1; }

_install() {
  src="$1"
  dst="$2"

  if [ -z "$src" ] || [ -h "$src" ] || { [ ! -f "$src" ] && [ ! -d "$src" ]; } || [ ! -r "$src" ]; then
    die "source '$src' must be specified and be a regular readable file or directory"
  fi

  if [ -z "$dst" ]; then
    die "destination '$dst' must be specified"
  fi

  if [ -e "$dst" -a ! -h "$dst" ]; then
    warn "destination '$dst' will be replaced"
  fi

  dstdir=$(dirname "$dst")
  if [ ! -d "$dstdir" ]; then
    warn "creating diretory '$dstdir'"
    $RUN mkdir -p "$dstdir"
    $RUN chmod -R 700 "$dstdir"
  fi

  $RUN rm -rf "$dst"
  $RUN ln -s $(realpath $src) "$dst"

  ok "installed: $dst"

}
