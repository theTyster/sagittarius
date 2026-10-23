uses([build]).
request(r1, 'format_price should group thousands with commas, so format_price(123456) gives "$1,234.56". The test is already there, PriceFormatTest.test_thousands_separator in test_prices.py, and it fails on the current code, which is what we want.').
claim(c1, introduce, 'format_price groups thousands with commas.').
cites(c1, 'format_price should group thousands with commas').
example(c1, 'format_price(123456) returns "$1,234.56"').
check(k1, c1).
claim(c2, preserve, 'format_price keeps amounts under one thousand unchanged.').
cites(c2, 'format_price should group thousands with commas (existing behavior for small amounts)').
example(c2, 'format_price(1999) returns "$19.99"').
check(k2, c2).
world(format_price_current('no separator: format_price(123456) returns "$1234.56"')).
source(format_price_current('no separator: format_price(123456) returns "$1234.56"'), 'python3 -m unittest test_prices, run on 2026-10-22').
not_explored('negative amounts and rounding of fractional cents').
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-23T01:22:10Z').
attest(a2, test_result, k2, result(k2, 2, pass), script, '2026-10-23T01:22:10Z').
