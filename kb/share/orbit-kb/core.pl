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
% 0.8.0 (scientific-method-overhaul, D50): the records of a ticket are a goal, the hypotheses
% under it, and the claims that each hypothesis predicts. hypothesis/3 above is the 0.7.2 form
% of the goal: when orbit-kb reads a KB, each hypothesis/3 fact gives a computed goal/4 fact
% (author agent), and each goal/4 fact gives a computed hypothesis/3 fact, so a query of one
% form answers on every KB (c43). A type ref(hypothesis) also accepts the id of a goal, and
% ref(goal) also accepts the id of a hypothesis/3 fact.
% An author is human, agent, human:NAME or agent:NAME.
decl(fact, goal(id, oneof([defect, feature, risk, change]), alt([human, agent, oneof([human, agent]):atom]), text),
     'The goal of the ticket: what the human hopes to accomplish. It names no avenue. The author is human, agent, human:NAME or agent:NAME.',
     'goal @(1) is a @(2), written by @(3): @(4)').
decl(fact, hypothesis(id, ref(goal), alt([human, agent, oneof([human, agent]):atom]), text),
     'A hypothesis under a goal: a claim about an avenue to the goal. The author is human, agent, human:NAME or agent:NAME.',
     'hypothesis @(1) of goal @(2), written by @(3): @(4)').
decl(fact, supports(ref([goal, hypothesis]), term),
     'The goal supports a goal above it: the id of a goal of this KB, or project(PG) for a goal of the project KB. In a project KB, a supporting hypothesis names its parent hypothesis.',
     '@(1) supports @(2)').
decl(fact, defeating_case(ref(hypothesis), alt([human, agent, oneof([human, agent]):atom]), text),
     'The admissible case that would show the hypothesis false, and who named it. A hypothesis with such a case is tempered.',
     'hypothesis @(1) is false if (named by @(2)): @(3)').
decl(fact, untempered(ref(hypothesis), alt([human, agent, oneof([human, agent]):atom]), text),
     'The human or the agent marks the hypothesis as not tempered, and why.',
     '@(2) marks hypothesis @(1) as not tempered: @(3)').
decl(fact, predicts(ref(hypothesis), ref(claim)),
     'The claim is a prediction of the hypothesis: what must be observable if the hypothesis and its premises hold. A preserve claim is a claim of the goal and has no predicts fact.',
     'hypothesis @(1) predicts claim @(2)').
decl(fact, defeat(id, ref(hypothesis), text),
     'A case defeated the hypothesis. The case stays on the version of the hypothesis that it defeated.',
     'case @(1) defeated hypothesis @(2): @(3)').
decl(fact, adoption_cited(ref(hypothesis), text),
     'The ticket marks the hypothesis as adopted by the human, and cites the words of the human. It is the reading of the writer: alone it adopts nothing. A human adoption, or a human GO vote that comes after it in kb.pl, adopts the hypothesis.',
     'the ticket cites the adoption of hypothesis @(1) by the human: @(2)').
decl(fact, carried(ref, ref(goal)),
     'A record of an older goal (a hypothesis, a claim, or a run attestation) is carried over to the goal that replaced it.',
     '@(1) is carried over to goal @(2)').
% 0.8.0 (stage 2): the description of an experiment. The rules that read these facts
% are in the build module.
decl(fact, procedure(ref(check), text),
     'How the experiment (the check) is carried out. Without it, the procedure is the command of the last run.',
     'the procedure of check @(1) is @(2)').
decl(fact, measurement_premise(id, ref(check), text),
     'A premise of the measurement of the check, such as: the clock is right within 0.2 s.',
     '@(1) is a measurement premise of check @(2): @(3)').
decl(fact, known_when(ref(check), text),
     'What was known when the claim and the assessment rule of the check were chosen.',
     'for check @(1), this was known when the claim and the rule were chosen: @(2)').
decl(fact, unresolved_because(ref(attest), text),
     'What the run could not decide. orbit-kb run writes it with each unresolved test result.',
     'run @(1) is unresolved because @(2)').
decl(fact, case_against(ref(attest), ref(hypothesis)),
     'The case that the human judged not wanted (a judgment attestation) is recorded against the hypothesis that allowed it.',
     'the not-wanted case @(1) is recorded against hypothesis @(2)').
decl(fact, formal_statement(ref(subject), ref(claim)),
     'The subject (a model, a Lean file) states the claim in a formal language.',
     'subject @(1) is a formal statement of claim @(2)').
decl(fact, could_change(ref(subject), text),
     'The decision that the precision of the formal statement could change.',
     'the precision of formal statement @(1) could change: @(2)').
decl(fact, behavior_conflict(id, text),
     'A behavior that no claim names changed or broke (Sound Basis). It is open for review until a current claim names it or a human waives it.',
     '@(1) is a behavior conflict: @(2)').
decl(fact, names(ref(claim), ref(behavior_conflict)),
     'The claim names the behavior of a behavior conflict as a behavior to change.',
     'claim @(1) names the behavior of @(2)').
decl(fact, upgraded(atom, time),
     'The first write of this orbit-kb version to a KB that an older version made, and when. Only orbit-kb writes it.',
     'the KB was upgraded to orbit-kb @(1) at @(2)').
decl(fact, done_before_upgrade(atom, time),
     'The ticket was done by the rules of the version before the upgrade to this version. It stays done. Only orbit-kb writes it.',
     'the ticket was done before the upgrade to orbit-kb @(1) at @(2)').
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
% D70, D71 (scientific-method-overhaul c34): a proposal of System 1. The fact is kept as text: it is
% no record, and no rule reads these two kinds, so they change no answer of done or blocking(X).
decl(fact, proposed(id, oneof([system1]), term, time),
     'A proposal of System 1: a fact, as text or as a term, and when it was proposed. It is not a record and it blocks nothing. orbit-kb propose writes it.',
     'System 1 (@(2)) proposed @(3) as @(1) at @(4)').
