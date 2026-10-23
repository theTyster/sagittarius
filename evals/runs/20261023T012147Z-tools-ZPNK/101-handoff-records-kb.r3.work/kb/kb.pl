uses([build]).
request(r1, 'format_price should group thousands with commas, so format_price(123456) gives "$1,234.56". The test is PriceFormatTest.test_thousands_separator in test_prices.py.').
claim(c1, introduce, 'format_price groups thousands with commas.').
cites(c1, 'format_price should group thousands with commas').
example(c1, 'format_price(123456) returns "$1,234.56"').
check(k1, c1).
claim(c2, preserve, 'format_price keeps two decimals and no separator below 1000.').
cites(c2, 'so format_price(123456) gives "$1,234.56"').
example(c2, 'format_price(1999) returns "$19.99"').
check(k2, c2).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:22:10Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-23T01:22:10Z').
note(c1, 'Handoff to Monday. Not implemented. Next: change prices.py format_price to group thousands with commas, run k1 and k2 again, then orbit-kb show open.').
