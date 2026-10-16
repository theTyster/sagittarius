#!/usr/bin/env bash
# run-one.sh ALGO[:COUNT] QUERY FILE...
#
# Runs one s(CASP) query exactly as:
#   timeout 30 scasp --unknown=error --forall=ALGO -s COUNT --query=QUERY FILE...
# COUNT defaults to 0 (all answers). Write all_c:1 to ask all_c for one answer.
# Prints one summary line:
#   LABEL ;; QUERY ;; ANSWERS ;; wall SECONDS ;; scasp-internal TIME ;; exit CODE ;; FILES
# Equal answers are merged and counted: "C = c1 (x500)".
# The full output of each run is appended to raw-output.log (first 300 lines).
#
# The --forall=all_c runs go through `heavy` (the machine's CPU queue). The
# wall time is measured inside heavy, so it excludes the queue wait.
# Exit code 124 means the 30 s timeout killed scasp.

label=$1
query=$2
shift 2

algo=$label
count=0
case "$label" in
  *:*)
    count=${label#*:}
    algo=${label%%:*}
    ;;
esac

out=$(mktemp)
tim=$(mktemp)

if [ "$algo" = all_c ]; then
  heavy /usr/bin/time -o "$tim" -f '%e %x' timeout 30 scasp --unknown=error --forall="$algo" -s "$count" --query="$query" "$@" >"$out" 2>&1
else
  /usr/bin/time -o "$tim" -f '%e %x' timeout 30 scasp --unknown=error --forall="$algo" -s "$count" --query="$query" "$@" >"$out" 2>&1
fi

read -r wall rc < <(tail -n 1 "$tim")

answers=$(awk '
  /^% +Answer [0-9]+/      { n++; next }
  /^% Bindings/            { inb = 1; cur = ""; next }
  /^% No bindings/         { inb = 2; next }
  inb == 1 && NF == 0      { ans[++k] = cur; inb = 0; next }
  inb == 1 && /^%/         { ans[++k] = cur; inb = 0; next }
  inb == 1                 { cur = (cur == "" ? $0 : cur ", " $0); next }
  inb == 2                 { if ($0 == "true") ans[++k] = "true (model, no bindings)"; inb = 0; next }
  /No models/              { nomodels = 1 }
  END {
    if (inb == 1) ans[++k] = cur
    if (nomodels && n == 0) { print "no models"; exit }
    if (n == 0)             { print "(no answer printed)"; exit }
    for (i = 1; i <= k; i++) { a = ans[i]; if (!(a in cnt)) order[++m] = a; cnt[a]++ }
    s = ""
    for (j = 1; j <= m; j++) s = s (j > 1 ? " / " : "") order[j] (cnt[order[j]] > 1 ? " (x" cnt[order[j]] ")" : "")
    print n " answer(s): " s
  }' "$out")

internal=$(grep -oE '(Answer [0-9]+ \([0-9.]+ sec\)|No models \([0-9.]+ seconds\))' "$out" | tail -n 1)
if [ -z "$internal" ]; then internal="-"; fi

if [ "$rc" = 124 ]; then answers="TIMEOUT 30 s; partial: $answers"; fi

printf '%s ;; %s ;; %s ;; wall %s s ;; %s ;; exit %s ;; %s\n' "$label" "$query" "$answers" "$wall" "$internal" "$rc" "$*"

blk=$(mktemp)
{
  printf '##### timeout 30 scasp --unknown=error --forall=%s -s %s --query=%s %s\n' "$algo" "$count" "'$query'" "$*"
  head -n 300 "$out"
  printf '##### wall %s s, exit %s\n\n' "$wall" "$rc"
} > "$blk"
# One append per run, so parallel runs do not interleave their blocks.
cat "$blk" >> raw-output.log

rm -f "$out" "$tim" "$blk"