decl(fact, proposal_confirmed(ref(proposed), by, time),
     'The agent or the human confirmed a proposal: orbit-kb confirm-proposal added its fact as a record.',
     'proposal @(1) was confirmed by the @(2) at @(3)').
% 0.3.0 (K-J, D39): orbit-kb withdraw writes the record of a kind that it removed.
decl(fact, withdrawn(term, by, time, int),
     'orbit-kb withdraw removed this kind (NAME/ARITY) from kb.pl: who, when, and how many facts. The removed lines stay in kb.pl as comments.',
     'the kind @(1) was withdrawn by @(2) at @(3) (@(4) facts)').
% 0.3.0 (K-F, D40): the facts and the attestation of a model are core (they were facts of
% the discovery module), so a KB that uses build records a model of a claim. The rules that
% read them (model_trusted, has_falsifier, the readiness of discovery) stay in the discovery
% module, and no burn rule reads them: a solver result closes no burn.
decl(fact, model(ref(subject), oneof([smt, tla])),
     'A subject that is a model file, and the tool that checks it.',
     'subject @(1) is a model for @(2)').
decl(fact, model_run(ref(subject), ref(model), digest),
     'A solver log, the model that the solver ran, and the digest of the model file at that run.',
     'log @(1) is a run of model @(2) at digest @(3)').
% 0.11.0 (orbit-front-door c6): a model run reads more than the model file: a harness module, its cfg, other
% modules. orbit model-run records each as a subject and writes this fact. A change of any of them (a new
% digest by orbit subject) makes the run stale (model_old_run).
decl(fact, model_run_file(ref(subject), ref(subject), digest),
     'A file that a model run read besides the model file (a harness module, a cfg, a module), and its digest at that run. orbit model-run writes it.',
     'run @(1) read file @(2) at digest @(3)').
decl(fact, encodes(ref(model), ref(claim)),
     'A model states a claim, so the model can falsify the claim.',
     'model @(1) states claim @(2)').
% 0.3.0 (K-F, D42 K3): a fact of the discovery module before; model_is_derived/1 reads it.
decl(fact, derived_from(ref(model), ref(model)),
     'A target model, then the existing-world model that it changes.',
     'model @(1) is derived from model @(2)').
% 0.3.0 (K-F, D42 K6): the bounds of a run, so that the report shows them beside a result
% that closes a burn.
decl(fact, run_bounds(ref(subject), text),
     'The bounds of a solver or model-checker run (the log): the sizes, the constants, the depth; none for a result with no bound. The report shows them beside a result that closes a burn.',
     'the run @(1) has the bounds @(2)').
decl(fact, universal(ref(claim)),
     'The claim says that something is true for every input.',
     'claim @(1) is about every input').
decl(fact, check(id, ref(claim)),
     'An executable check of the claim.',
     '@(1) is a check of claim @(2)').
% questions-server q8 (Ty, 2026-11-17: both): a check says in words what it checks. The Desk
% shows these words; without them it shows the first line of the check script's docstring, else
% the command of its last run. Lint W12 names a check of a current claim with no words.
decl(fact, checks_that(ref(check), text),
     'What the check checks, in words that a human reads: the Desk shows them.',
     'check @(1) checks that @(2)').
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
% kb-migrations (c2, c16, c17): what a migration wrote into the KB. Only orbit-kb migrate apply
% writes these facts. A version that retires a predicate N/A writes retired(N/A, Version, What)
% beside a first clause N(_, ..., _) :- !, fail. in kb.pl: the facts of N/A stay in kb.pl, and
% the clause takes them out of the model. The KB carries what it retired; the tool does not.
decl(fact, retired(term, atom, term),
     'The predicate Name/Arity was retired by the version, and the term says what replaces it. A cut-fail clause before its facts in kb.pl takes them out of the model (lint WM1).',
     'predicate @(1) was retired in orbit-kb @(2), replaced by @(3)').
decl(fact, migration_added(atom, atom, term),
     'The migration, run by the orbit-kb version, added the fact (the third argument). orbit-kb migrate apply writes one after each fact that it adds.',
     'migration @(1) of orbit-kb @(2) added @(3)').
decl(rule, migration_question(ref(question)),
     'A migration raised the question for a step that only the human can do (kb-migrations c5, c10).',
     'a migration raised question @(1)').

% ---------------------------------------------------------------------
% Core rule predicates
% ---------------------------------------------------------------------

decl(rule, superseded(ref),
     'Another claim replaces the claim, or another hypothesis replaces the hypothesis.',
     '@(1) is superseded').
decl(rule, current(ref(claim)),
     'The claim is in force, because no other claim replaces it.',
     'claim @(1) is current').
% 0.8.0 (scientific-method-overhaul, D50 to D54): the records. The rules are below, under
% "The records". rules.pl cannot add clauses to them (lint E16).
decl(rule, goal_current(ref(goal)),
     'The goal is in force: no other goal replaces it.',
     'goal @(1) is current').
decl(rule, hypothesis_state(ref(hypothesis), oneof([superseded, retired, defeated, adopted, proposed])),
     'The state of a hypothesis under a goal. Exactly one holds, the first that applies in this order: superseded, retired, defeated, adopted, proposed.',
     'hypothesis @(1) is @(2)').
decl(rule, hypothesis_current(ref(hypothesis)),
     'The hypothesis is proposed or adopted, and its goal is current or the hypothesis is carried over to a current goal.',
     'hypothesis @(1) is current').
decl(rule, hypothesis_adopted(ref(hypothesis)),
     'A human adopted the hypothesis (an adoption attestation). The discovery module adds: the human voted GO in a round after the hypothesis was written.',
     'a human adopted hypothesis @(1)').
