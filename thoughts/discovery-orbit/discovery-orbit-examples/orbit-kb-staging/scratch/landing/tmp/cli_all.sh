set -u
S=/home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging
L=$S/scratch/landing
export ORBIT_KB_LIB=$L/lib
export XDG_CACHE_HOME=$(mktemp -d $L/tmp/xdg-XXXXXX)
export TMPDIR=$L/tmp
CLI=$(readlink -f ~/.local/bin/orbit-kb)
echo "CLI sha256 at start: $(sha256sum < $CLI | cut -c1-16); module: $(sha256sum < $L/lib/modules/discovery.pl | cut -c1-16); XDG_CACHE_HOME=$XDG_CACHE_HOME (empty: $(ls -A $XDG_CACHE_HOME | wc -l) entries)"
q() { echo "\$ orbit-kb query '$2' -n 0   [$1]"; timeout 180 orbit-kb --dir "$L/cli2/$1" query "$2" -n 0 2>&1; echo "rc=$?"; }
lint() { echo "\$ orbit-kb lint $2  [$1]"; timeout 180 orbit-kb --dir "$L/cli2/$1" lint $2 2>&1; echo "rc=$?"; }
mk() { rm -rf "$L/cli2/$1"; mkdir -p "$L/cli2"; rsync -a --exclude expected.pl $L/fixtures/fxnew/ "$L/cli2/$1/"; }
w() { echo "\$ orbit-kb $*"; timeout 120 orbit-kb "$@" 2>&1; echo "rc=$?"; }

echo "== base: lint, lint --strict, and every base expectation goal (stderr kept)"
mk base; lint base ""; lint base --strict
swipl -q -g "open('$L/fixtures/fxnew/expected.pl', read, S), repeat, read_term(S, T, []), ( T == end_of_file -> !, close(S) ; T = expect(base, G, _), format('~w~n', [G]), fail )" -t halt > $L/tmp/base-goals.txt
while IFS= read -r g; do q base "$g"; done < $L/tmp/base-goals.txt

echo "== R1 negative control analog: ED codes exit 1 (log tag removed)"
mk ed1; grep -v '^discovery_evidence(log4417, system)' $L/fixtures/fxnew/kb.pl > $L/cli2/ed1/kb.pl; lint ed1 ""

echo "== C1 writers"
mk wr
w --dir $L/cli2/wr attest decision h1 "hold(h1, 'Wait for the pricing team.')"
w --dir $L/cli2/wr attest decision h1 "hold(h1, 'Wait for the pricing team.')" --by human
w --dir $L/cli2/wr attest approval m_target 'digest(current)'
echo "== C2 H4"
w --dir $L/cli2/wr attest model_result run_target 'verdict(m_target, explore(order_4417), sat)'
w --dir $L/cli2/wr attest model_result run_now "calibration(m_now, case('order_4417'), matches)"
echo "== C4 refs"
w --dir $L/cli2/wr add "model_run(run_target, m_ghost, 'sha256:ac17a45536f31f4c27d0f85194dc4690e2aca118122023697632ec30908b664b')"
w --dir $L/cli2/wr add 'model(m_z, smt)'
w --dir $L/cli2/wr add 'derived_from(m_now, m_now)' 'derived_from(m_now, m_target)' 'lap_done(7)' 'raised_by(q1, c1)'
w --dir $L/cli2/wr add "model_run(log4417, m_target, 'sha256:ac17a45536f31f4c27d0f85194dc4690e2aca118122023697632ec30908b664b')"
lint wr ""; q wr 'discovery_ready'

echo "== C3 GO, then edit the ticket"
mk go
w --dir $L/cli2/go subject tk ticket.md
w --dir $L/cli2/go add 'ticket(tk)'
w --dir $L/cli2/go attest approval tk 'digest(current)' --by human
echo '- Added after GO: percentage codes are in scope.' >> $L/cli2/go/ticket.md
w --dir $L/cli2/go attest approval tk 'digest(current)' --by human
lint go ""
w --dir $L/cli2/go subject tk ticket.md
lint go ""; q go 'stale(A)'; q go 'discovery_ready'

echo "== CLI-P1 (L1) abstained disproof hides a break"
mk p1; sed -i 's/verdict(m_target, preserve(c2b), unsat)/verdict(m_target, preserve(c2b), sat)/' $L/cli2/p1/kb.pl
w --dir $L/cli2/p1 attest disproof m_target 'verdict(c2b, abstained)'
q p1 'model_unfiled_break(C)'; q p1 'discovery_ready'; lint p1 ""
echo "== CLI-P1b (L1) same with inconclusive"
mk p1b; sed -i 's/verdict(m_target, preserve(c2b), unsat)/verdict(m_target, preserve(c2b), sat)/' $L/cli2/p1b/kb.pl
w --dir $L/cli2/p1b attest disproof m_target 'verdict(c2b, inconclusive)'
q p1b 'discovery_ready'; lint p1b ""
echo "== CLI-P2 (L2) model divergence on the system log"
mk p2; w --dir $L/cli2/p2 attest divergence log4417 'model(m_now)'
q p2 'model_diverges(M)'; q p2 'discovery_ready'; lint p2 ""
echo "== CLI-P3 (L6a) agent-alone supersession of an undisputed claim"
mk p3
w --dir $L/cli2/p3 add "claim(c1b, introduce, 'No order is charged below its floor price after all codes.')" "cites(c1b, 'paid less than our minimum price')" 'supersedes(c1b, c1)' 'encodes(m_target, c1b)'
w --dir $L/cli2/p3 attest model_result run_target 'verdict(m_target, applies(c1b), sat)'
q p3 'discovery_unratified(C)'; q p3 'discovery_ready'; lint p3 ""
echo "== CLI-P4 (L4) derived_from cycle with the existing-world bad case unsat"
mk p4; sed -i 's/verdict(m_now, bad_case, sat)/verdict(m_now, bad_case, unsat)/' $L/cli2/p4/kb.pl
w --dir $L/cli2/p4 add 'derived_from(m_now, m_target)'
q p4 'model_diverges(M)'; q p4 'discovery_ready'; lint p4 ""
echo "== CLI-P5 (L13) exploration re-run"
mk p5
w --dir $L/cli2/p5 attest model_result run_target 'verdict(m_target, explore(witnesses), sat)'
w --dir $L/cli2/p5 attest model_result run_target 'verdict(m_target, explore(witnesses), unsat)'
q p5 'discovery_ready'; lint p5 ""
echo "CLI sha256 at end: $(sha256sum < $CLI | cut -c1-16)"
