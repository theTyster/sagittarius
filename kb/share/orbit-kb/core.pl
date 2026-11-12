% orbit-kb core library (core.pl)
%
% orbit-kb always loads this file first. Then it loads the modules that
% uses/1 in kb.pl names, then kb.pl, then rules.pl. The text is a Prolog
% program that SWI-Prolog runs. `not p` is negation as failure.
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
%   Template  The text that why and whynot print for the predicate. @(1),
%             @(2), ... stand for the arguments by position. Use '' for no
%             template. Do not write #pred lines (lint E17).
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
% helper predicates. The engine makes each declared predicate dynamic, so
% a declared predicate with no clauses fails. A predicate that is not
% declared, or a misspelled name, is lint error E2.
%
% NEGATION
%
% `not p` is negation as failure: it holds when p has no answer. Thus
% "not under(_)" means "there is no under at all". The rules below keep
% their helper forms, which were needed until 2026-11-02, when s(CASP)
% was the second engine (D20):
%
%     any_under :- under(_).
%     done :- not any_under.
%
% The rules must be stratified: no predicate depends on itself through
% not (lint E18).


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
% 0.3.0 (K-A, D30): every ticket has a hypothesis, so hypothesis/3 is a core
% fact (it was a fact of the discovery module). The kind change is for a
% direct build of a document or a configuration, which is no defect, feature,
% or risk (question q_k_a_1).
decl(fact, hypothesis(id, oneof([defect, feature, risk, change]), text),
     'A falsifiable and wide restatement of the request: what must be true when the ticket is done.',
     'hypothesis @(1) is a @(2): @(3)').
% 0.3.0 (K-A, D30 H2): a premise is a condition that the hypothesis takes as
% given. It has two states: checked on the system (and where), or not
% (question q_k_a_2: a premise that the system shows false is a divergence on
% the hypothesis, and the hypothesis is restated).
decl(fact, premise(id, ref(hypothesis), text),
     'A premise of the hypothesis: a condition that it takes as given. Where the premise does not hold, the hypothesis says nothing.',
     '@(1) is a premise of hypothesis @(2): @(3)').
decl(fact, premise_checked(ref(premise), text),
     'The premise was checked on the current system, and where (a file and line, a query, a log).',
     'premise @(1) was checked on the system at @(2)').
decl(fact, no_premises(ref(hypothesis)),
     'The hypothesis takes nothing as given: the record of "Premises: none".',
     'hypothesis @(1) has no premises').
% supersedes/2 takes two claims, or two hypotheses (or, with the project
% module, two decisions, definitions, or rules). The type is ref (any id),
% because one type cannot name all these kinds. orbit-kb checks the kinds:
% a claim and a hypothesis is E4.
decl(fact, supersedes(ref, ref),
     'The first claim replaces the second claim, or the first hypothesis replaces the second hypothesis.',
     '@(1) replaces @(2)').
% 0.3.0 (K-G, D35): a signal of the prompt that fired has a record. Kind is
% one of the six signals; NoticedBy says who noticed it. report drafts the
% Signals field from these facts, the divergence attestations, and the burns.
decl(fact, signal(id, oneof([questions, divergence, built_by_other, burn, handoff, effort]), oneof([agent, system1, human]), text),
     'A signal that fired: which of the six signals, who noticed it (the agent, System 1, or the human), and what differed.',
     'signal @(1) (@(2)) fired, noticed by @(3): @(4)').
decl(fact, lean_back(id, text),
     'A lean back: what stopped, and what stays active. report prints it under Signals.',
     'the agent leaned back (@(1)): @(2)').
% 0.3.0 (K-J, D39): orbit-kb withdraw writes the record of a kind that it removed.
decl(fact, withdrawn(term, by, time, int),
     'orbit-kb withdraw removed this kind (NAME/ARITY) from kb.pl: who, when, and how many facts. The removed lines stay in kb.pl as comments.',
     'the kind @(1) was withdrawn by @(2) at @(3) (@(4) facts)').
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
% D30 H3: a question can hang on a hypothesis. Its default is a default of the
% hypothesis that the agent marks, such as the scope "every screen".
decl(fact, question(id, ref([claim, hypothesis]), text),
     'A dormant question about a claim, or about a default of the hypothesis.',
     '@(1) is a question about @(2): @(3)').
decl(fact, assumed(ref(question), term),
     'The default answer to a question.',
     'the default answer to question @(1) is @(2)').
decl(fact, option(ref(question), text, text),
     'An option of a question, and what choosing it changes (D24).',
     'option @(2) of question @(1) changes: @(3)').
decl(fact, answer(ref(question), term, alt([human, agent, oneof([human]):atom])),
     'An answer to a question, and who gave it: human, agent, or human:NAME for a pinned answer that NAME gave (T27).',
     '@(3) answered question @(1) with @(2)').