decl(rule, hypothesis_retired(ref(hypothesis)),
     'A retirement attestation names the hypothesis.',
     'hypothesis @(1) is retired').
decl(rule, hypothesis_defeated(ref(hypothesis)),
     'A recorded case defeated the hypothesis (defeat/3). The build module adds: a confirmed location in the hypothesis or in a premise of it, or a not-wanted case placed against it.',
     'hypothesis @(1) is defeated').
decl(rule, hypothesis_superseded(ref(hypothesis)),
     'Another hypothesis replaces the hypothesis.',
     'hypothesis @(1) is superseded').
decl(rule, hypothesis_out(ref(hypothesis)),
     'The hypothesis is superseded, retired or defeated: it holds nothing up.',
     'hypothesis @(1) is superseded, retired or defeated').
decl(rule, hypothesis_goal_current(ref(hypothesis)),
     'The goal of the hypothesis is current, or the hypothesis is carried over to a current goal.',
     'hypothesis @(1) counts for a current goal').
decl(rule, hypothesis_agent_written(ref(hypothesis)),
     'The author of the hypothesis is agent or agent:NAME.',
     'an agent wrote hypothesis @(1)').
decl(rule, hypothesis_human_written(ref(hypothesis)),
     'The author of the hypothesis is human or human:NAME.',
     'a human wrote hypothesis @(1)').
decl(rule, any_current_hypothesis,
     'At least one hypothesis under a goal is current.',
     'some hypothesis is current').
decl(rule, hypothesis_cited(ref(hypothesis)),
     'The ticket marks the hypothesis as adopted by the human (adoption_cited). Alone it adopts nothing.',
     'the ticket cites the adoption of hypothesis @(1)').
decl(rule, hypothesis_marked_untempered(ref(hypothesis)),
     'An untempered fact names the hypothesis.',
     'someone marked hypothesis @(1) as not tempered').
decl(rule, tempered(ref(hypothesis)),
     'The record of the hypothesis names one admissible case that would show it false (defeating_case/3), and nobody marked it untempered.',
     'hypothesis @(1) is tempered').
decl(rule, not_tempered(ref(hypothesis)),
     'The hypothesis is current and not tempered. Lint W13 lists it.',
     'hypothesis @(1) is current and not tempered').
decl(rule, claim_predicted(ref(claim)),
     'A predicts fact names the claim.',
     'a hypothesis predicts claim @(1)').
decl(rule, claim_of_goal(ref(claim)),
     'The claim has no predicts fact: it hangs on the goal, and holds under every hypothesis.',
     'claim @(1) is a claim of the goal').
decl(rule, claim_under_current(ref(claim)),
     'A current hypothesis predicts the claim.',
     'a current hypothesis predicts claim @(1)').
decl(rule, hypothesis_guess(ref(hypothesis)),
     'An agent wrote the hypothesis, no human adopted it, and it is current. The report lists it under Residual, Wanted.',
     'hypothesis @(1) is a guess: agent-written, not adopted').
decl(rule, record_step(ref, ref),
     'One step up inside the records of the KB: a run to its check, a check to its claim, a claim to its hypothesis or to the current goal, a hypothesis to its goal.',
     '@(1) is one step below @(2)').
decl(rule, record_up(ref, ref),
     'One to four record steps up.',
     '@(1) is below @(2) in the records').
decl(rule, rests_on(ref, term),
     'What a record rests on, one step up: a run on its check, a check on its claim, a claim on its hypothesis (predicts) or on the current goal, a hypothesis on its goal, a goal on what it supports (a goal id, or project(PG)). In a project KB also: a fact rests on a fact that it depends on, through one or more depends_on facts (D27; orbit-kb computes these when it reads the KB).',
     '@(1) rests on @(2)').
decl(rule, rests_above(ref, term),
     'From a goal or a hypothesis: what it rests on through supports facts and the goal of a hypothesis.',
     '@(1) supports @(2), directly or through others').
decl(rule, rests_up(ref, term),
     'What a record rests on, one step or more up: up to the goal, and to the project goal that the goal supports.',
     '@(1) rests on @(2), directly or through others').
decl(rule, supports_closure(ref, term),
     'The first goal or hypothesis reaches the second through one or more supports facts. orbit-kb computes it when it reads the KB.',
     '@(1) supports @(2), directly or through others').
decl(rule, goal_written(ref(goal)),
     'The goal is written as a goal/4 fact in kb.pl (not in the 0.7.2 form hypothesis/3). orbit-kb computes it when it reads the KB.',
     'goal @(1) is written as a goal/4 fact').
decl(rule, retirement_ignored(ref(hypothesis)),
     'An agent retirement of the hypothesis does not count: a human wrote or adopted it, or the ticket marks it as adopted.',
     'an agent retirement of hypothesis @(1) does not count').
decl(rule, supports_missing(ref, atom),
     'The goal names project(PG) in a supports fact, the project KB of project_kb/1 can be read, and it holds no goal PG. orbit-kb computes it when it reads the KB. Lint W20.',
     '@(1) supports the project goal @(2), which the project KB does not hold').
decl(rule, goal_supported(ref(goal)),
     'A supports fact names what the goal supports.',
     'goal @(1) names a goal above it').
decl(rule, goal_unsupported(ref(goal)),
     'The goal is current and names no goal above it (no supports fact). Lint W14 lists it. It blocks nothing.',
     'goal @(1) is current and names no goal above it').
decl(rule, made_by_new,
     'The KB was made by orbit-kb 0.8.0 or later: its first "Made by" line names that version or a later one. orbit-kb computes it when it reads the KB. A KB of an older version gets no lint W14 and no lint W16.',
     'the KB was made by orbit-kb 0.8.0 or later').
