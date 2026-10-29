% orbit-kb build module (modules/build.pl)
%
% Load this module with uses([build]) in kb.pl. It adds the changes to
% the code, the Lean results, and the rules that decide when the build
% is done. The file format and the H1 rule are the same as in core.pl.
% The rules below use the core rules passed/1, was_red/1, refuted/1,
% current/1, to_ask/1, contested_twice/1, supersedes_closure/2, and
% any_supersede_cycle/0.


% ---------------------------------------------------------------------
% Build facts
% ---------------------------------------------------------------------

decl(fact, change(id, text),
     'A change to the code, with the file or a short description.',
     '@(1) is a change: @(2)').
decl(fact, serves(ref(change), ref(claim)),
     'The change serves the claim.',
     'change @(1) serves claim @(2)').
decl(fact, burn_requested(ref(claim)),
     'A human asked for a Lean proof of the claim.',
     'a human asked for a Lean proof of claim @(1)').
decl(fact, conformance(ref(check)),
     'The check runs the code against the Lean model of its claim.',
     'check @(1) runs the code against the Lean model').

% ---------------------------------------------------------------------
% Build rule predicates
% ---------------------------------------------------------------------

decl(rule, fulfilled(ref(claim)),
     'A check of the claim passed with no later fail, it failed first unless the label is preserve, and nothing refutes the claim.',
     'claim @(1) is fulfilled').
decl(rule, under(ref(claim)),
     'The claim is current, but it is not fulfilled, and no human waived a check of it.',
     'claim @(1) is current but not fulfilled').
decl(rule, served(ref(change)),
     'The change serves at least one claim.',
     'change @(1) serves a claim').
decl(rule, over(ref(change)),
     'The change serves no claim.',
     'change @(1) serves no claim').
decl(rule, any_under,
     'At least one current claim is not fulfilled.',
     'some current claim is not fulfilled').
decl(rule, any_over,
     'At least one change serves no claim.',
     'some change serves no claim').
decl(rule, any_current_claim,
     'At least one claim is current.',
     'some claim is current').
decl(rule, no_current_claim,
     'No claim is current. Then the work is not done.',
     'no claim is current').
decl(rule, done,
     'At least one claim is current, no current claim is unfulfilled, no change is without a claim, no question must be asked, no burn is open, and no claim is in a supersede cycle.',
     'the work is done').
decl(rule, burn_reason(ref(claim)),
     'The claim was contested twice, it is universal, or a human asked for a Lean proof.',
     'claim @(1) has a reason to need a Lean proof').
decl(rule, burn(ref(claim)),
     'The claim needs a Lean proof, because it has a burn reason, or it replaces a claim with a burn reason, directly or through other claims.',
     'claim @(1) needs a Lean proof').
decl(rule, proof_changed(ref(attest)),
     'A file of the proof changed after the proof, or the proof log is missing or does not match. orbit-kb computes it when it reads the KB.',
     'a file of proof @(1) changed after the proof').
decl(rule, waiver_lapsed(ref(attest)),
     'The due time of the waiver is in the past, or it is not a valid time. orbit-kb computes it when it reads the KB.',
     'waiver @(1) is past its due time').
decl(rule, burn_proved(ref(claim)),
     'orbit-kb prove recorded a proof of the claim, and no file of that proof has changed since.',
     'claim @(1) is proved in Lean').
decl(rule, burn_waived(ref(claim)),
     'A human waived the proof of the claim, and the due time of the waiver is not past.',
     'a human waived the proof of claim @(1)').
decl(rule, burn_open(ref(claim)),
     'The claim is current and needs a Lean proof, but it is not proved and no human waived the proof.',
     'claim @(1) needs a Lean proof that does not exist yet').
decl(rule, any_burn_open,
     'At least one burn is open.',
     'some claim needs a Lean proof that does not exist yet').
decl(rule, check_waived(ref(claim)),
     'A human waived a check of the claim, and the due time of the waiver is not past. The claim is covered for done, but it is not fulfilled.',
     'a human waived a check of claim @(1)').
