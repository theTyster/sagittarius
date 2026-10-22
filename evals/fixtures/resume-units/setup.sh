# Runs in the work directory before the agent starts. It leaves the KB that an
# earlier session wrote: one claim, a red check, and a dormant question.
set -e
orbit-kb init kb --request 'km_to_miles is off by a few percent. Use the exact factor.' --uses build >/dev/null 2>&1
cd kb
orbit-kb add "claim(c1, introduce, 'km_to_miles(10) returns 6.21371 to four places.')" \
             "cites(c1, 'Use the exact factor.')" \
             "example(c1, 'km_to_miles(10) = 6.21371')" \
             "check(k1, c1)" \
             "question(q1, c1, 'Round the result, or return the full float?')" \
             "assumed(q1, full_float)" >/dev/null
orbit-kb run k1 -- sh -c 'cd .. && python3 -m unittest -q test_units' >/dev/null 2>&1 || true