decl(rule, claim_unplaced(ref(claim)),
     'The claim is current, it is no preserve claim, and no hypothesis predicts it, in a KB made by orbit-kb 0.8.0 or later that has a current hypothesis. Lint W16 lists it.',
     'claim @(1) is not placed under a hypothesis').
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
decl(rule, any_project_conflict_072,
     'any_project_conflict, with no step through blocking/1: done_072 reads it (D57). The project module adds the clauses.',
     'the project KB blocks this KB').
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

% 0.3.0 (K-F, D42 K3): the rules of trust of a model (moved from the discovery module).
decl(rule, model_sanity_ok(atom), 'A result that passes a sanity check.', '@(1) passes a sanity check').
decl(rule, model_decided_result(atom), 'A solver result that is not unknown.', '@(1) is a decided result').
decl(rule, model_shows_case(atom), 'A solver result that shows a case.', '@(1) shows a case').
decl(rule, model_shows_no_case(atom), 'A solver result that shows no case.', '@(1) shows no case').
decl(rule, model_old_run(ref(subject), ref(model)), 'The log has a run of the model at a digest that is not the current one.', 'log @(1) has a run of an older digest of model @(2)').
decl(rule, model_run_current(ref(subject), ref(model)), 'The log is a run of the model at its current digest, and at no older digest.', 'log @(1) is a current run of model @(2)').
decl(rule, model_run_stale(ref(subject), ref(model)), 'The log is a run of the model at an older digest.', 'log @(1) is an old run of model @(2)').
decl(rule, model_verdict(ref(attest), ref(model), term, atom), 'A verdict that counts: its attestation, model, check, and result.', 'attestation @(1) gives model @(2) the result @(4) on check @(3)').
decl(rule, model_calibration(ref(attest), ref(model), atom), 'A calibration that counts: its attestation, model, and result.', 'attestation @(1) gives model @(2) the calibration result @(3)').
decl(rule, model_has_parent(ref(model)), 'The model is derived from some model.', 'model @(1) is derived from a model').
decl(rule, model_root(ref(model)), 'The model is an existing-world model: it is derived from no model.', 'model @(1) is an existing-world model').
decl(rule, model_is_derived(ref(model)), 'The model is a target model derived from an existing-world model.', 'model @(1) is a target model').
decl(rule, model_sane(ref(model)), 'A sanity check of the model passed, and none failed.', 'model @(1) is sane').
decl(rule, model_sanity_failed(ref(model)), 'A sanity check of the model failed or was unknown.', 'a sanity check of model @(1) failed').
decl(rule, model_calibration_case(ref(model), oneof([fails, passes])), 'A matching calibration on a current run of the model: a real case where the system fails, or one where it passes (D33 R4).', 'model @(1) matches the current system on a real case where it @(2)').
decl(rule, model_calibrated(ref(model)), 'The model matches the current system on a real case where the system fails and on a real case where it passes (D33 R4).', 'model @(1) matches the current system on a failing case and on a passing case').
decl(rule, model_diverges(ref(model)), 'The model disagrees with the current system.', 'model @(1) disagrees with the current system').
decl(rule, model_trusted(ref(model)), 'The model is sane, calibrated by its own two cases, and does not diverge. A derived model needs its own two cases (D33 R4).', 'model @(1) is trusted').
decl(rule, model_decided(ref(model), ref(claim)), 'A check of the model that names the claim gave a decided result.', 'model @(1) decided a check of claim @(2)').
decl(rule, model_breaks(ref(model), ref(claim)), 'The model shows a case that breaks the claim.', 'model @(1) breaks claim @(2)').

% ---------------------------------------------------------------------
% Core attestation types
% ---------------------------------------------------------------------

% 0.3.0 (K-F, D40): a core type, as model/2.
% verdict/3 has three arguments, so the core refuted/1 never reads it.
attest_type(model_result,
    alt([verdict(ref(model),
                 alt([sanity, bad_case, together, root_cause(atom), normal_case(atom),
                      preserve(ref(claim)), applies(ref(claim)), explore(term)]),
                 oneof([sat, unsat, unknown, reached, violated, holds])),
         calibration(ref(model), alt([fails(text), passes(text), example(ref(claim)), case(text)]), oneof([matches, differs])),
         mutation(ref(model), atom, oneof([killed, survived]))]),
    [agent, human],
    'The result of one check on a model, read from the log of the solver run. A calibration names a real case where the system fails (fails), or one where it passes (passes); example and case are the older forms, and they calibrate nothing (D33).').
attest_type(disclosure,
            alt([guess(ref(question)), unverified(text), disagreement(text),
                 out_of_scope(text), self_error(text), other(text),
                 seen_red(ref(check), text)]),
            [agent, human],
            'The writer discloses a guess, an unverified point, a disagreement, an item out of scope, an error of its own, or another point. seen_red(K, Output): the agent saw check K fail before the KB existed (orbit-kb shift --red-log, D43); it is not a test result, and the tool did not show K red.').
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
% 0.8.0 (D55, claim c7): a run has three results. pass is the verdict meets, fail is conflicts,
% and unresolved says that the run could not decide (unresolved_because/2 holds the reason).
attest_type(test_result,
            result(ref(check), int, oneof([pass, fail, unresolved])),
            [script],
            'The result of one numbered run of a check; only orbit-kb run writes it. pass: the verdict meets. fail: it conflicts. unresolved: the run could not decide (unresolved_because/2 says why).').
% 0.8.0 (D50, D52): the human adopts a hypothesis; a hypothesis is retired.
attest_type(adoption,
            adopted,
            [human],
            'The human adopts the hypothesis (the subject).').
attest_type(retirement,
            retired(text),
            [human, agent],
            'The hypothesis (the subject) is retired, and why. An agent retires only a hypothesis that an agent wrote and no human adopted.').
