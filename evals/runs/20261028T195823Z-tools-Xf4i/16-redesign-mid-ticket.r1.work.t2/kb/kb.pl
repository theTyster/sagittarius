uses([build]).
request(r1, 'Change of plan from the security review: page scripts must not be able to read the renewal token. Move it into an HttpOnly cookie. The web client will post an empty body to /renew from now on.').
claim(c1, retire, 'The renewal token is in a JSON response body, where page scripts can read it.').
cites(c1, 'page scripts must not be able to read the renewal token').
example(c1, 'sign_in(ana).body has no "renewal" key; renew(...).body has none either').
claim(c2, introduce, 'Sign-in and renew set the renewal token in an HttpOnly cookie named renewal, with a 12 hour max age.').
cites(c2, 'Move it into an HttpOnly cookie').
example(c2, 'sign_in(ana).cookies[renewal] is the token, with http_only true and max_age 43200').
claim(c3, introduce, 'renew reads the renewal token from the cookie; an empty body works.').
cites(c3, 'post an empty body to /renew').
example(c3, 'renew({}, {renewal: T}, now=10min) gives 200 and new cookies').
claim(c4, preserve, 'A renewal token stays valid for 12 hours, so a renewal after a lunch break works.').
cites(c4, 'earlier ticket: people get signed out after a lunch break, session lasts 12 hours').
example(c4, 'renew with the cookie at 1 hour and at 11 hours gives 200').
claim(c5, preserve, 'Without a renewal token, renew gives 401. Sign-in still returns the access token in the body and sets the auth cookie.').
cites(c5, 'Move it into an HttpOnly cookie (only the renewal token moves)').
example(c5, 'renew({}, {}, now=0) gives 401; sign_in body still has access').
attest(a1, divergence, c1, claim(c1), human, '2026-10-28T19:59:06Z').
note(c1, 'Human changed the design after the first delivery: the renewal token moves from the body to an HttpOnly cookie. Earlier tests assert the old behavior and change with it.').
check(k1, c1).
check(k2, c2).
check(k3, c3).
check(k4, c4).
check(k5, c5).
attest(a2, test_result, k1, result(k1, 1, fail), script, '2026-10-28T19:59:20Z').
attest(a3, test_result, k2, result(k2, 2, fail), script, '2026-10-28T19:59:20Z').
attest(a4, test_result, k3, result(k3, 3, fail), script, '2026-10-28T19:59:20Z').
attest(a5, test_result, k4, result(k4, 4, fail), script, '2026-10-28T19:59:20Z').
attest(a6, test_result, k5, result(k5, 5, fail), script, '2026-10-28T19:59:20Z').
attest(a7, test_result, k1, result(k1, 6, pass), script, '2026-10-28T19:59:34Z').
attest(a8, test_result, k2, result(k2, 7, pass), script, '2026-10-28T19:59:34Z').
attest(a9, test_result, k3, result(k3, 8, pass), script, '2026-10-28T19:59:34Z').
attest(a10, test_result, k4, result(k4, 9, pass), script, '2026-10-28T19:59:34Z').
attest(a11, test_result, k5, result(k5, 10, pass), script, '2026-10-28T19:59:34Z').
change(x1, 'session.py: renewal token set in HttpOnly cookie, removed from body').
serves(x1, c1).
serves(x1, c2).
change(x2, 'session.py: renew reads the renewal cookie, ignores the body').
serves(x2, c3).
serves(x2, c5).
change(x3, 'session.py: Response records cookie attributes so checks can see HttpOnly').
serves(x3, c2).
attest(a12, disclosure, c2, other('Response.set_cookie dropped max_age and http_only; I record them in cookie_attrs, else c2 cannot fail.'), agent, '2026-10-28T19:59:34Z').