decl(rule, conforms(ref(claim)),
     'A conformance check of the claim passed: the code agrees with the Lean model on its cases.',
     'the code conforms to the Lean model of claim @(1)').

% ---------------------------------------------------------------------
% Build attestation types
% ---------------------------------------------------------------------

attest_type(lean_result,
            verdict(ref(claim), alt([stated, refuted(text), tested(int)])),
            [agent, script],
            'Progress on the Lean statement of a claim: stated (it type-checks with sorry), refuted (with the counterexample as text), or tested in N trials with no counterexample. None of these is a proof.').
attest_type(lean_proof,
            proof(ref(claim), digest),
            [script],
            'A Lean proof of the claim. The digest covers the files of the proof. Only orbit-kb prove writes it.').
attest_type(waiver,
            waive(ref([claim, check, question]), time, text),
            [human],
            'A human waives an item until the due time, for the reason in the text: the proof of a claim, a check (its claim is covered for done, not fulfilled), or a question (it need not be asked).').

% ---------------------------------------------------------------------
% Build rules
% ---------------------------------------------------------------------

fulfilled(C) :- claim(C, preserve, _), check(K, C), passed(K), not refuted(C).
fulfilled(C) :- claim(C, L, _), L \= preserve, check(K, C), passed(K), was_red(K),
                not refuted(C).
under(C) :- current(C), not fulfilled(C), not check_waived(C).
served(X) :- serves(X, _).
over(X) :- change(X, _), not served(X).
any_under :- under(_).
any_over :- over(_).
% D17 (issue #1): a KB with no current claim is not done. Before D17, a
% build KB right after init was done. done negates no_current_claim, and
% does not call any_current_claim directly: then whynot done can explain
% "no claim is current" in the grounded program (a rule instance with a
% positive body that cannot hold is not in the grounding).
any_current_claim :- current(_).
no_current_claim :- not any_current_claim.
done :- not any_under, not any_over, not any_to_ask, not any_burn_open,
        not any_supersede_cycle, not no_current_claim.
burn_reason(C) :- contested_twice(C).
burn_reason(C) :- universal(C).
burn_reason(C) :- burn_requested(C).
% A claim that replaces a burning claim inherits the burn (Ty, 2026-10-20).
% supersedes_closure/2 is a derived fact (core.pl), so burn/1 does not
% recurse through supersedes/2.
burn(C) :- burn_reason(C).
burn(C) :- supersedes_closure(C, O), burn_reason(O).
% A burn needs a proof. A stated or tested Lean result is progress, not
% a proof. When orbit-kb reads the KB, it adds a proof_changed/1 fact
% for each proof whose files changed, and a waiver_lapsed/1 fact for
% each waiver whose due time is past or not a valid time. So an old
% proof or an old waiver does not count. rules.pl cannot add clauses to
% these rules (lint E16; the engines ignore such clauses).
burn_proved(C) :- attest(A, lean_proof, _, proof(C, _), script, _), not proof_changed(A).
burn_waived(C) :- attest(W, waiver, _, waive(C, _, _), human, _), not waiver_lapsed(W).
burn_open(C) :- burn(C), current(C), not burn_proved(C), not burn_waived(C).
any_burn_open :- burn_open(_).
conforms(C) :- conformance(K), check(K, C), passed(K).
% D13 (Ty, 2026-10-21): a waiver can also target a check or a question.
% A waiver on a check covers its claim for done (under/1), but the claim
% is not fulfilled, and a burn of the claim still needs a proof or a
% waiver on the claim. A waiver on a question closes it (to_ask/1 in
% core.pl reads question_waived/1). A lapsed waiver (waiver_lapsed/1)
% does not count. rules.pl cannot add clauses to these rules (lint E16).
check_waived(C) :- check(K, C), attest(W, waiver, _, waive(K, _, _), human, _),
                   not waiver_lapsed(W).
question_waived(Q) :- question(Q, _, _), attest(W, waiver, _, waive(Q, _, _), human, _),
                      not waiver_lapsed(W).
