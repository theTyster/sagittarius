set -u
export ORBIT_KB_LIB=/home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/lib
L=/home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing
echo "module sha256: $(sha256sum < $L/lib/modules/discovery.pl | cut -c1-16)"
q() { echo "$ orbit-kb query '$2' -n 0   [$1]"; timeout 120 orbit-kb --dir "$L/cli/$1" query "$2" -n 0 2>&1; echo "rc=$?"; }
lint() { echo "$ orbit-kb lint   [$1]"; timeout 120 orbit-kb --dir "$L/cli/$1" lint 2>&1; echo "rc=$?"; }
mk() { rm -rf "$L/cli/$1"; rsync -a --exclude expected.pl $L/fixtures/fx157/ "$L/cli/$1/"; }

echo "== CLI-P1 (L1): trusted target breaks c2b; the disprover abstained"
mk p1
sed -i 's/verdict(m_target, preserve(c2b), unsat)/verdict(m_target, preserve(c2b), sat)/' $L/cli/p1/kb.pl
orbit-kb --dir $L/cli/p1 attest disproof m_target 'verdict(c2b, abstained)'
q p1 'model_unfiled_break(C)'; q p1 'discovery_ready'; lint p1

echo "== CLI-P2 (L2): divergence model(m_now) recorded on the system log"
mk p2
orbit-kb --dir $L/cli/p2 attest divergence log4417 'model(m_now)'
q p2 'model_diverges(M)'; q p2 'discovery_ready'; lint p2

echo "== CLI-P3 (L6): the agent alone supersedes c1 (not refuted, not contested)"
mk p3
orbit-kb --dir $L/cli/p3 add "claim(c1b, introduce, 'No order is charged below its floor price after all codes.')" "cites(c1b, 'paid less than our minimum price')" 'supersedes(c1b, c1)' 'encodes(m_target, c1b)'
orbit-kb --dir $L/cli/p3 attest model_result run_target 'verdict(m_target, applies(c1b), sat)'
q p3 'discovery_unratified(C)'; q p3 'discovery_ready'; lint p3

echo "== CLI-P4: derived_from self-loop and cycle, raised_by a claim (kb2)"
q kb2 'model_diverges(M)'; q kb2 'discovery_ready'

echo "== CLI-P5 (L13): one exploration re-run with a blocked witness"
mk p5
orbit-kb --dir $L/cli/p5 attest model_result run_target 'verdict(m_target, explore(witnesses), sat)'
orbit-kb --dir $L/cli/p5 attest model_result run_target 'verdict(m_target, explore(witnesses), unsat)'
q p5 'discovery_ready'; lint p5