% 0.8.0 (stage 2): the rules that read these types are in the build module.
attest_type(measurement,
            false(text),
            [human, agent],
            'The measurement premise (the subject) was found false. Each run of its check at or before that time is unresolved.').
attest_type(location,
            located(alt([build, measurement, premise(ref(premise)), hypothesis(ref(hypothesis)), claim(ref(claim))]), text),
            [human, agent],
            'Where the conflict of a run (the subject, a test_result attestation) lies, with the evidence: in the build, in the measurement, in a premise, in a hypothesis, or in a claim of the goal.').
attest_type(confirmation,
            confirms(text),
            [human, agent],
            'A pane that did not build, or the human, confirms a location (the subject, a location attestation).').
attest_type(judgment,
            alt([case(text, oneof([wanted, not_wanted])), satisfied, not_satisfied, accepts(ref(claim))]),
            [human],
            'A judgment of the human. On the goal (the subject): a concrete case that is wanted or not wanted, or the goal as a whole (satisfied, not_satisfied). On a formal statement (the subject): accepts(C), it says what claim C means.').

% ---------------------------------------------------------------------
% Core rules
% ---------------------------------------------------------------------

superseded(C) :- supersedes(_, C).
% 0.8.0 (D51, c37, c38): a claim is current when no claim replaces it, and it is a claim of the
% goal (no predicts fact) or a current hypothesis predicts it. In a KB with no predicts fact
% (each KB of 0.7.2) this is the rule of 0.7.2.
% 0.8.0 (D61, c42): after a change of the goal, a claim of the goal that stands before the new goal
% in kb.pl is current only when a record carries it over (carried/2).
current(C) :- claim(C, _, _), not superseded(C), claim_of_goal(C), not claim_not_carried(C).
claim_not_carried(C) :- claim(C, _, _), before_goal(C, G), goal_current(G), not carried(C, G).
current(C) :- claim(C, _, _), not superseded(C), claim_under_current(C).
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
% kb-migrations c10: the question of a human step of a migration is asked until a human answers
% it, so the KB is not done (and not discovery_ready) while it waits.
migration_question(Q) :- migration_added(_, _, question(Q, _, _)), question(Q, _, _).
to_ask(Q) :- migration_question(Q), not answered(Q), not question_waived(Q).
% question_waived/1 has no clause here. The build module adds it (D13):
% a waiver attestation is a type of that module.
any_to_ask :- to_ask(_).
stale(A) :- attest(A, approval, S, digest(D0), human, _), subject(S, _, D1), D0 \= D1.
% 0.8.0 (D55, c7): a later unresolved run takes the pass away too, as a later fail does. In a KB
% with only pass and fail runs the answer is the one of 0.7.2.
passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after(K, R),
             not unresolved_after(K, R).
failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
unresolved_after(K, R) :- attest(_, test_result, _, result(K, R2, unresolved), _, _), R2 > R.
was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _),
              attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
% 0.3.0 (K-F, D42 K3): the rules of trust of a model, moved from the discovery module, so that
% a burn of a build KB can read a model (burn_model_closed/1 of the build module). Their meaning
% did not change; the helpers discovery_* were renamed model_*. E16 protects them.
% A verdict counts only for the current digest of its own model: a log that also has a run at an
% older digest does not count, so reusing a log for a new digest does not bring old verdicts back.
model_old_run(S, M) :- model_run(S, M, D), subject(M, _, D1), D \= D1.
model_old_run(S, M) :- model_run(S, M, _), model_run_file(S, F, D), subject(F, _, D1), D \= D1.
model_run_current(S, M) :- model_run(S, M, D), subject(M, _, D), not model_old_run(S, M).
model_run_stale(S, M) :- model_run(S, M, _), not model_run_current(S, M).
model_verdict(A, M, K, R) :- attest(A, model_result, S, verdict(M, K, R), _, _), model_run_current(S, M).
model_calibration(A, M, R) :- attest(A, model_result, S, calibration(M, _, R), _, _), model_run_current(S, M).
model_sanity_ok(sat).
model_sanity_ok(reached).
model_sanity_ok(violated).
model_decided_result(sat).
model_decided_result(unsat).
model_decided_result(reached).
model_decided_result(violated).
model_decided_result(holds).
model_shows_case(sat).
model_shows_case(reached).
model_shows_case(violated).
model_shows_no_case(unsat).
model_shows_no_case(holds).
% --- Trust: sane, calibrated, and no divergence from the current system ---
model_sanity_failed(M) :- model_verdict(_, M, sanity, R), not model_sanity_ok(R).
model_sane(M) :- model_verdict(_, M, sanity, R), model_sanity_ok(R), not model_sanity_failed(M).
% D33 R4: two matching cases on a current run, one where the system fails and one where it
% passes. The older case forms (example, case) calibrate nothing.
model_calibration_case(M, fails) :- attest(_, model_result, S, calibration(M, fails(_), matches), _, _), model_run_current(S, M).
model_calibration_case(M, passes) :- attest(_, model_result, S, calibration(M, passes(_), matches), _, _), model_run_current(S, M).
model_calibrated(M) :- model_calibration_case(M, fails), model_calibration_case(M, passes).
% A target is derived from a root. A model in a derived_from cycle is no target, so it
% gets the existing-world bad-case check (ED9 flags the cycle).
model_has_parent(M) :- derived_from(M, _).
model_root(M) :- model(M, _), not model_has_parent(M).
model_is_derived(M) :- derived_from(M, M0), model_root(M0).
model_diverges(M) :- model_calibration(_, M, differs).
% A model divergence counts on any subject, except a log of an older digest of the model.
model_diverges(M) :- attest(_, divergence, S, model(M), _, _), not model_run_stale(S, M).
% The existing-world model must reproduce the reported bad case.
model_diverges(M) :- model_verdict(_, M, bad_case, R), model_shows_no_case(R), not model_is_derived(M).
% D33 R4: a target model no longer inherits the trust of the model that it changes. It
% needs its own two cases.
model_trusted(M) :- model_sane(M), model_calibrated(M), not model_diverges(M).
model_decided(M, C) :- model_verdict(_, M, preserve(C), R), model_decided_result(R).
model_decided(M, C) :- model_verdict(_, M, applies(C), R), model_decided_result(R).
model_breaks(M, C) :- model_verdict(_, M, preserve(C), R), model_shows_case(R).
model_breaks(M, C) :- model_verdict(_, M, bad_case, R), model_shows_case(R),
    model_is_derived(M), encodes(M, C), claim(C, introduce, _).
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
premise_unchecked(P) :- premise(P, H, _), not superseded(H), not hypothesis_out(H), not premise_was_checked(P).
premises_stated(H) :- premise(_, H, _).
premises_stated(H) :- no_premises(H).
% Review of K-A (finding 9): a premise and the record "Premises: none" on one hypothesis.
lint_issue('W11', H, 'This hypothesis has a premise and also the record no_premises ("Premises: none"). They contradict each other. Restate the hypothesis (a new hypothesis with supersedes) with its premises, or with no_premises only.') :-
    hypothesis(H, _, _), not goal_written(H), not superseded(H), premise(_, H, _), no_premises(H).
