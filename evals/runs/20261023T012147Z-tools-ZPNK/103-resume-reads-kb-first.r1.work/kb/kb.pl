uses([build]).
request(r1, 'sales_tax charges a little too little. It must use the 7.25% county rate.').
claim(c2, introduce, 'sales_tax(200) returns 14.50.').
cites(c2, 'It must use the 7.25% county rate.').
example(c2, 'sales_tax(200) = 14.50').
check(k2, c2).
question(q1, c2, 'Round the tax to whole cents, or return the unrounded amount?').
assumed(q1, unrounded).
attest(a1, test_result, k2, result(k2, 1, fail), script, '2026-10-23T01:23:42Z').
