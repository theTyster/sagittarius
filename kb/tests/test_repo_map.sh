#!/usr/bin/env bash
# Black-box tests for kb/bin/repo-map (ticket T12, claims c1-c3). repo-map is a separate tool
# from orbit-kb, so it has no CONTRACT entry (no D26); its spec is kb/share/repo-map/README.md.
#
# Usage: kb/tests/test_repo_map.sh [path-to-repo-map]   (or REPO_MAP_BIN=...)
# Exit: 0 all pass, 1 a test failed, 2 the suite cannot run.
# The tests use the CLI only through its command line:
#   repo-map --facts KB_PL --containers CONTAINERS_PL [--level c1|c2|both]
# stdout is Markdown with Mermaid C4 diagrams; usage errors exit 2.
#
# Input hash (the contract of c2): sha256 over the bytes of the facts file, then one NUL byte,
# then the bytes of the containers file. The map carries `map@` and the first 12 hex digits.
# Requirement map: C1a-C1d (c1), C2a-C2d (c2), C3a-C3b (c3), U1 (usage).
set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(cd "$here/../.." && pwd -P)
RM=${1:-${REPO_MAP_BIN:-$repo/kb/bin/repo-map}}
for tool in swipl sha256sum mktemp awk grep sed; do
    command -v "$tool" >/dev/null 2>&1 || { echo "test_repo_map.sh: required tool not found: $tool" >&2; exit 2; }
done
EX_KB=$repo/kb/share/repo-map/example-kb.pl
EX_CT=$repo/kb/share/repo-map/sagittarius.containers.pl

pass=0 fail=0
base=$(mktemp -d "${TMPDIR:-/tmp}/repo-map-test.XXXXXX") || exit 2
trap 'rm -rf "$base"' EXIT
out="" err="" rc=0
FAILS=()
note() { FAILS+=("$*"); }
snip() { printf '%s' "$1" | head -c 300 | tr '\n' '~'; }
rm_run() {  # rm_run ARGS...: run the tool; sets out, err, rc
    "$RM" "$@" >"$base/.out" 2>"$base/.err" </dev/null; rc=$?
    out=$(<"$base/.out"); err=$(<"$base/.err")
}
rc_is()  { [ "$rc" = "$1" ] || note "${2:+$2: }exit $rc, want $1 (stdout: $(snip "$out") | stderr: $(snip "$err"))"; }
out_has()   { printf '%s\n' "$out" | grep -Eq -- "$1" || note "${2:+$2: }stdout lacks /$1/ (stdout: $(snip "$out"))"; }
out_hasnt() { if printf '%s\n' "$out" | grep -Eq -- "$1"; then note "${2:+$2: }stdout has /$1/"; fi; }
all_hasnt_f() {  # a fixed string in neither stdout nor stderr
    if printf '%s\n%s\n' "$out" "$err" | grep -Fq -- "$1"; then note "${2:+$2: }output has the string '$1'"; fi
}

