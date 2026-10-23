uses([build]).
request(r1, 'format_price should group thousands with commas, so format_price(123456) gives "$1,234.56". The test is already there, PriceFormatTest.test_thousands_separator in test_prices.py, and it fails on the current code, which is what we want.').
claim(c1, introduce, 'format_price groups thousands with commas.').
cites(c1, 'format_price should group thousands with commas').
example(c1, 'format_price(123456) gives $1,234.56').
check(k1, c1).
claim(c2, preserve, 'format_price keeps small amounts unchanged.').
cites(c2, 'format_price should group thousands with commas').
example(c2, 'format_price(1999) gives $19.99').
check(k2, c2).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:22:06Z').
attest(a2, test_result, k2, result(k2, 2, fail), script, '2026-10-23T01:22:06Z').
attest(a3, test_result, k1, result(k1, 3, fail), script, '2026-10-23T01:22:10Z').
attest(a4, test_result, k2, result(k2, 4, pass), script, '2026-10-23T01:22:11Z').
note(c1, 'HANDOFF to Monday session. Status: k1 is red for the right reason (run 3: AssertionError, $1234.56 != $1,234.56). Change NOT implemented, as asked. Next: add comma grouping to format_price in prices.py, then rerun k1 and k2 and the full suite from the project root.').
note(c1, 'Runs 1 and 2 (k1, k2) were launched from kb/ by mistake and failed on ModuleNotFoundError. They are not evidence. Runs 3 and 4 were run from the project root and are the valid results.').
note(c2, 'Open question for the human: negative amounts and fractional cents are not in the request. Default: leading minus sign, group only the integer part. Confirm before building.').
