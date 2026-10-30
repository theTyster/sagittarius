uses([build]).
request(r1, 'Our privacy review flagged optouts.csv. We can\'t keep people\'s email addresses in the opt-out list in plain text anymore. Switch it to store a SHA-256 hash of each address instead, and convert the existing file. subscribers.csv stays as it is.').
claim(c1, preserve, 'An opted-out reader never gets the newsletter, whatever the capitals or edge spaces of the address in either file.').
cites(c1, 'Earlier ticket: readers who unsubscribed still get the newsletter.').
claim(c2, introduce, 'optouts.csv holds no plain-text email address; each row holds the SHA-256 of the normalized address.').
cites(c2, 'We can\'t keep people\'s email addresses in the opt-out list in plain text anymore. Switch it to store a SHA-256 hash').
claim(c3, introduce, 'opt_out() writes the hash of the normalized address, not the address.').
cites(c3, 'Switch it to store a SHA-256 hash of each address instead').
claim(c4, introduce, 'The existing optouts.csv is converted: same readers and dates, hashes only.').
cites(c4, 'convert the existing file').
claim(c5, preserve, 'subscribers.csv is unchanged.').
cites(c5, 'subscribers.csv stays as it is.').
example(c2, 'Row for Maria.K@Example.net becomes the SHA-256 of maria.k@example.net, plus the date 2026-08-19.').
assumption(a1, 'Hash input is the normalized address (strip, lower) in UTF-8, as lowercase hex; the header is renamed to email_sha256.').
risk(k1, 'Conversion overwrites optouts.csv; the plain addresses cannot be recovered from it. No plain-text backup is kept, on purpose.').
risk(k2, 'Unsalted SHA-256 of an email can be reversed by guessing addresses. This is what was asked; it is weaker than a keyed hash.').
check(t1, c1).
check(t2, c2).
check(t3, c3).
check(t4, c4).
check(t5, c5).
attest(a2, test_result, t1, result(t1, 1, pass), script, '2026-10-30T10:27:30Z').
attest(a3, test_result, t2, result(t2, 2, fail), script, '2026-10-30T10:27:30Z').
attest(a4, test_result, t3, result(t3, 3, fail), script, '2026-10-30T10:27:31Z').
attest(a5, test_result, t4, result(t4, 4, fail), script, '2026-10-30T10:27:31Z').
attest(a6, test_result, t5, result(t5, 5, pass), script, '2026-10-30T10:27:31Z').
attest(a7, test_result, t5, result(t5, 6, pass), script, '2026-10-30T10:27:38Z').
attest(a8, test_result, t1, result(t1, 7, pass), script, '2026-10-30T10:27:44Z').
attest(a9, test_result, t2, result(t2, 8, pass), script, '2026-10-30T10:27:44Z').
attest(a10, test_result, t3, result(t3, 9, pass), script, '2026-10-30T10:27:44Z').
attest(a11, test_result, t4, result(t4, 10, pass), script, '2026-10-30T10:27:44Z').
change(x1, 'mailing.py: digest(); opt_out() writes the digest; opted_out() reads email_sha256; recipients() compares digests').
serves(x1, c1).
serves(x1, c3).
change(x2, 'optouts.csv converted in place to email_sha256,date').
serves(x2, c2).
serves(x2, c4).