# Structural Mermaid check of stdout: fences paired, each diagram opens with C4Context or
# C4Container, every body line starts with a known C4 keyword (or a brace or comment), parens
# are balanced outside quotes, quotes are even, braces balance. Not a render.
mermaid_ok() {
    printf '%s\n' "$out" | awk '
        /^```mermaid$/ { if (inb) bad("nested fence"); inb=1; first=1; depth=0; next }
        /^```$/        { if (!inb) bad("stray fence"); else { if (depth!=0) bad("unbalanced braces"); n++ } inb=0; next }
        inb {
            line=$0; sub(/^[ \t]+/, "", line)
            if (line=="") next
            if (first) { if (line!="C4Context" && line!="C4Container") bad("bad diagram type: " line); first=0; next }
            if (line ~ /^%%/) next
            if (line=="}") { depth--; next }
            if (line !~ /^(title|Person|Person_Ext|System|System_Ext|SystemDb|Container|ContainerDb|Container_Ext|Container_Boundary|System_Boundary|Boundary|Enterprise_Boundary|Rel|BiRel|UpdateLayoutConfig)( |\()/) bad("unknown keyword: " line)
            q=gsub(/"/, "\"", line); if (q%2) bad("odd quotes: " line)
            t=line; gsub(/"[^"]*"/, "", t)
            o=gsub(/\(/, "(", t); c=gsub(/\)/, ")", t); if (o!=c) bad("unbalanced parens: " line)
            if (t ~ /\{[ \t]*$/) depth++
        }
        function bad(m) { print "MERMAID: " m; e=1 }
        END { if (inb) { print "MERMAID: unclosed fence"; e=1 } if (n<1) { print "MERMAID: no diagram"; e=1 } exit e }
    ' >"$base/.m" 2>&1 || note "mermaid structure: $(snip "$(<"$base/.m")")"
}

hash12() {  # hash12 FACTS CONTAINERS: the first 12 hex of sha256(facts NUL containers)
    { cat "$1"; printf '\0'; cat "$2"; } | sha256sum | cut -c1-12
}
mkfix() {  # mkfix DIR: a small fixture (kb.pl with three repos, a containers file)
    mkdir -p "$1"
    cat > "$1/kb.pl" <<'KB'
uses(project).
repo(alpha, '/srv/work/alpha').
repo(beta, '/srv/work/beta').
repo(gamma, '/srv/work/gamma').
KB
    cat > "$1/containers.pl" <<'CT'
repo(alpha).
person(dev, 'Developer', 'Works on alpha.').
external(cloud, 'Cloud service', 'Hosts things.').
container(web, 'Web app', 'Python', 'Serves pages.').
container(store, 'Store', 'SQLite', 'Keeps data.').
link(dev, web, 'uses').
link(web, store, 'reads and writes').
link(web, beta, 'calls').
link(web, cloud, 'deploys to').
CT
}

# ---------------------------------------------------------------- c1
t_C1a() {  # the example renders both diagrams for sagittarius
    rm_run --facts "$EX_KB" --containers "$EX_CT"; rc_is 0
    out_has '^C4Context$' "C1 diagram"; out_has '^ *C4Container$' "C2 diagram" || true
    out_has 'System\(sagittarius,' "this repo is a System in C1"
    out_has 'Container_Boundary\(sagittarius,' "this repo is the boundary in C2"
}
t_C1b() {  # C2 lists the seven parts of the repo
    rm_run --facts "$EX_KB" --containers "$EX_CT"; rc_is 0
    local c
    for c in prompt orbit_kb hubkit s1 evals site docs; do out_has "Container\\($c," "container $c"; done
    out_has 'Rel\(' "links"
}
t_C1c() {  # the output is well-formed Mermaid C4 (structure only, not rendered)
    rm_run --facts "$EX_KB" --containers "$EX_CT"; rc_is 0; mermaid_ok
    rm_run --facts "$EX_KB" --containers "$EX_CT" --level c1; rc_is 0; mermaid_ok
    out_hasnt 'C4Container' "level c1 has no C2"
    rm_run --facts "$EX_KB" --containers "$EX_CT" --level c2; rc_is 0; mermaid_ok
    out_hasnt 'C4Context' "level c2 has no C1"
}
t_C1d() {  # the example is truthful: the paths of the parts that exist today exist
    local p
    for p in prompt/SAGITTARIUS.md kb/bin/orbit-kb evals/run.sh site/index.html docs/PHILOSOPHY.md; do
        [ -e "$repo/$p" ] || note "missing $p"
    done
    [ -f "$EX_CT" ] || { note "no committed containers example $EX_CT"; return; }
    grep -q 'planned' "$EX_CT" || note "hubkit and s1 are not in the tree yet; the example must say planned"
}

# ---------------------------------------------------------------- c2
t_C2a() {  # map@ + 12 hex of sha256(facts NUL containers), once
    mkfix "$base/c2a"
    rm_run --facts "$base/c2a/kb.pl" --containers "$base/c2a/containers.pl"; rc_is 0
    local want; want=$(hash12 "$base/c2a/kb.pl" "$base/c2a/containers.pl")
    out_has "map@$want( |\$)" "the hash of the inputs ($want)"
    [ "$(printf '%s\n' "$out" | grep -o 'map@' | wc -l)" = 1 ] || note "map@ must occur exactly once"
    printf '%s\n' "$out" | grep -Eo 'map@[0-9a-f]+' | grep -Eqx 'map@[0-9a-f]{12}' || note "map@ is not followed by exactly 12 hex"
}
t_C2b() {  # the hash follows the inputs; the same inputs give the same output
    mkfix "$base/c2b"
    rm_run --facts "$base/c2b/kb.pl" --containers "$base/c2b/containers.pl"; rc_is 0; local a=$out
    rm_run --facts "$base/c2b/kb.pl" --containers "$base/c2b/containers.pl"; [ "$out" = "$a" ] || note "output is not deterministic"
    printf '%% a comment\n' >> "$base/c2b/containers.pl"
    rm_run --facts "$base/c2b/kb.pl" --containers "$base/c2b/containers.pl"; rc_is 0
    local want; want=$(hash12 "$base/c2b/kb.pl" "$base/c2b/containers.pl")
    out_has "map@$want" "hash after a containers edit"
    [ "$out" != "$a" ] || note "a changed input must change the map"
    # the order is fixed: swapping the two files' roles must not give the same hash
    [ "$(hash12 "$base/c2b/containers.pl" "$base/c2b/kb.pl")" != "$want" ] || note "test setup: swapped hash equals"
}
t_C2c() {  # a project KB under a hub-like directory: neither its name nor its path is in the output
    local hub="$base/hubx-main-hub-9z"
    mkfix "$base/stage"; mkdir -p "$hub/project-kb"
    cp "$base/stage/kb.pl" "$hub/project-kb/kb.pl"; cp "$base/stage/containers.pl" "$hub/project-kb/containers.pl"
    printf "repo(delta, '%s/delta').\n" "$hub" >> "$hub/project-kb/kb.pl"
    rm_run --facts "$hub/project-kb/kb.pl" --containers "$hub/project-kb/containers.pl"; rc_is 0
    all_hasnt_f "hubx-main-hub-9z" "hub dir name"; all_hasnt_f "$hub" "hub path"; all_hasnt_f "project-kb" "kb dir name"
    out_has 'map@[0-9a-f]{12}' "still carries the hash"
    ( cd "$hub/project-kb" && "$RM" --facts kb.pl --containers containers.pl --level both ) >"$base/.out" 2>"$base/.err"
    out=$(<"$base/.out"); err=$(<"$base/.err")
    all_hasnt_f "hubx-main-hub-9z" "relative paths: hub dir name"; all_hasnt_f "$base" "relative paths: any absolute path"
    # no location of any repo appears either
    all_hasnt_f "/srv/work" "repo locations"
}
t_C2d() {  # the hash is not a function of the file names or the directory
    mkfix "$base/x1"; mkfix "$base/x2"; mv "$base/x2/kb.pl" "$base/x2/other_name.pl"
    rm_run --facts "$base/x1/kb.pl" --containers "$base/x1/containers.pl"; local a=$out
    rm_run --facts "$base/x2/other_name.pl" --containers "$base/x2/containers.pl"; rc_is 0
    [ "$out" = "$a" ] || note "same bytes under other names must give the same map"
}

# ---------------------------------------------------------------- c3
t_C3a() {  # repo/2 facts drive the C1 system list
    mkfix "$base/c3a"
    rm_run --facts "$base/c3a/kb.pl" --containers "$base/c3a/containers.pl" --level c1; rc_is 0
    out_has 'System\(alpha,' "alpha (this repo)"; out_has 'System_Ext\(beta,' "beta"; out_has 'System_Ext\(gamma,' "gamma"
    out_hasnt 'delta' "no delta yet"
    printf "repo(delta, '/srv/work/delta').\n" >> "$base/c3a/kb.pl"
    rm_run --facts "$base/c3a/kb.pl" --containers "$base/c3a/containers.pl" --level c1; rc_is 0
    out_has 'System_Ext\(delta,' "delta added"
    grep -v '^repo(gamma' "$base/c3a/kb.pl" > "$base/c3a/kb2.pl"
    rm_run --facts "$base/c3a/kb2.pl" --containers "$base/c3a/containers.pl" --level c1; rc_is 0
    out_hasnt 'gamma' "gamma removed"; out_has 'System_Ext\(delta,' "delta stays"
}
t_C3b() {  # a repo/2 fact that no link mentions still shows in C1; C2 shows only linked outside systems
    mkfix "$base/c3b"
    rm_run --facts "$base/c3b/kb.pl" --containers "$base/c3b/containers.pl" --level c2; rc_is 0
    out_has 'System_Ext\(beta,' "beta is linked from web"; out_hasnt 'gamma' "gamma is not linked, so not in C2"
    out_has 'Rel\(web, beta,' "link to beta"
}

# ---------------------------------------------------------------- usage
t_U1() {  # usage errors exit 2
    rm_run; rc_is 2 "no args"
    rm_run --facts "$base/none.pl" --containers "$base/none2.pl"; rc_is 2 "missing files"
    mkfix "$base/u1"
    rm_run --facts "$base/u1/kb.pl" --containers "$base/u1/containers.pl" --level c9; rc_is 2 "bad level"
}

for t in C1a C1b C1c C1d C2a C2b C2c C2d C3a C3b U1; do
    FAILS=(); "t_$t"
    if [ ${#FAILS[@]} -eq 0 ]; then pass=$((pass+1)); echo "PASS $t"
    else fail=$((fail+1)); echo "FAIL $t"; for m in "${FAILS[@]}"; do echo "     - $m"; done; fi
done
echo "----"
echo "repo-map=$RM pass=$pass fail=$fail"
[ $fail = 0 ]
