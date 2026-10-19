set -u
export XDG_CACHE_HOME=$(mktemp -d /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/tmp/xdg-XXXXXX)
export TMPDIR=/home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/tmp
CLI=$(readlink -f ~/.local/bin/orbit-kb)
echo "CLI sha256: $(sha256sum < $CLI | cut -c1-16); module: $(sha256sum < /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/h2/modules/discovery.pl | cut -c1-16); lint_cli.sh: $(sha256sum < /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/harness/lint_cli.sh | cut -c1-16)"
cp /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/harness/lint_cli.sh /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/h2/harness/lint_cli.sh
timeout 600 bash /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/h2/harness/lint_cli.sh /home/ty/.dotfiles/thoughts/discovery-orbit/discovery-orbit-examples/orbit-kb-staging/scratch/landing/h2/modules/discovery.pl; echo "lint_cli rc=$?"
