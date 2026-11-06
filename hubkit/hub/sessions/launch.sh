#!/usr/bin/env bash
# Start or resume one of the hub's long-lived Claude Code sessions, by name.
#
#   launch.sh NAME [--dry-run]
#
# NAME must be a line in sessions/ROLES (one session name per line). The session is found by its
# name in Claude Code's transcript store. Never use --continue: it takes the newest session in the
# cwd, and every role shares the hub root as its cwd.
#
# Optional per role: sessions/<NAME>/prompt.md (appended to the system prompt) and
# sessions/<NAME>/settings.json (passed with --settings). Both are re-passed on every launch,
# because a resume does not restore them.
#
# Exit codes: 0 ok, 2 bad name or usage, 3 the session is already running.
# Needs: bash 4+, jq, claude.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
hub="$(cd "$here/.." && pwd -P)"
mapfile -t ROLES < <(grep -v '^\s*\(#\|$\)' "$here/ROLES")

usage() { local IFS="|"; echo "usage: ${0##*/} {${ROLES[*]}} [--dry-run]" >&2; exit 2; }

name="" dry=0
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) dry=1 ;;
    -h|--help) usage ;;
    -*) echo "${0##*/}: unknown flag: $arg" >&2; usage ;;
    *) [[ -z "$name" ]] || usage; name="$arg" ;;
  esac
done
[[ -n "$name" ]] || usage
valid=0
for r in "${ROLES[@]}"; do [[ "$r" == "$name" ]] && valid=1; done
(( valid )) || { echo "${0##*/}: not a hub session: $name (roles: ${ROLES[*]})" >&2; exit 2; }

# Claude Code keeps one transcript per session at <config>/projects/<cwd with every
# non-alphanumeric byte turned into '-'>/<sessionId>.jsonl. Naming (-n, /rename) appends a
# {"type":"custom-title","customTitle":…,"sessionId":…} record; the last one is the current name.
store="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/$(printf '%s' "$hub" | sed 's/[^A-Za-z0-9]/-/g')"

mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }   # GNU, then BSD/macOS

# Print "<mtime>\t<sessionId>" for each session whose current name is $1, newest first.
sessions_named() {
  local want="$1" f last
  shopt -s nullglob
  for f in "$store"/*.jsonl; do
    last="$(grep -F '"type":"custom-title"' "$f" | tail -n 1)" || true
    [[ -n "$last" ]] || continue
    jq -r --arg want "$want" --arg m "$(mtime "$f")" \
      'select(.customTitle == $want) | "\($m)\t\(.sessionId)"' <<<"$last" 2>/dev/null || true
  done | sort -rn
}

mapfile -t found < <(sessions_named "$name")
if (( ${#found[@]} == 1 )); then
  id="${found[0]#*$'\t'}"; resume=(--resume "$id"); note="resuming $name ($id)"
elif (( ${#found[@]} > 1 )); then
  resume=(--resume "$name"); note="${#found[@]} sessions are named $name; Claude Code will ask which"
else
  resume=(-n "$name"); note="no session named $name yet; creating it"
fi

# Refuse to open a second process on a conversation that is already running.
if [[ "${resume[0]}" == --resume && "${resume[1]}" != "$name" ]]; then
  pid="$(claude agents --json 2>/dev/null \
    | jq -r --arg id "${resume[1]}" '.[] | select(.sessionId == $id and .pid != null) | .pid' 2>/dev/null \
    | head -n 1)" || true
  if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
    if (( dry )); then note="$note; NOTE: already running as pid $pid, a real launch would refuse"
    else echo "${0##*/}: $name is already running (pid $pid)" >&2; exit 3; fi
  fi
fi

args=("${resume[@]}")
[[ -f "$here/$name/prompt.md" ]] && args+=(--append-system-prompt-file "$here/$name/prompt.md")
[[ -f "$here/$name/settings.json" ]] && args+=(--settings "$here/$name/settings.json")

if (( dry )); then
  echo "# $note" >&2
  printf 'cd %q && HUB_SESSION=%q claude' "$hub" "$name"; printf ' %q' "${args[@]}"; printf '\n'
  exit 0
fi
echo "${0##*/}: $note" >&2
cd "$hub"
export HUB_SESSION="$name"     # hubflow reads this as the writer's identity
exec claude "${args[@]}"
