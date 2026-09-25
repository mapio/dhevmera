#!/bin/bash
# Claude Code status line.
#
# Reads the JSON payload Claude Code pipes on stdin and renders a compact,
# single-line status: model, current directory, git branch, context-window
# usage, and plan rate-limit usage (5h / 7d windows).
#
# Rate limits (not $ cost) are shown because this account is on a flat-rate
# plan, where the dollar figure is only an estimated API-equivalent cost.

input=$(cat)

# --- dim ANSI colors (status line renders dimmed in the terminal) ---
reset=$'\033[0m'
c_model=$'\033[2;36m'   # dim cyan
c_dir=$'\033[2;34m'     # dim blue
c_git=$'\033[2;32m'     # dim green
c_ctx=$'\033[2;33m'     # dim yellow
c_rl=$'\033[2;35m'      # dim magenta

# --- Model ---
model=$(printf '%s' "$input" | jq -r '.model.display_name // .model.id // "unknown"')

# --- Current directory (basename only, for compactness) ---
dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
if [ "$dir" = "$HOME" ]; then
  dir_display="~"
elif [ -n "$dir" ]; then
  dir_display=$(basename -- "$dir" 2>/dev/null)
else
  dir_display=""
fi

# --- Git branch (skip optional locks; silent if not a repo) ---
branch=""
if [ -n "$dir" ] && git -C "$dir" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi
fi

# --- Context-window usage: prefer the pre-calculated percentage, else derive
# it from token counts vs. the model's context window size. ---
ctx_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
if [ -z "$ctx_pct" ] || [ "$ctx_pct" = "null" ]; then
  in_tok=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // empty')
  win=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // empty')
  if [ -n "$in_tok" ] && [ -n "$win" ] && [ "$win" != "0" ] && [ "$win" != "null" ]; then
    ctx_pct=$(awk -v a="$in_tok" -v b="$win" 'BEGIN { printf "%.0f", (a / b) * 100 }')
  fi
fi
[ -n "$ctx_pct" ] && [ "$ctx_pct" != "null" ] && ctx_pct=$(awk -v v="$ctx_pct" 'BEGIN { printf "%.0f", v }')

# --- Plan rate-limit usage (5h / 7d rolling windows) ---
rl_5h=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_7d=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_5h_reset=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d_reset=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
[ -n "$rl_5h" ] && [ "$rl_5h" != "null" ] && rl_5h=$(awk -v v="$rl_5h" 'BEGIN { printf "%.0f", v }')
[ -n "$rl_7d" ] && [ "$rl_7d" != "null" ] && rl_7d=$(awk -v v="$rl_7d" 'BEGIN { printf "%.0f", v }')

# Countdown to a Unix-epoch reset time, e.g. "2h13m" / "4d6h" / "13m".
fmt_countdown() {
  local target="$1" now diff days hours mins
  [ -z "$target" ] || [ "$target" = "null" ] && return
  now=$(date +%s)
  diff=$(( target - now ))
  [ "$diff" -le 0 ] && { printf 'now'; return; }
  days=$(( diff / 86400 ))
  hours=$(( (diff % 86400) / 3600 ))
  mins=$(( (diff % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    printf '%dd%dh' "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf '%dh%dm' "$hours" "$mins"
  else
    printf '%dm' "$mins"
  fi
}
rl_5h_cd=$(fmt_countdown "$rl_5h_reset")
rl_7d_cd=$(fmt_countdown "$rl_7d_reset")

# --- Assemble the line ---
line=$(printf '%s[%s]%s' "$c_model" "$model" "$reset")
[ -n "$dir_display" ] && line="$line $(printf '%s%s%s' "$c_dir" "$dir_display" "$reset")"
[ -n "$branch" ] && line="$line $(printf '%s(%s)%s' "$c_git" "$branch" "$reset")"
if [ -n "$ctx_pct" ] && [ "$ctx_pct" != "null" ]; then
  line="$line $(printf '%sctx:%s%%%s' "$c_ctx" "$ctx_pct" "$reset")"
fi
rl=""
if [ -n "$rl_5h" ] && [ "$rl_5h" != "null" ]; then
  rl="5h:${rl_5h}%"
  [ -n "$rl_5h_cd" ] && rl="${rl}(${rl_5h_cd})"
fi
if [ -n "$rl_7d" ] && [ "$rl_7d" != "null" ]; then
  [ -n "$rl" ] && rl="$rl "
  rl="${rl}7d:${rl_7d}%"
  [ -n "$rl_7d_cd" ] && rl="${rl}(${rl_7d_cd})"
fi
[ -n "$rl" ] && line="$line $(printf '%s%s%s' "$c_rl" "$rl" "$reset")"

printf '%s\n' "$line"