% T27: who owns a question (u58), and the pins of a question and of its answer.
decl(fact, question_pin(ref(question), oneof([ledger, tracker]), atom, digest, time),
     'The question is owned by a ledger ask or a tracker item (the ref); the digest is of the question text when it was pinned. Only orbit-kb pin-question writes it.',
     'question @(1) is owned by the @(2) item @(3), pinned at @(5)').
decl(fact, answer_pin(ref(question), atom, digest, time),
     'The answer of the question was copied from its owner (the ref); the digest is of the answer text. Only orbit-kb pin-answer and the question server write it.',
     'the answer of question @(1) was pinned from @(2) at @(4)').
% T27: the request is pinned to its tracker item (u84, u52).
decl(fact, request_pin(ref(request), atom, digest, time),
     'A reading of the tracker item of the request: its ref, the digest of its request text (title, description, acceptance criteria), and the date. Only orbit-kb init --source and pin-request write it.',
     'request @(1) was read from @(2) at @(4)').
decl(fact, request_accepted(ref(request), digest, text),
     'A human accepted a new text of the request: its digest, and the text (the cached snapshot). Only orbit-kb pin-request --accept --by human writes it.',
     'a human accepted a new text of request @(1)').
decl(rule, request_stale(ref(request)),
     'The latest reading of the tracker item has a request text that is not the one in the KB, and no human accepted it. orbit-kb computes it when it reads the KB.',
     'the text of request @(1) changed at its source').
decl(rule, any_request_stale,
     'A request of the KB is stale.',
     'a request of the KB is stale').
% D22: the item is due at the time. A past due time blocks an open item.
decl(fact, due(ref([claim, check, question]), time),
     'The claim, check, or question is due at the time.',
     '@(1) is due at @(2)').
% D22: orbit-kb add writes it when a fact declares its predicate by its first use.
decl(fact, first_use(term, by, time),
     'The predicate Name/Arity was declared by its first use in orbit-kb add, by the writer, at the time.',
     'predicate @(1) was declared by its first use, by the @(2) at @(3)').
decl(fact, note(ref, text),
     'A free-text note about any id.',
     'a note on @(1) says @(2)').
decl(fact, subject(id, text, digest),
     'An artifact path and its sha256 digest; a relative path starts at the KB directory.',
     'subject @(1) is @(2) with digest @(3)').
decl(fact, attest(id, atom, ref, attest_predicate, by, time),
     'An attestation with its id, type, subject, predicate, writer, and time.',
     'attestation @(1) of type @(2) records @(4) about @(3), by the @(5) at @(6)').
% D28 (T25): who made a record, and what a reviewer saw. Only the commands
% write these facts (add refuses them). The role is self-reported.
decl(fact, actor(ref, atom, atom),
     'Who made the record: its role (from --as or ORBIT_KB_ROLE) and its session (the writer of the KB, T27). orbit-kb writes it with each attestation and each change.',
     '@(1) was made by role @(2) in session @(3)').
decl(fact, review_saw(atom, oneof([ticket, kb, diff]), digest),
     'What a reviewer saw when the review started: the ticket file, the KB (its spec-kb stamp), and the diff. Only orbit-kb review start writes it.',
     'reviewer @(1) saw the @(2) with digest @(3)').
decl(fact, rests_on_run(ref(attest), ref(attest)),
     'The verdict rests on the run: a test_result attestation that the reviewer read or ran.',
     'verdict @(1) rests on run @(2)').

% ---------------------------------------------------------------------
% Core rule predicates
% ---------------------------------------------------------------------

decl(rule, superseded(ref),
     'Another claim replaces the claim, or another hypothesis replaces the hypothesis.',
     '@(1) is superseded').
decl(rule, current(ref(claim)),
     'The claim is in force, because no other claim replaces it.',
     'claim @(1) is current').
decl(fact, writer_takeover(atom, atom, time),
     'A writer took the lock of the KB from another writer: with --take, or because the lease of the holder lapsed (T27).',
     '@(2) took the writer lock from @(1) at @(3)').
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
     'Ask this question now, because no human answered it, no human waived it, and its claim is current and contested.',
     'question @(1) must be asked now').
decl(rule, question_waived(ref(question)),
     'A human waived the question, and the due time of the waiver is not past. The build module adds the clause.',
     'a human waived question @(1)').
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
decl(rule, supersedes_closure(ref, ref),
     'The first claim or hypothesis replaces the second through one or more supersedes facts. orbit-kb computes it when it reads the KB.',
     '@(1) replaces @(2), directly or through others').
decl(rule, supersede_cycle(ref),
     'The claim or hypothesis replaces itself through one or more supersedes facts. orbit-kb computes it when it reads the KB.',
     '@(1) is in a supersede cycle').
decl(rule, any_supersede_cycle,
     'At least one claim or hypothesis is in a supersede cycle.',
     'some claim or hypothesis is in a supersede cycle').
decl(rule, check_ran(ref(check)),
     'The check has at least one test result.',
     'check @(1) ran').
decl(rule, due_passed(ref),
     'The due time of the item is past, or it is not a valid time. orbit-kb computes it when it reads the KB.',
     'the due time of @(1) is past').
