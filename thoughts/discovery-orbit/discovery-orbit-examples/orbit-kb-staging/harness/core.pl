% Stand-in for the orbit-kb core.pl, copied from the contract v2.1 for the discovery
% staging harness. The real core.pl belongs to builder A. Docs and templates are mine.
% No stubs here: the runner generates them, as the CLI does.

% --- Core facts ---
decl(fact, request(id, text), 'The words of the human, verbatim.', 'request @(1) says @(2)').
decl(fact, ticket(ref(subject)), 'The subject that holds the ratified ticket.', 'subject @(1) holds the ticket').
decl(fact, claim(id, oneof([preserve, retire, introduce]), text), 'A claim about the request, with its label.', 'claim @(1) is labeled @(2): @(3)').
decl(fact, cites(ref(claim), text), 'The request or ticket text that a claim serves.', 'claim @(1) serves the text @(2)').
decl(fact, example(ref(claim), text), 'A concrete case for a claim.', 'claim @(1) has the example @(2)').
decl(fact, supersedes(ref(claim), ref(claim)), 'A new claim, then the old claim that it replaces.', 'claim @(1) supersedes claim @(2)').
decl(fact, universal(ref(claim)), 'The claim says that something holds for every input.', 'claim @(1) is universal').
decl(fact, check(id, ref(claim)), 'An executable check of a claim.', 'check @(1) tests claim @(2)').
decl(fact, world(term), 'A closed-world fact about the current state.', 'in the current world, @(1) holds').
decl(fact, source(term, text), 'The place where a world fact was observed.', 'world fact @(1) was observed at @(2)').
decl(fact, scope(oneof([in, out]), text), 'An item inside or outside the scope.', 'scope @(1) holds the item @(2)').
decl(fact, risk(id, text), 'A risk of the change.', 'risk @(1) is @(2)').
decl(fact, assumption(id, text), 'An assumption that the work depends on.', 'assumption @(1) is @(2)').
decl(fact, not_explored(text), 'An area that the work did not explore.', 'the work did not explore @(1)').
decl(fact, question(id, ref(claim), text), 'A dormant question about a claim.', 'question @(1) about claim @(2) asks @(3)').
decl(fact, assumed(ref(question), term), 'The default answer to a question.', 'the default answer to question @(1) is @(2)').
decl(fact, answer(ref(question), term, oneof([human, agent])), 'An answer to a question, and who gave it.', 'question @(1) has the answer @(2) from the @(3)').
decl(fact, depends(ref(question), ref(question)), 'A question that depends on another question.', 'question @(1) depends on question @(2)').
decl(fact, note(ref, text), 'A free-text note about any id.', 'the note on @(1) says @(2)').
decl(fact, subject(id, text, digest), 'An artifact path and its sha256 digest.', 'subject @(1) is the file @(2) with digest @(3)').
decl(fact, attest(id, atom, ref, attest_predicate, by, time), 'An attestation with its type, subject, predicate, writer, and time.', 'attestation @(1) of type @(2) on @(3) states @(4), by the @(5) at @(6)').

% --- Core attestation types ---
attest_type(disclosure, alt([guess(ref(question)), unverified(text), disagreement(text), out_of_scope(text), self_error(text), other(text)]), [agent, human], 'Something that the agent tells the human about the work.').
attest_type(divergence, alt([claim(ref(claim)), hypothesis(term), model(term)]), [human, agent], 'Two parties disagree, and a note holds the description.').
attest_type(disproof, verdict(ref(claim), oneof([refuted, inconclusive, abstained])), [agent], 'The result of an attempt to disprove a claim.').
attest_type(approval, digest(digest), [human], 'The human approves the subject at this digest.').
attest_type(test_result, result(ref(check), int, oneof([pass, fail])), [script], 'The result of one run of a check, written by orbit-kb run.').

% --- Core rules ---
decl(rule, superseded(ref(claim)), 'A newer claim replaces this claim.', 'claim @(1) is superseded').
decl(rule, current(ref(claim)), 'A claim that no newer claim replaces.', 'claim @(1) is current').
decl(rule, answered(ref(question)), 'A question that the human answered.', 'the human answered question @(1)').
decl(rule, defeated(ref(question)), 'A question whose human answer differs from its default.', 'the human answer to question @(1) defeats its default').
decl(rule, refuted(ref(claim)), 'An attestation refutes the claim.', 'claim @(1) is refuted').
decl(rule, contested(ref(claim)), 'A divergence names the claim.', 'claim @(1) is contested').
decl(rule, contested_twice(ref(claim)), 'Two divergences name the claim.', 'claim @(1) is contested twice').
decl(rule, to_ask(ref(question)), 'A question that the human must answer now.', 'question @(1) must be asked').
decl(rule, stale(ref(attest)), 'An approval of a subject whose digest changed.', 'approval @(1) is stale').
decl(rule, passed(ref(check)), 'A check whose last result is a pass.', 'check @(1) passed').
decl(rule, failed_after(ref(check), int), 'A check failed in a run after the given run.', 'check @(1) failed after run @(2)').
decl(rule, was_red(ref(check)), 'A check failed before it passed.', 'check @(1) was red before it passed').
decl(rule, lint_issue(atom, term, text), 'A module lint result: a code, the id that it is about, and a message.', 'lint code @(1) on @(2) says @(3)').

superseded(C) :- supersedes(_, C).
current(C) :- claim(C, _, _), not superseded(C).
answered(Q) :- answer(Q, _, human).
defeated(Q) :- assumed(Q, A), answer(Q, B, human), A \= B.
refuted(C) :- attest(_, _, _, verdict(C, refuted), _, _).
contested(C) :- attest(_, divergence, _, claim(C), _, _).
contested_twice(C) :- attest(D1, divergence, _, claim(C), _, _),
                      attest(D2, divergence, _, claim(C), _, _), D1 \= D2.
to_ask(Q) :- depends(Q, P), defeated(P), not answered(Q).
to_ask(Q) :- question(Q, C, _), contested(C), not answered(Q).
stale(A) :- attest(A, approval, S, digest(D0), human, _), subject(S, _, D1), D0 \= D1.
passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after(K, R).
failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _),
              attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
% lint_issue/3 has no core clauses. Modules add them.
