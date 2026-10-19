set -u
export TMPDIR=/home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/tmp
echo "== selftest.sh (copy in h2; module $(sha256sum < /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/h2/modules/discovery.pl | cut -c1-16))"
timeout 900 bash /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/h2/harness/selftest.sh; echo "selftest rc=$?"
echo "== only=typo probe (expect: exit 1 or a FAIL line for an unknown variant)"
timeout 300 swipl /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/h2/harness/run.pl /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/h2/fixtures/discovery-a /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/lib only=no_such_variant; echo "only-typo rc=$?"
echo "== cli_conformance.sh (copy in h2, frozen fixture fx157)"
timeout 1800 bash /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/h2/harness/cli_conformance.sh; echo "cli_conformance rc=$?"