lint_issue('W11', G, 'This goal has a premise and also the record no_premises ("Premises: none"). They contradict each other. Restate the goal (a new goal with supersedes) with its premises, or with no_premises only.') :-
    goal_written(G), not superseded(G), premise(_, G, _), no_premises(G).
lint_issue('W11', H, 'This hypothesis has a premise and also the record no_premises ("Premises: none"). They contradict each other. Add a new hypothesis with supersedes, with its premises, or with no_premises only.') :-
    hypothesis_current(H), premise(_, H, _), no_premises(H).
lint_issue('W12', K, 'This check of a current claim does not say in words what it checks. Add checks_that(K, Text): one line that a human reads (the Desk shows it).') :-
    check(K, C), not superseded(C), not checks_that(K, _).
lint_issue('W10', H, 'This hypothesis has no premise and no record "Premises: none". Add premise(P, H, Text) for each condition that it takes as given, or no_premises(H).') :-
    hypothesis(H, _, _), not goal_written(H), not superseded(H), not premises_stated(H).
lint_issue('W10', G, 'This goal has no premise and no record "Premises: none". Add premise(P, G, Text) for each condition that it takes as given, or no_premises(G).') :-
    goal_written(G), not superseded(G), not premises_stated(G).
lint_issue('W10', H, 'This hypothesis has no premise and no record "Premises: none". Add premise(P, H, Text) for each condition that it takes as given, or no_premises(H).') :-
    made_by_new, hypothesis_current(H), not premises_stated(H).

% ---------------------------------------------------------------------
% The records (0.8.0, D50 to D54): goal, hypotheses, predictions
% ---------------------------------------------------------------------
% When orbit-kb reads the KB it adds: goal(Id, Kind, agent, Text) for each hypothesis/3 fact of
% kb.pl, hypothesis(G, Kind, Text) for each goal/4 fact, supports_closure/2 (the closure of the
% supports facts), and made_by_new. No rule recurses, so the engine finishes on every KB.
goal_current(G) :- goal(G, _, _, _), not superseded(G).
hypothesis_superseded(H) :- hypothesis(H, _, _, _), superseded(H).
hypothesis_agent_written(H) :- hypothesis(H, _, agent, _).
hypothesis_agent_written(H) :- hypothesis(H, _, agent:_, _).
hypothesis_human_written(H) :- hypothesis(H, _, human, _).
hypothesis_human_written(H) :- hypothesis(H, _, human:_, _).
% D52: only a human adopts. The discovery module adds the clause of the GO vote.
hypothesis_adopted(H) :- hypothesis(H, _, _, _), attest(_, adoption, H, adopted, human, _).
% D52 (c37): the retirement of an agent counts only for a hypothesis that an agent wrote, that
% no human adopted, and that the ticket does not mark as adopted (adoption_cited).
hypothesis_retired(H) :- hypothesis(H, _, _, _), attest(_, retirement, H, _, human, _).
hypothesis_retired(H) :- attest(_, retirement, H, _, agent, _), hypothesis_agent_written(H),
                         not hypothesis_adopted(H), not hypothesis_cited(H).
