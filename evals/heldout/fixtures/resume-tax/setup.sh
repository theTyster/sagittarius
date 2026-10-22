# Runs in the work directory before the agent starts. It leaves the KB that an
# earlier session wrote: one claim, a red check, and a dormant question.
set -e
orbit-kb init kb --request 'sales_tax charges a little too little. It must use the 7.25% county rate.' --uses build >/dev/null 2>&1
cd kb
orbit-kb add "claim(c2, introduce, 'sales_tax(200) returns 14.50.')" \
             "cites(c2, 'It must use the 7.25% county rate.')" \
             "example(c2, 'sales_tax(200) = 14.50')" \
             "check(k2, c2)" \
             "question(q1, c2, 'Round the tax to whole cents, or return the unrounded amount?')" \
             "assumed(q1, unrounded)" >/dev/null
orbit-kb run k2 -- sh -c 'cd .. && python3 -m unittest -q test_tax' >/dev/null 2>&1 || true
