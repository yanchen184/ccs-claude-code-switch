#!/bin/sh
# Claude Code status line — Powerlevel10k inspired
# Shows: account | dir | git branch | ctx% | model | session

input=$(cat)

# Extract fields from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Claude 登入帳號(email) — 依 CLAUDE_CONFIG_DIR 判斷目前是哪個帳號(ccs 多帳號)
cfg_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
case "$cfg_dir" in
  "$HOME/.claude")   acct_tag="1" ; acct_json="$HOME/.claude.json" ;;
  "$HOME/.claude-2") acct_tag="2" ; acct_json="$cfg_dir/.claude.json" ;;
  "$HOME/.claude-3") acct_tag="3" ; acct_json="$cfg_dir/.claude.json" ;;
  *)                 acct_tag="?" ; acct_json="$cfg_dir/.claude.json" ;;
esac
# 主帳號的 .claude.json 可能落在 config dir 內,兩處都試
[ -f "$acct_json" ] || acct_json="$cfg_dir/.claude.json"
[ -f "$acct_json" ] || acct_json="$HOME/.claude.json"

account=$(jq -r '.oauthAccount.emailAddress // empty' "$acct_json" 2>/dev/null)
if [ -n "$account" ]; then
  user_host="[${acct_tag}] ${account}"
else
  user_host="[${acct_tag}] $(whoami)@$(hostname | cut -d. -f1)"
fi

# Shorten home directory to ~
if [ -n "$cwd" ]; then
  short_dir=$(echo "$cwd" | sed "s|$HOME|~|")
else
  short_dir="$(pwd | sed "s|$HOME|~|")"
fi

# Git branch + dirty flag (skip lock to avoid contention)
git_info=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -1)
    if [ -n "$dirty" ]; then
      git_info="  ${branch} *"
    else
      git_info="  ${branch}"
    fi
  fi
fi

# Context window usage
ctx_info=""
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  if [ "$used_int" -ge 80 ]; then
    ctx_info="  ctx:${used_int}%!"
  else
    ctx_info="  ctx:${used_int}%"
  fi
fi

# Model (shorten common names)
model_info=""
if [ -n "$model" ]; then
  short_model=$(echo "$model" | sed \
    -e 's/Claude //' \
    -e 's/ Sonnet/S/' \
    -e 's/ Opus/O/' \
    -e 's/ Haiku/H/')
  model_info="  ${short_model}"
fi

# Session id 短碼 — 前 6 碼,一眼認出目前在哪個 session
sess_info=""
if [ -n "$session_id" ] && [ "$session_id" != "null" ]; then
  sess_info="  sess:$(echo "$session_id" | cut -c1-6)"
fi

# Output with ANSI colors
# Cyan=user@host  Blue=dir  Yellow=git  Cyan=ctx  Gray=model  Magenta=session
printf "\033[0;36m%s\033[0m \033[1;34m%s\033[0m\033[1;33m%s\033[0m\033[0;36m%s\033[0m\033[0;90m%s\033[0m\033[0;35m%s\033[0m" \
  "$user_host" \
  "$short_dir" \
  "$git_info" \
  "$ctx_info" \
  "$model_info" \
  "$sess_info"