decl(rule, item_open(ref),
     'The item still blocks done: a question to ask, or (build module) a claim that is under or has an open burn or flare, or a check of a claim that is under.',
     '@(1) is still open').
decl(rule, blocking(term),
     'The item blocks done. The term names its kind and its id, such as to_ask(q1) or burn_open(c1).',
     '@(1) blocks done').
decl(rule, any_project_conflict,
     'An item of the project KB blocks this KB: the project KB does not load clean (project_kb_unclean), or a claim pins a fact that is in a contradiction there (project_contradiction). No draft blocks (T43). The project module adds the clauses (D23, D27).',
     'the project KB blocks this KB (project_kb_unclean or project_contradiction)').
% D30 H2: the state of a premise, and lint W10.
decl(rule, premise_was_checked(ref(premise)),
     'A premise_checked fact names the premise.',
     'premise @(1) was checked on the system').
decl(rule, premise_unchecked(ref(premise)),
     'The premise of a hypothesis that no other hypothesis replaces was not checked on the system. It is a guess about the system.',
     'premise @(1) was not checked on the system').
decl(rule, premises_stated(ref(hypothesis)),
     'The hypothesis has a premise, or the record no_premises.',
     'the premises of hypothesis @(1) are stated').
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
            verdict(ref(claim), alt([refuted(text), upheld(text), inconclusive(text), abstained(text),
                                     inconclusive, abstained])),
            [agent],
            'The verdict of an attempt to break a claim. The text says what was tried; a refuted verdict carries the counterexample. upheld: the attempt did not break the claim. The bare inconclusive and abstained are for old KBs.').
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
answered(Q) :- answer(Q, _, human:_).
defeated(Q) :- assumed(Q, A), answer(Q, B, human), A \= B.
defeated(Q) :- assumed(Q, A), answer(Q, B, human:_), A \= B.
refuted(C) :- attest(_, _, _, verdict(C, refuted(_)), _, _).
contested(C) :- attest(_, divergence, _, claim(C), _, _).
contested_twice(C) :- attest(D1, divergence, _, claim(C), _, _),
                      attest(D2, divergence, _, claim(C), _, _), D1 \= D2.
% D22: a question whose prerequisite is defeated has no clause here any more.
to_ask(Q) :- question(Q, C, _), current(C), contested(C), not answered(Q),
             not question_waived(Q).
% question_waived/1 has no clause here. The build module adds it (D13):
% a waiver attestation is a type of that module.
any_to_ask :- to_ask(_).
stale(A) :- attest(A, approval, S, digest(D0), human, _), subject(S, _, D1), D0 \= D1.
passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after(K, R).
failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _),
              attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
% supersedes_closure/2 and supersede_cycle/1 have no clauses here. When
% orbit-kb reads the KB, it adds their facts: the transitive closure of
% the supersedes/2 facts of kb.pl, and each claim that reaches itself.
% Thus no rule recurses through supersedes/2, and the engine finishes on
% every KB. Lint E15 reports a cycle.
any_supersede_cycle :- supersede_cycle(_).
% D22: blocking(X) lists each item that blocks done. done does not read it.
% The build module adds the kinds of its own rules. due_passed/1 has no
% clauses here: orbit-kb adds its facts when it reads the KB, as for
% waiver_lapsed/1. rules.pl cannot add clauses to these rules (lint E16).
check_ran(K) :- attest(_, test_result, _, result(K, _, _), _, _).
item_open(Q) :- to_ask(Q).
blocking(to_ask(Q)) :- to_ask(Q).
blocking(supersede_cycle(C)) :- supersede_cycle(C).
blocking(past_due(X)) :- due_passed(X), item_open(X).
% T27: request_stale/1 has no clauses here: orbit-kb computes its facts.
blocking(request_stale(R)) :- request_stale(R).
any_request_stale :- request_stale(_).
% lint_issue/3: the core adds W10 below (D30); modules add their own (the module lint hook).
% D30 H2: premises. A premise of a superseded hypothesis is not asked for: it is no
% guess, and W10 does not name its hypothesis.
premise_was_checked(P) :- premise_checked(P, _).
premise_unchecked(P) :- premise(P, H, _), not superseded(H), not premise_was_checked(P).
premises_stated(H) :- premise(_, H, _).
premises_stated(H) :- no_premises(H).
% Review of K-A (finding 9): a premise and the record "Premises: none" on one hypothesis.
lint_issue('W11', H, 'This hypothesis has a premise and also the record no_premises ("Premises: none"). They contradict each other. Restate the hypothesis (a new hypothesis with supersedes) with its premises, or with no_premises only.') :-
    hypothesis(H, _, _), not superseded(H), premise(_, H, _), no_premises(H).
lint_issue('W10', H, 'This hypothesis has no premise and no record "Premises: none". Add premise(P, H, Text) for each condition that it takes as given, or no_premises(H).') :-
    hypothesis(H, _, _), not superseded(H), not premises_stated(H).