hypothesis_cited(H) :- adoption_cited(H, _).
hypothesis_defeated(H) :- hypothesis(H, _, _, _), defeat(_, H, _).
hypothesis_out(H) :- hypothesis_superseded(H).
hypothesis_out(H) :- hypothesis_retired(H).
hypothesis_out(H) :- hypothesis_defeated(H).
hypothesis_state(H, superseded) :- hypothesis_superseded(H).
hypothesis_state(H, retired) :- hypothesis_retired(H), not hypothesis_superseded(H).
hypothesis_state(H, defeated) :- hypothesis_defeated(H), not hypothesis_superseded(H), not hypothesis_retired(H).
hypothesis_state(H, adopted) :- hypothesis_adopted(H), not hypothesis_out(H).
hypothesis_state(H, proposed) :- hypothesis(H, _, _, _), not hypothesis_adopted(H), not hypothesis_out(H).
hypothesis_goal_current(H) :- hypothesis(H, G, _, _), goal_current(G).
hypothesis_goal_current(H) :- hypothesis(H, _, _, _), carried(H, G), goal_current(G).
hypothesis_current(H) :- hypothesis(H, _, _, _), not hypothesis_out(H), hypothesis_goal_current(H).
any_current_hypothesis :- hypothesis_current(_).
tempered(H) :- defeating_case(H, _, _), not hypothesis_marked_untempered(H).
hypothesis_marked_untempered(H) :- untempered(H, _, _).
not_tempered(H) :- hypothesis_current(H), not tempered(H).
claim_predicted(C) :- predicts(_, C).
claim_of_goal(C) :- claim(C, _, _), not claim_predicted(C).
claim_under_current(C) :- predicts(H, C), hypothesis_current(H).
hypothesis_guess(H) :- hypothesis_agent_written(H), hypothesis_current(H), not hypothesis_adopted(H).
% D53 (c38): what a record rests on. record_step/2 has at most four steps (a run, a check, a
% claim, a hypothesis, a goal), so record_up/2 is written out.
record_step(A, K) :- attest(A, test_result, _, result(K, _, _), _, _).
record_step(K, C) :- check(K, C).
record_step(C, H) :- predicts(H, C).
record_step(C, G) :- claim_of_goal(C), goal_current(G).
record_step(H, G) :- hypothesis(H, G, _, _).
record_up(X, Y) :- record_step(X, Y).
record_up(X, Y) :- record_step(X, Z), record_step(Z, Y).
record_up(X, Y) :- record_step(X, Z1), record_step(Z1, Z2), record_step(Z2, Y).
record_up(X, Y) :- record_step(X, Z1), record_step(Z1, Z2), record_step(Z2, Z3), record_step(Z3, Y).
rests_on(X, Y) :- record_step(X, Y).
rests_on(G, R) :- supports(G, R).
rests_above(X, Y) :- supports_closure(X, Y).
rests_above(X, Y) :- supports_closure(X, H), hypothesis(H, Y, _, _).
rests_above(X, Y) :- supports_closure(X, H), hypothesis(H, G, _, _), supports_closure(G, Y).
rests_up(X, Y) :- rests_on(X, Y).
rests_up(X, Y) :- record_up(X, Y).
rests_up(X, Y) :- rests_above(X, Y).
rests_up(X, Y) :- record_up(X, Z), rests_above(Z, Y).
goal_supported(G) :- supports(G, _).
goal_unsupported(G) :- goal_current(G), not goal_supported(G).
claim_unplaced(C) :- made_by_new, any_current_hypothesis, claim(C, L, _), L \= preserve,
                     not superseded(C), claim_of_goal(C).
lint_issue('W13', H, 'This current hypothesis is not tempered: its record names no admissible case that would show it false, or someone marked it untempered. Add defeating_case(H, By, Text): one case that would defeat it. To replace it, add a new hypothesis and supersedes(New, H).') :-
    not_tempered(H).
lint_issue('W14', G, 'This goal names no goal above it. Add supports(G, project(PG)) for the project goal that it supports, or supports(G, G2) for a goal of this KB. It blocks nothing.') :-
    made_by_new, goal_unsupported(G).
lint_issue('W15', C, 'Two current hypotheses predict this claim. A claim is a prediction of one hypothesis. Keep one predicts fact, or make it a claim of the goal (no predicts fact).') :-
    predicts(H1, C), predicts(H2, C), H1 \= H2, hypothesis_current(H1), hypothesis_current(H2).
lint_issue('W16', C, 'This claim is not placed: the KB has a current hypothesis, and no hypothesis predicts the claim. Add predicts(H, C) for the hypothesis that it is a prediction of. A claim that must hold under every hypothesis is a preserve claim.') :-
    claim_unplaced(C).


% =====================================================================
% 0.8.0, stage 2: experiments and verdicts (D55 to D62; claims c6, c7, c39)
% =====================================================================
% One view for every kind of evidence. An experiment is one test of one claim, and it has
% exactly one verdict: meets, conflicts, or unresolved (the definition Warrants of
% ScientificMethod.lean). The build module adds the kinds proof and demo, the rules that read a
% change (verdict_stale/2, control/1), and the location of a conflict.
% rules.pl cannot add clauses to these rules (lint E16).

decl(rule, unresolved_after(ref(check), int),
     'The check was unresolved in a run with a higher number than the given run.',
     'check @(1) was unresolved in a run after run @(2)').
decl(rule, record_line(ref, int),
     'The line of kb.pl that holds the record (an attestation, a change, a goal). orbit-kb computes it when it reads the KB. A record on a higher line was written later.',
     'record @(1) is on line @(2) of kb.pl').
decl(rule, before_goal(ref, ref),
     'The record (a hypothesis, a claim, or a run) stands before the fact of the goal in kb.pl, and the goal replaces an older goal. orbit-kb computes it when it reads the KB.',
     '@(1) was recorded before goal @(2) replaced the older goal').
decl(rule, claim_not_carried(ref(claim)),
     'The claim stands before the current goal in kb.pl, the goal replaced an older goal, and no carried fact carries the claim over. It is not current.',
     'claim @(1) is not carried over to the current goal').
decl(rule, upgrade_line(int),
     'The line of kb.pl that holds the first upgraded/2 fact. orbit-kb computes it when it reads the KB.',
     'the upgrade is recorded on line @(1) of kb.pl').
decl(rule, later_run(ref(check), int),
     'The check has a run with a higher number than the given run.',
     'check @(1) has a run after run @(2)').
decl(rule, latest_run(ref(check), ref(attest)),
     'The attestation is the run of the check with the highest number.',
     'run @(2) is the latest run of check @(1)').
decl(rule, run_voided(ref(attest)),
     'The run does not count as observed: a measurement premise of its check was found false after it, or a confirmed location places its conflict in the measurement.',
     'the measurement of run @(1) does not stand').
decl(rule, experiment(ref(attest), oneof([test, model, proof, demo, judgment]), ref),
     'The attestation is an experiment of the claim (for a judgment of the goal: of the goal). Kind: a test run, a counted model result, a Lean proof, the approval of a demo, or a judgment of the human.',
     '@(1) is an experiment (@(2)) of @(3)').
