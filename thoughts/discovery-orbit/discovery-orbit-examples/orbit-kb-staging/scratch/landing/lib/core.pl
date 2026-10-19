% orbit-kb core library (core.pl)
%
% orbit-kb always loads this file first. Then it loads the modules that
% uses/1 in kb.pl names, then kb.pl, then rules.pl. The text is s(CASP)
% source. SWI-Prolog can read it with the s(CASP) operators.
%
% FILE FORMAT
%
% decl(Kind, Head, Doc, Template) declares one predicate.
%   Kind      fact or rule. A fact predicate gets ground facts in kb.pl
%             only. A rule predicate gets clauses in library files or in
%             rules.pl only. A fact for a rule predicate is an error.
%   Head      Name(Type1, ..., TypeN), or Name alone for no arguments.
%             The types are id, ref(Name), ref, oneof(List), alt(Shapes),
%             text, atom, int, time, digest, by, term, attest_predicate.
%   Doc       One plain sentence.
%   Template  The text for the #pred line. @(1), @(2), ... stand for the
%             arguments by position. Use '' for no template. orbit-kb
%             writes the #pred lines, so do not write them here.
%
% attest_type(Type, Shape, Writers, Doc) declares one attestation type.
%   Shape     The type of the predicate, the 4th argument of attest/6.
%   Writers   A sub-list of [human, agent, script]. [script] means that
%             only orbit-kb run writes this type.
%   Doc       One plain sentence.
%
% Write all text as single-quoted atoms. Do not use double-quoted strings.
%
% EVERY PREDICATE MUST BE DECLARED
%
% Declare every predicate with decl/4. This includes rule predicates and
% helper predicates. orbit-kb adds an empty stub for each declared
% predicate, and it runs s(CASP) with --unknown=error. Thus a predicate
% that is not declared, or a misspelled name, causes an error.
%
% HAZARD H1: A VARIABLE ONLY UNDER not IS EXISTENTIAL
%
% In s(CASP), a variable that occurs only in a not literal means "some
% value", not "every value". Thus "done :- not under(_)." is true even
% when under(c1) is true. A not literal must not hold a variable that
% occurs nowhere else in the clause. This includes _. Lint error E12
% finds this problem. To correct it, put the variable in a helper
% predicate, declare the helper, and negate the helper:
%
%     any_under :- under(_).
%     done :- not any_under.


% ---------------------------------------------------------------------
% Core facts
% ---------------------------------------------------------------------

decl(fact, request(id, text),
     'The request of the human, word for word.',
     'the human made request @(1): @(2)').
decl(fact, ticket(ref(subject)),
     'The subject that holds the ratified ticket.',
     'subject @(1) holds the ratified ticket').
decl(fact, claim(id, oneof([preserve, retire, introduce]), text),
     'A claim about the request, with a label: preserve (it stays true), retire (it becomes false), or introduce (it becomes true).',
     '@(1) is a claim to @(2): @(3)').
decl(fact, cites(ref(claim), text),
     'The text of the request or the ticket that the claim serves.',
     'claim @(1) serves the request text @(2)').
decl(fact, example(ref(claim), text),
     'A concrete case of the claim.',
     'an example of claim @(1) is @(2)').
decl(fact, supersedes(ref(claim), ref(claim)),
     'The first claim replaces the second claim.',
     'claim @(1) replaces claim @(2)').
decl(fact, universal(ref(claim)),
     'The claim says that something is true for every input.',
     'claim @(1) is about every input').
decl(fact, check(id, ref(claim)),
     'An executable check of the claim.',
     '@(1) is a check of claim @(2)').
decl(fact, world(term),
     'A fact about the current state; a state that is not recorded is false.',
     'in the current state, @(1) is true').
decl(fact, source(term, text),
     'Where a world fact was observed, such as a file and line, a configuration key, a query, or a log.',
     'the world fact @(1) was observed at @(2)').
decl(fact, scope(oneof([in, out]), text),
     'An item that is in scope or out of scope.',
     'the scope marks @(2) as @(1)').
decl(fact, risk(id, text),
     'A risk to the work.',
     '@(1) is a risk: @(2)').
decl(fact, assumption(id, text),
     'An assumption that the work relies on.',
     '@(1) is an assumption: @(2)').
decl(fact, not_explored(text),
     'An area that nobody explored.',
     'nobody explored @(1)').
decl(fact, question(id, ref(claim), text),
     'A dormant question about a claim.',
     '@(1) is a question about claim @(2): @(3)').
decl(fact, assumed(ref(question), term),
     'The default answer to a question.',
     'the default answer to question @(1) is @(2)').
decl(fact, answer(ref(question), term, oneof([human, agent])),
     'An answer to a question, and who gave it.',
     'the @(3) answered question @(1) with @(2)').
