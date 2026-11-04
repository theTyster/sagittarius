# Runs in the work directory before the agent starts. It leaves the KB that a peer
# session wrote before it handed the ticket off: the request, one claim with an
# example, its check (test_purge.py), and a red run. The code is not built yet.
set -e
orbit-kb init kb --request 'Add a purge command to tasks.py that deletes the finished tasks.' --uses build >/dev/null 2>&1
cd kb
orbit-kb add "claim(c1, introduce, 'python3 tasks.py purge deletes every finished task and keeps the open ones.')" \
             "cites(c1, 'Add a purge command to tasks.py that deletes the finished tasks.')" \
             "example(c1, 'milk done, bread open, eggs done; purge leaves bread')" \
             "check(k1, c1)" >/dev/null
orbit-kb run k1 -- sh -c 'cd .. && python3 -m unittest -q test_purge' >/dev/null 2>&1 || true