decl(rule, verdict(ref(attest), oneof([meets, conflicts, unresolved])),
     'The verdict of the experiment. Exactly one holds for each experiment.',
     'the verdict of experiment @(1) is @(2)').
decl(rule, model_tests_intro(ref(model)),
     'The model is a target model that encodes an introduce claim: its bad_case check tests that claim.',
     'the bad case of model @(1) tests an introduce claim').
decl(rule, check_unresolved(ref(check)),
     'The verdict of the latest run of the check is unresolved.',
     'the latest run of check @(1) is unresolved').
decl(rule, kb_before_upgrade,
     'A version of orbit-kb before 0.8.0 made the KB, and no later version wrote to it. orbit-kb computes it when it reads the KB.',
     'the KB is from before the upgrade to 0.8.0').


later_run(K, N) :- attest(_, test_result, _, result(K, N2, _), _, _), N2 > N.
latest_run(K, A) :- attest(A, test_result, _, result(K, N, _), _, _), not later_run(K, N).
% A measurement premise that is found false voids each run of its check that was recorded
% before the finding (D56, c39). The order is the order of kb.pl: the file only grows.
run_voided(A) :- attest(A, test_result, _, result(K, _, _), _, _), measurement_premise(MP, K, _),
                 attest(F, measurement, MP, false(_), _, _),
                 record_line(A, LA), record_line(F, LF), LA < LF.
experiment(A, test, C) :- attest(A, test_result, _, result(K, _, _), _, _), check(K, C).
experiment(A, model, C) :- model_verdict(A, _, preserve(C), _).
experiment(A, model, C) :- model_verdict(A, _, applies(C), _).
experiment(A, model, C) :- model_verdict(A, M, bad_case, _), model_is_derived(M), encodes(M, C),
                           claim(C, introduce, _).
experiment(A, judgment, C) :- attest(A, judgment, _, accepts(C), human, _).
experiment(A, judgment, G) :- attest(A, judgment, G, case(_, _), human, _).
experiment(A, judgment, G) :- attest(A, judgment, G, satisfied, human, _).
experiment(A, judgment, G) :- attest(A, judgment, G, not_satisfied, human, _).
% A test run: pass is meets, fail is conflicts, and unresolved stays unresolved. A run whose
% measurement does not stand is unresolved, whatever it showed.
verdict(A, unresolved) :- attest(A, test_result, _, result(_, _, _), _, _), run_voided(A).
verdict(A, meets) :- attest(A, test_result, _, result(_, _, pass), _, _), not run_voided(A).
verdict(A, conflicts) :- attest(A, test_result, _, result(_, _, fail), _, _), not run_voided(A).
verdict(A, unresolved) :- attest(A, test_result, _, result(_, _, unresolved), _, _), not run_voided(A).
% A counted model result that names a claim: a case against the claim conflicts, no case meets,
% and an unknown result is unresolved. An applies check shows no case against the claim.
model_tests_intro(M) :- model_is_derived(M), encodes(M, C), claim(C, introduce, _).
verdict(A, conflicts) :- model_verdict(A, _, preserve(_), R), model_shows_case(R).
verdict(A, meets) :- model_verdict(A, _, preserve(_), R), model_shows_no_case(R).
verdict(A, unresolved) :- model_verdict(A, _, preserve(_), R), not model_decided_result(R).
verdict(A, meets) :- model_verdict(A, _, applies(_), R), model_decided_result(R).
verdict(A, unresolved) :- model_verdict(A, _, applies(_), R), not model_decided_result(R).
verdict(A, conflicts) :- model_verdict(A, M, bad_case, R), model_tests_intro(M), model_shows_case(R).
verdict(A, meets) :- model_verdict(A, M, bad_case, R), model_tests_intro(M), model_shows_no_case(R).
verdict(A, unresolved) :- model_verdict(A, M, bad_case, R), model_tests_intro(M), not model_decided_result(R).
% A judgment of the human (D59): wanted, accepts and satisfied meet; not wanted and not
% satisfied conflict. A judgment changes the verdict of no other experiment (c41).
verdict(A, meets) :- attest(A, judgment, _, accepts(_), human, _).
verdict(A, meets) :- attest(A, judgment, _, case(_, wanted), human, _).
verdict(A, conflicts) :- attest(A, judgment, _, case(_, not_wanted), human, _).
verdict(A, meets) :- attest(A, judgment, _, satisfied, human, _).
verdict(A, conflicts) :- attest(A, judgment, _, not_satisfied, human, _).
check_unresolved(K) :- latest_run(K, A), verdict(A, unresolved).

hypothesis_of(H, G) :- hypothesis(H, G, _, _).
decl(rule, hypothesis_of(ref, ref),
     'The hypothesis (of the new sense) is a hypothesis of the goal.',
     'hypothesis @(1) is a hypothesis of goal @(2)').
% D52: an agent retirement that the rule does not count is named, so it is not a silent record.
lint_issue('W19', A, 'This retirement by an agent does not count: a human wrote or adopted the hypothesis, or the ticket marks it as adopted by the human (adoption_cited). The hypothesis is not retired. Only the human retires it: orbit-kb retire H --reason TEXT --by human.') :-
    attest(A, retirement, H, _, agent, _), hypothesis(H, _, _, _), retirement_ignored(H).
retirement_ignored(H) :- hypothesis_human_written(H).
retirement_ignored(H) :- hypothesis_adopted(H).
retirement_ignored(H) :- hypothesis_cited(H).
% D54: supports_missing/2 has no clauses here: orbit-kb computes it when the project KB of
% project_kb/1 can be read and holds no goal with that id.
lint_issue('W20', G, 'This goal supports a project goal that the project KB does not hold (supports(G, project(PG)): no goal PG there). Fix the id, or add the goal to the project KB.') :-
    supports_missing(G, _).
