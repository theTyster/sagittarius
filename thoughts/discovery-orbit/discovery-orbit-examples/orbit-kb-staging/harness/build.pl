% Stand-in for the orbit-kb build module, copied from the contract v2.1 for the discovery
% staging harness. The real modules/build.pl belongs to builder A. Docs and templates are mine.
% Since v2.1, test_result, passed/1, failed_after/2, and was_red/1 are in the core.

% --- Build facts ---
decl(fact, change(id, text), 'A change to the code, with a short description.', 'change @(1) is @(2)').
decl(fact, serves(ref(change), ref(claim)), 'A change, then a claim that it serves.', 'change @(1) serves claim @(2)').
decl(fact, burn_requested(ref(claim)), 'The human asks to prove the claim in Lean.', 'the human asks to burn claim @(1)').

% --- Build attestation types ---
attest_type(lean_result, verdict(ref(claim), alt([stated, refuted, tested(int), proved])), [agent, script], 'The result of a Lean statement or proof of a claim.').

% --- Build rules ---
decl(rule, fulfilled(ref(claim)), 'A current check of the claim passed, with a red baseline when the claim is not preserve.', 'claim @(1) is fulfilled').
decl(rule, under(ref(claim)), 'A current claim that is not fulfilled.', 'claim @(1) is under-built').
decl(rule, served(ref(change)), 'A change that serves some claim.', 'change @(1) serves a claim').
decl(rule, over(ref(change)), 'A change that serves no claim.', 'change @(1) is over-built').
decl(rule, any_under, 'Some current claim is not fulfilled.', 'some claim is under-built').
decl(rule, any_over, 'Some change serves no claim.', 'some change is over-built').
decl(rule, any_to_ask, 'Some question must be asked.', 'some question must be asked').
decl(rule, done, 'Every claim is fulfilled, every change serves a claim, and nothing must be asked.', 'the build is done').
decl(rule, burn(ref(claim)), 'A claim that needs a Lean proof.', 'claim @(1) goes to BURN').

fulfilled(C) :- claim(C, preserve, _), check(K, C), passed(K), not refuted(C).
fulfilled(C) :- claim(C, L, _), L \= preserve, check(K, C), passed(K), was_red(K),
                not refuted(C).
under(C) :- current(C), not fulfilled(C).
served(X) :- serves(X, _).
over(X) :- change(X, _), not served(X).
any_under :- under(_).
any_over :- over(_).
any_to_ask :- to_ask(_).
done :- not any_under, not any_over, not any_to_ask.
burn(C) :- contested_twice(C).
burn(C) :- universal(C).
burn(C) :- burn_requested(C).
