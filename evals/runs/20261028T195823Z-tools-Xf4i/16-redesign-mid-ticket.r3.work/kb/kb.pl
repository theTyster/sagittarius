uses([build]).
request(r1, 'Change of plan from the security review: page scripts must not be able to read the renewal token. Move it into an HttpOnly cookie. The web client will post an empty body to /renew from now on.').
claim(c0, preserve, 'A renewal token works after a 60 minute break and up to 12 hours (earlier fix).').
cites(c0, 'People get signed out after a lunch break').
claim(c1, introduce, 'Sign-in and renew send the renewal token only in an HttpOnly cookie, never in the response body.').
cites(c1, 'page scripts must not be able to read the renewal token. Move it into an HttpOnly cookie.').
example(c1, 'sign_in body has no renewal key; cookie renewal is http_only').
claim(c2, introduce, 'renew reads the renewal token from the cookie; an empty body works.').
cites(c2, 'post an empty body to /renew').
example(c2, 'renew({}, {renewal: tok}, now=60min) is 200').
claim(c3, retire, 'renew no longer accepts a renewal token in the body.').
cites(c3, 'post an empty body to /renew').
example(c3, 'renew({renewal: tok}, {}, now=0) is 401').
claim(c4, preserve, 'The access cookie and page_load still work.').
cites(c4, 'Move it into an HttpOnly cookie').
check(k0, c0).
check(k1, c1).
check(k2, c2).
check(k3, c3).
check(k4, c4).
attest(a1, divergence, c0, claim(c0), human, '2026-10-28T19:59:01Z').
attest(a2, test_result, k0, result(k0, 1, fail), script, '2026-10-28T19:59:18Z').
attest(a3, test_result, k1, result(k1, 2, fail), script, '2026-10-28T19:59:18Z').
attest(a4, test_result, k2, result(k2, 3, fail), script, '2026-10-28T19:59:19Z').
attest(a5, test_result, k3, result(k3, 4, fail), script, '2026-10-28T19:59:19Z').
attest(a6, test_result, k4, result(k4, 5, pass), script, '2026-10-28T19:59:19Z').
attest(a7, test_result, k0, result(k0, 6, pass), script, '2026-10-28T19:59:26Z').
attest(a8, test_result, k1, result(k1, 7, pass), script, '2026-10-28T19:59:26Z').
attest(a9, test_result, k2, result(k2, 8, pass), script, '2026-10-28T19:59:26Z').
attest(a10, test_result, k3, result(k3, 9, pass), script, '2026-10-28T19:59:26Z').
attest(a11, test_result, k4, result(k4, 10, pass), script, '2026-10-28T19:59:26Z').
change(x1, 'session.py: renewal token in HttpOnly cookie, removed from body; renew reads the cookie').
serves(x1, c1).
serves(x1, c2).
serves(x1, c3).
change(x2, 'test_session.py: tests use the cookie; new tests for c1-c3').
serves(x2, c0).
change(x3, 'README.md: describe cookie').
serves(x3, c1).
attest(a12, disclosure, c1, out_of_scope('No SameSite or Path on the renewal cookie: set_cookie has no such options. /renew by cookie is now CSRF-reachable.'), agent, '2026-10-28T19:59:31Z').
attest(a13, disclosure, c2, unverified('Invalid or expired renewal token still raises InvalidToken (500), as before.'), agent, '2026-10-28T19:59:31Z').