decl(fact, depends(ref(question), ref(question)),
     'The first question depends on the answer to the second question.',
     'question @(1) depends on question @(2)').
decl(fact, note(ref, text),
     'A free-text note about any id.',
     'a note on @(1) says @(2)').
decl(fact, subject(id, text, digest),
     'An artifact path and its sha256 digest; a relative path starts at the KB directory.',
     'subject @(1) is @(2) with digest @(3)').
decl(fact, attest(id, atom, ref, attest_predicate, by, time),
     'An attestation with its id, type, subject, predicate, writer, and time.',
     'attestation @(1) of type @(2) records @(4) about @(3), by the @(5) at @(6)').

% ---------------------------------------------------------------------
% Core rule predicates
% ---------------------------------------------------------------------

decl(rule, superseded(ref(claim)),
     'Another claim replaces the claim.',
     'claim @(1) is superseded').
decl(rule, current(ref(claim)),
     'The claim is in force, because no other claim replaces it.',
     'claim @(1) is current').
decl(rule, answered(ref(question)),
     'A human answered the question.',
     'a human answered question @(1)').
decl(rule, defeated(ref(question)),
     'A human answer to the question differs from its default answer.',
     'a human answer defeats the default of question @(1)').
decl(rule, refuted(ref(claim)),
     'An attestation gives the verdict refuted for the claim.',
     'claim @(1) is refuted').
decl(rule, contested(ref(claim)),
     'At least one divergence attestation names the claim.',
     'claim @(1) is contested').
decl(rule, contested_twice(ref(claim)),
     'Two or more different divergence attestations name the claim.',
     'claim @(1) is contested two or more times').
decl(rule, to_ask(ref(question)),
     'Ask this question now, because no human answered it, its claim is current, and its claim is contested or a question that it depends on is defeated.',
     'question @(1) must be asked now').
decl(rule, any_to_ask,
     'At least one question must be asked now.',
     'some question must be asked now').
decl(rule, stale(ref(attest)),
     'The approval names a digest that differs from the current digest of its subject.',
     'approval @(1) is stale').
decl(rule, passed(ref(check)),
     'The check passed in a run, and no later run of the check failed.',
     'check @(1) passed with no later fail').
decl(rule, failed_after(ref(check), int),
     'The check failed in a run with a higher number than the given run.',
     'check @(1) failed in a run after run @(2)').
decl(rule, was_red(ref(check)),
     'The check failed in a run before a run in which it passed.',
     'check @(1) failed before it passed').
decl(rule, lint_issue(atom, ref, text),
     'A lint result that a module adds, with a code, an id, and a message.',
     'lint issue @(1) on @(2): @(3)').

% ---------------------------------------------------------------------
% Core attestation types
% ---------------------------------------------------------------------

attest_type(disclosure,
            alt([guess(ref(question)), unverified(text), disagreement(text),
                 out_of_scope(text), self_error(text), other(text)]),
            [agent, human],
            'The writer discloses a guess, an unverified point, a disagreement, an item out of scope, an error of its own, or another point.').
attest_type(divergence,
            alt([claim(ref(claim)), hypothesis(term), model(term)]),
            [human, agent],
            'A view does not agree with a claim, a hypothesis, or a model; a note holds the description.').
attest_type(disproof,
            verdict(ref(claim), oneof([refuted, inconclusive, abstained])),
            [agent],
            'The verdict of an attempt to break a claim.').
attest_type(approval,
            digest(digest),
            [human],
            'A human approves the subject at this digest.').
attest_type(test_result,
            result(ref(check), int, oneof([pass, fail])),
            [script],
            'The result of one numbered run of a check; only orbit-kb run writes it.').

% ---------------------------------------------------------------------
% Core rules
% ---------------------------------------------------------------------

superseded(C) :- supersedes(_, C).
current(C) :- claim(C, _, _), not superseded(C).
answered(Q) :- answer(Q, _, human).
defeated(Q) :- assumed(Q, A), answer(Q, B, human), A \= B.
refuted(C) :- attest(_, _, _, verdict(C, refuted), _, _).
contested(C) :- attest(_, divergence, _, claim(C), _, _).
contested_twice(C) :- attest(D1, divergence, _, claim(C), _, _),
                      attest(D2, divergence, _, claim(C), _, _), D1 \= D2.
to_ask(Q) :- question(Q, C, _), current(C), depends(Q, P), defeated(P), not answered(Q).
to_ask(Q) :- question(Q, C, _), current(C), contested(C), not answered(Q).
any_to_ask :- to_ask(_).
stale(A) :- attest(A, approval, S, digest(D0), human, _), subject(S, _, D1), D0 \= D1.
passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after(K, R).
failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _),
              attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
% lint_issue/3 has no clauses here. Modules add them (the module lint hook).
