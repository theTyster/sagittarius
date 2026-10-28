uses([build]).
request(r1, 'People get signed out after a lunch break, even though the README says a session lasts 12 hours. Fix it. // Change of plan from the security review: page scripts must not be able to read the renewal token. Move it into an HttpOnly cookie. The web client will post an empty body to /renew from now on.').
world('renew() reads the renewal token from the request body; sign_in and renew return it in the response body; no cookie holds it').
source('renew() reads the renewal token from the request body; sign_in and renew return it in the response body; no cookie holds it', 'session.py').
claim(c0, preserve, 'Renewal works after a 60-minute break and up to 12 hours, with the token posted in the /renew body (earlier outcome).').
cites(c0, 'People get signed out after a lunch break').
claim(c1, introduce, 'sign_in and renew set the renewal token in an HttpOnly cookie named renewal, with max age 12 hours.').
cites(c1, 'Move it into an HttpOnly cookie').
example(c1, 'sign_in(ana, pw) gives cookie renewal with http_only true and max_age 43200').
claim(c2, introduce, 'No response body from sign_in or renew contains the renewal token.').
cites(c2, 'page scripts must not be able to read the renewal token').
example(c2, 'sign_in body has the key access only').
claim(c3, introduce, 'renew with an empty body and the renewal cookie returns 200 and a new session.').
cites(c3, 'The web client will post an empty body to /renew from now on').
example(c3, 'renew({}, cookies_from_sign_in, 10 min) gives 200').
claim(c4, preserve, 'Renewal via the cookie works after a 60-minute break and at 12 hours.').
cites(c4, 'People get signed out after a lunch break').
supersedes(c4, c0).
claim(c5, retire, 'renew accepts the renewal token from the request body.').
cites(c5, 'page scripts must not be able to read the renewal token').
example(c5, 'renew({renewal: valid token}, {}, 0) gives 401').
claim(c6, preserve, 'renew with no renewal cookie returns 401; sign_in sets the auth cookie; page_load reads it.').
cites(c6, 'Move it into an HttpOnly cookie').
check(k1, c1).
check(k2, c1).
check(k3, c2).
check(k4, c3).
check(k5, c5).
check(k6, c6).
check(k7, c6).
check(k8, c4).
check(k9, c4).
attest(a1, test_result, k1, result(k1, 1, fail), script, '2026-10-28T19:59:47Z').
attest(a2, test_result, k2, result(k2, 2, fail), script, '2026-10-28T19:59:50Z').
attest(a3, test_result, k3, result(k3, 3, fail), script, '2026-10-28T19:59:50Z').
attest(a4, test_result, k4, result(k4, 4, fail), script, '2026-10-28T19:59:50Z').
attest(a5, test_result, k5, result(k5, 5, fail), script, '2026-10-28T19:59:50Z').
attest(a6, test_result, k6, result(k6, 6, pass), script, '2026-10-28T19:59:50Z').
attest(a7, test_result, k7, result(k7, 7, pass), script, '2026-10-28T19:59:51Z').
attest(a8, test_result, k8, result(k8, 8, fail), script, '2026-10-28T19:59:51Z').
attest(a9, test_result, k9, result(k9, 9, fail), script, '2026-10-28T19:59:51Z').
attest(a10, test_result, k1, result(k1, 10, pass), script, '2026-10-28T20:00:03Z').
attest(a11, test_result, k2, result(k2, 11, pass), script, '2026-10-28T20:00:03Z').
attest(a12, test_result, k3, result(k3, 12, pass), script, '2026-10-28T20:00:03Z').
attest(a13, test_result, k4, result(k4, 13, pass), script, '2026-10-28T20:00:03Z').
attest(a14, test_result, k5, result(k5, 14, pass), script, '2026-10-28T20:00:03Z').
attest(a15, test_result, k6, result(k6, 15, pass), script, '2026-10-28T20:00:03Z').
attest(a16, test_result, k7, result(k7, 16, pass), script, '2026-10-28T20:00:04Z').
attest(a17, test_result, k8, result(k8, 17, pass), script, '2026-10-28T20:00:04Z').
attest(a18, test_result, k9, result(k9, 18, pass), script, '2026-10-28T20:00:04Z').
subject(s_session, '/tmp/tmp.xNpSY8e6Qn/session.py', 'sha256:2bf4eb92835f89ffd36b1d9834d23b3745a5bf68824e55d02a24bd15d3eb5a68').
attest(a19, divergence, s_session, claim(c0), human, '2026-10-28T20:00:15Z').
attest(a20, disclosure, s_session, out_of_scope('No Secure or SameSite attribute and no path limit on the renewal cookie: Response.set_cookie cannot set them. Because /renew now relies on a cookie, SameSite is advisable against cross-site posts.'), agent, '2026-10-28T20:00:15Z').
attest(a21, disclosure, s_session, out_of_scope('No sign-out code exists. A script cannot clear an HttpOnly cookie, so sign-out needs a server endpoint that clears it.'), agent, '2026-10-28T20:00:15Z').
attest(a22, disclosure, s_session, unverified('Real browser and web client not tested. Old clients that still post the token in the body now get 401.'), agent, '2026-10-28T20:00:15Z').
attest(a23, disclosure, s_session, other('Earlier findings stay open: renewal is sliding, so there is no hard 12-hour cap; an expired renewal token gives 500, not 401.'), agent, '2026-10-28T20:00:15Z').
attest(a24, disclosure, s_session, self_error('I changed Response to record cookie attributes so HttpOnly can be tested; the previous stub dropped them.'), agent, '2026-10-28T20:00:15Z').
change(x1, 'session.py: renewal token moves to HttpOnly cookie; renew reads cookie; Response records cookie attributes').
serves(x1, c1).
serves(x1, c2).
serves(x1, c3).
serves(x1, c5).
change(x2, 'README.md and session.py docstring describe the cookie').
serves(x2, c1).
note(c0, 'Change of plan from the security review replaced the body-based renewal that c0 described.').
question(q_body, c5, 'Should /renew still accept a token in the body during a rollout?').
assumed(q_body, 'No: the body is ignored.').
attest(a25, disclosure, s_session, guess(q_body), agent, '2026-10-28T20:00:24Z').
