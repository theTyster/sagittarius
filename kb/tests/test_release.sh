#!/usr/bin/env bash
# Release checks (ticket T15, claims c1-c3). Run from anywhere: kb/tests/test_release.sh
# c1  README.md has a "Use it" section: install, start a hub, the hook (optional, manual).
# c2  A fresh install in a scratch HOME works (five links, the System 1 link too); install.py never writes a settings file.
# c3  hubkit/kit.json version is higher than the first one; CHANGELOG.md has the redesign entry.
# c4  (0.3.0) VERSION, the last line of the prompt and a CHANGELOG heading agree; install.py --check prints the version;
#     the installed orbit-kb and a formal hub's copy of it print it (orbit-kb version).
# Exit: 0 all pass, 1 a check failed.  Prints `pass=N fail=N`.
set -u
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
pass=0 fail=0
ok()  { pass=$((pass+1)); echo "PASS $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1: $2"; }
chk() { # name, command...
    local n=$1; shift
    if "$@" >/dev/null 2>&1 </dev/null; then ok "$n"; else bad "$n" "command failed: $*"; fi
}

readme=$repo/README.md
use=$(awk '/^## Use it/{f=1;next} /^## /{f=0} f' "$readme")

# c1
[ -n "$use" ] && ok c1-use-it-section || bad c1-use-it-section "no '## Use it' section in README.md"
printf '%s' "$use" | grep -q 'install\.py' && ok c1-step-install || bad c1-step-install "no install.py in Use it"
printf '%s' "$use" | grep -q 'hubkit/' && printf '%s' "$use" | grep -q 'INSTRUCTIONS\.md' \
    && ok c1-step-hub || bad c1-step-hub "Use it does not start a hub from hubkit/INSTRUCTIONS.md"
printf '%s' "$use" | grep -qi 's1/README\.md' && printf '%s' "$use" | grep -qi 'optional' \
    && ok c1-step-hook-optional || bad c1-step-hook-optional "Use it lacks the optional hook step with s1/README.md"
printf '%s' "$use" | grep -qi 'settings\.json' && printf '%s' "$use" | grep -qi 'paste' \
    && printf '%s' "$use" | grep -qi 'no script\|nothing writes\|never writes\|does not write' \
    && ok c1-hook-manual || bad c1-hook-manual "Use it does not say the hook is a manual paste into settings.json that no script writes"

# c2
scratch=$(mktemp -d "${TMPDIR:-/tmp}/release-test.XXXXXX") || exit 1
trap 'rm -rf "$scratch"' EXIT
export_home() { HOME=$scratch env -u XDG_CONFIG_HOME -u XDG_DATA_HOME "$@"; }
export_home python3 "$repo/install.py" >"$scratch/install.out" 2>&1 </dev/null \
    && ok c2-install-runs || bad c2-install-runs "$(head -c 300 "$scratch/install.out")"
export_home python3 "$repo/install.py" --check >/dev/null 2>&1 </dev/null \
    && ok c2-install-check || bad c2-install-check "install.py --check fails after install"
for l in .local/bin/orbit-kb .local/bin/repo-map .local/share/orbit-kb .claude/sagittarius .claude/sagittarius-s1; do
    [ -L "$scratch/$l" ] && ok "c2-link-$(basename "$l")" || bad "c2-link-$(basename "$l")" "no link at \$HOME/$l"
done
HOME=$scratch PATH="$scratch/.local/bin:$PATH" orbit-kb help </dev/null >"$scratch/help.out" 2>&1 \
    && [ -s "$scratch/help.out" ] && ok c2-orbit-kb-help || bad c2-orbit-kb-help "orbit-kb help from the installed link failed"
HOME=$scratch PATH="$scratch/.local/bin:$PATH" repo-map </dev/null >"$scratch/rm.out" 2>&1
grep -q 'usage: repo-map' "$scratch/rm.out" && ok c2-repo-map-usage || bad c2-repo-map-usage "installed repo-map printed no usage line"
HOME=$scratch PATH="$scratch/.local/bin:$PATH" repo-map --facts "$repo/kb/share/repo-map/example-kb.pl" \
    --containers "$repo/kb/share/repo-map/sagittarius.containers.pl" </dev/null 2>&1 | grep -q '^# Repo map' \
    && ok c2-repo-map-runs || bad c2-repo-map-runs "installed repo-map made no map"
python3 -I "$repo/hubkit/tools/hubkit-test.py" </dev/null >"$scratch/hk.out" 2>&1
tail -1 "$scratch/hk.out" | grep -q ' 0 failed' && ok c2-hubkit-test || bad c2-hubkit-test "$(tail -1 "$scratch/hk.out")"
found=$(find "$scratch" -name 'settings*.json' | head -1)
[ -z "$found" ] && ok c2-no-settings-file || bad c2-no-settings-file "a settings file exists: $found"
grep -qi 'settings' "$repo/install.py" && bad c2-install-no-settings-code "install.py mentions settings" || ok c2-install-no-settings-code

# c3
cat >"$scratch/c3.py" <<'PY'
import json, os, subprocess, sys
# The kit version must tell templates apart and only move up (Ty, 2026-11-12: "a reliable way to
# distinguish versions monotonically"). Against the base (main, or KIT_BASE_REF): never lower, and
# higher whenever the template (hubkit/hub, hubkit/editions), the kit tools, or the files a formal hub
# copies from kb/ (kit.json orbit_kb paths) differ from the base's.
repo = sys.argv[1]
ref = os.environ.get("KIT_BASE_REF") or "main"
def ver(s): return tuple(int(x) for x in s.split("."))
now = json.load(open(repo + "/hubkit/kit.json"))["version"]
def git(*a): return subprocess.run(["git", "-C", repo, *a], capture_output=True, text=True, stdin=subprocess.DEVNULL)
base = None
m = git("show", ref + ":hubkit/kit.json")
if m.returncode == 0:
    base = json.loads(m.stdout)["version"]
else:  # hubkit is not on main: compare with the version it first had
    first = git("log", "--reverse", "--format=%h", "--", "hubkit/kit.json").stdout.split()
    if first:
        base = json.loads(git("show", first[0] + ":hubkit/kit.json").stdout)["version"]
if base is None:
    sys.exit("no earlier version found to compare with: this check needs a git checkout with history (not an archive copy)")
if ver(now) < ver(base):
    sys.exit(f"kit.json version {now} is below {base} ({ref})")
if m.returncode == 0 and ver(now) == ver(base):
    kit = json.load(open(repo + "/hubkit/kit.json"))
    ok_ = kit.get("orbit_kb") or {}
    src = os.path.normpath(os.path.join("hubkit", ok_.get("from", "../kb")))
    copied = [os.path.join(src, p) for p in ok_.get("paths", [])]  # what a formal hub copies from kb/
    d = git("diff", "--quiet", ref, "--", "hubkit/hub", "hubkit/editions", "hubkit/tools/hubkit.py", *copied)
    if d.returncode != 0:
        sys.exit(f"the template differs from {ref}, but kit.json version {now} is not above {base}")
elif m.returncode != 0 and not ver(now) > ver(base):
    sys.exit(f"kit.json version {now} is not above {base}")
PY
python3 "$scratch/c3.py" "$repo" >"$scratch/c3.out" 2>&1 && ok c3-kit-version || bad c3-kit-version "$(cat "$scratch/c3.out")"
# The rule must see every file a hub copies from the kit at one version, the orbit-kb copy included
# (kit.json orbit_kb). A commit that changes only kb/share/orbit-kb/help/core.txt and keeps the kit
# version must fail the rule.
c3m=$scratch/c3-mutant
if git clone -q --no-hardlinks "$repo" "$c3m" 2>/dev/null; then
    printf '\n' >>"$c3m/kb/share/orbit-kb/help/core.txt"
    git -C "$c3m" -c user.name=t -c user.email=t@t commit -qam "c3 mutant: orbit-kb help only" 2>/dev/null
    KIT_BASE_REF=HEAD~1 python3 "$scratch/c3.py" "$c3m" >"$scratch/c3m.out" 2>&1 \
        && bad c3-kit-version-sees-orbit-kb "a change of kb/share at the same kit version passed: $(cat "$scratch/c3m.out")" \
        || ok c3-kit-version-sees-orbit-kb
else
    bad c3-kit-version-sees-orbit-kb "could not clone $repo"
fi
cl=$repo/CHANGELOG.md
[ -f "$cl" ] && ok c3-changelog-file || bad c3-changelog-file "no CHANGELOG.md"
for w in "| MindHole Kit |" philosophy "spec KB" "Jev" "flow ledger" "Lean" "small prompt" panes "question view" "repo map" tempering "status line" "System 1 hook" "Not in this release yet"; do
    grep -qi -- "$w" "$cl" 2>/dev/null && ok "c3-changelog-$w" || bad "c3-changelog-$w" "CHANGELOG.md lacks: $w"
done
grep -q '0\.2\.0' "$cl" 2>/dev/null && ok c3-changelog-version || bad c3-changelog-version "CHANGELOG.md does not name hubkit 0.2.0"

# c4 (0.3.0, V-A): one source for the version
python3 "$repo/docs/check_version.py" >"$scratch/ver.out" 2>&1 && ok c4-version-agrees || bad c4-version-agrees "$(cat "$scratch/ver.out")"
v=$(tr -d '[:space:]' <"$repo/VERSION")
export_home python3 "$repo/install.py" --check 2>&1 </dev/null | grep -q "Sagittarius $v" \
    && ok c4-install-check-prints-version || bad c4-install-check-prints-version "install.py --check does not print Sagittarius $v"
# c4 (0.3.0, c_v_a_2): the installed link and a formal hub's own copy of orbit-kb print the version
HOME=$scratch PATH="$scratch/.local/bin:$PATH" env -u ORBIT_KB_LIB orbit-kb version </dev/null 2>&1 | grep -qx "orbit-kb $v" \
    && ok c4-orbit-kb-link-version || bad c4-orbit-kb-link-version "the installed orbit-kb does not print orbit-kb $v"
python3 "$repo/hubkit/tools/hubkit.py" install --hub "$scratch/hub" --edition formal >/dev/null 2>&1 </dev/null
env -u ORBIT_KB_LIB "$scratch/hub/.claude/orbit-kb/bin/orbit-kb" version </dev/null 2>&1 | grep -qx "orbit-kb $v" \
    && ok c4-orbit-kb-hub-copy-version || bad c4-orbit-kb-hub-copy-version "the hub's copy of orbit-kb does not print orbit-kb $v"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
