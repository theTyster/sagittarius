% orbit-kb build module (modules/build.pl)
%
% Load this module with uses([build]) in kb.pl. It adds the changes to
% the code, the Lean results, and the rules that decide when the build
% is done. The file format is the same as in core.pl.
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
% D21 (issue #9): a visual claim flares. A human must see it to judge it.
decl(fact, visual(ref(claim)),
     'A human must see the claim to judge it: a look, a layout, a name, or another preference.',
     'claim @(1) is visual: a human must see it').
% D29 (ticket T29 c7, u93): an acceptance criterion of the ticket is a claim marked ac/1. It changes
% no rule: show blocking and draft blocking name an unmet one as such.
decl(fact, ac(ref(claim)),
     'The claim is an acceptance criterion (AC) of the ticket.',
     'claim @(1) is an acceptance criterion of the ticket').
decl(fact, demo(ref(subject), ref(claim)),
     'The subject, a screenshot or a recording, shows the claim to a human.',
     'subject @(1) is a demo of claim @(2)').
% D28 (T25): add writes change_at/2 with each change/2 fact, and actor/3.
decl(fact, change_at(ref(change), time),
     'The time at which the change was recorded. orbit-kb add writes it with the change.',
     'change @(1) was recorded at @(2)').
decl(fact, conformance(ref(check)),
     'The check runs the code against the Lean definitions of its claim.',
     'check @(1) runs the code against the Lean definitions').

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
     'At least one claim is current, no current claim is unfulfilled, no change is without a claim, no question must be asked, no burn or flare is open, no request is stale, and no claim is in a supersede cycle.',
     'the work is done').
decl(rule, burn_reason(ref(claim)),
     'The claim was contested twice and is not visual, it is universal, or a human asked for a Lean proof.',
     'claim @(1) has a reason to burn').
decl(rule, burn(ref(claim)),
     'The claim burns, because it has a burn reason, or it replaces a claim with a burn reason, directly or through other claims. A Lean proof closes a burn; a burn that needs no Lean proof (burn_needs_lean) is closed by a model too (D42).',
     'claim @(1) burns').
decl(rule, burn_lean_reason(ref(claim)),
     'The claim is universal, or a human asked for a proof: only a Lean proof (or a waiver) closes its burn (D42).',
     'claim @(1) has a reason to need a Lean proof').
decl(rule, burn_needs_lean(ref(claim)),
     'The claim has a reason to need a Lean proof, or it replaces such a claim, directly or through other claims (D42).',
     'claim @(1) needs a Lean proof').
decl(rule, burn_model_settled(ref(claim)),
     'A trusted model that encodes the claim gave a decided result on a check that names the claim (as has_falsifier counts it, D42).',
     'a trusted model decided claim @(1)').
decl(rule, burn_model_broken(ref(claim)),
     'A counted verdict of a model shows a case that breaks the claim (D42).',
     'a model shows a case that breaks claim @(1)').
decl(rule, burn_model_closed(ref(claim)),
     'The claim was contested twice and needs no Lean proof, and a trusted model settled it with no case that breaks it: its formal statement exists (D42).',
     'a model closes the burn of claim @(1)').
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
     'The claim is current and burns, but it is not proved, no human waived the proof, and no model closed it (D42: only a claim that needs no Lean proof can be closed by a model).',
     'claim @(1) needs a proof or a formal statement that does not exist yet').
decl(rule, any_burn_open,
     'At least one burn is open.',
     'some claim needs a proof or a formal statement that does not exist yet').
decl(rule, demo_changed(ref(subject)),
     'The file of a demo subject is missing, or its sha256 differs from the digest in subject/3. orbit-kb computes it when it reads the KB.',
     'the file of demo @(1) changed after its digest was recorded').
decl(rule, flare(ref(claim)),
     'A human must approve a demo of the claim, because it is visual, or it replaces a visual claim, directly or through other claims.',
     'claim @(1) needs a demo that a human approves').
decl(rule, flare_shown(ref(claim)),
     'A human approved a demo of the claim, the approval names the recorded digest of the demo, and the file on disk still has that digest.',
     'a human approved a demo of claim @(1)').
decl(rule, flare_waived(ref(claim)),
     'A human waived the claim, and the due time of the waiver is not past. The same waiver also closes a burn of the claim.',
     'a human waived the demo of claim @(1)').
decl(rule, flare_open(ref(claim)),
     'The claim is current and needs a demo, but no human approved a current demo and no human waived it.',
     'claim @(1) needs a demo that a human approves').
decl(rule, any_flare_open,
     'At least one flare is open.',
     'some claim needs a demo that a human approves').
decl(rule, check_waived(ref(claim)),
     'A human waived a check of the claim, and the due time of the waiver is not past. The claim is covered for done, but it is not fulfilled.',
     'a human waived a check of claim @(1)').
decl(rule, conforms(ref(claim)),
     'A conformance check of the claim passed: the code agrees with the Lean definitions on its cases.',
     'the code conforms to the Lean definitions of claim @(1)').

% D28 (T25): independent verification.
decl(rule, independently_verified(ref(claim)),
     'The latest verdict on the claim is upheld, comes from an actor whose role and session both differ from the actor of the last change of the claim, is after that change, and rests on a run of a check of the claim by the same actor after that change. A change with no change time, or a KB with no change at all, verifies nothing (fail closed).',
     'claim @(1) is independently verified').
decl(rule, last_change(ref(claim), ref(change)),
     'The change is a change of the claim and has a change time, and no other change of the claim has a later one.',
     'change @(2) is the last change of claim @(1)').
decl(rule, later_change(ref(claim), time),
     'A change of the claim was recorded after the time.',
     'a change of claim @(1) was recorded after @(2)').
% T38 c2, c3: the latest verdict, and old data that fails closed.
decl(rule, claim_change(ref(claim), ref(change)),
     'The change serves the claim. A claim that no change serves has every change of the KB (T38 c3).',
     'change @(2) is a change of claim @(1)').
decl(rule, claim_served(ref(claim)),
     'A change serves the claim.',
     'a change serves claim @(1)').
decl(rule, has_claim_change(ref(claim)),
     'The claim has a change (its own, or a change of the KB).',
     'claim @(1) has a change').
decl(rule, change_dated(ref(change)),
     'The change has a change time (change_at).',
     'change @(1) has a change time').
decl(rule, undated_change(ref(claim)),
     'A change of the claim has no change time, so no verdict on the claim can be shown to come after it (T38 c3: fail closed).',
     'a change of claim @(1) has no change time').
decl(rule, later_verdict(ref(attest)),
     'Another disproof verdict on the same claim comes after this one in kb.pl. orbit-kb computes it when it reads the KB (T38 c2).',
     'a later verdict on the same claim follows @(1)').
decl(rule, review_due,
     'No current claim is under: every claim is fulfilled or covered by a waiver, so a fresh-eyes review is due and WR1 reports (T38 c5).',
     'a review is due').
decl(rule, has_actor(ref),
     'The record has an actor.',
     '@(1) has an actor').
decl(rule, verdict_not_independent(ref(attest), ref(claim)),
     'The verdict on the claim is not independent of the last change: the change has no actor, the role or the session is the same, or the verdict is not after the change.',
     'verdict @(1) on claim @(2) is not independent of its last change').
decl(rule, run_before_last_change(ref(attest), ref(claim)),
     'The run is not after the last change of the claim.',
     'run @(1) is not after the last change of claim @(2)').
decl(rule, verdict_fresh_run(ref(attest), ref(claim)),
     'The verdict rests on a run of a check of the claim by the same actor, after the last change of the claim.',
     'verdict @(1) rests on a fresh run of a check of claim @(2)').
decl(rule, verification_recorded,
     'The KB records actors or a review (D28). Then lint warns about each current claim that is not independently verified (WR1).',
     'the KB records who verified what').

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
            waive(ref([claim, check, question, behavior_conflict]), time, text),
            [human],
            'A human waives an item until the due time, for the reason in the text: the proof and the demo of a claim, a check (its claim is covered for done, not fulfilled), a question (it need not be asked), or a conflict with existing behavior (D60).').

% ---------------------------------------------------------------------
% Build rules
% ---------------------------------------------------------------------

% 0.8.0 (D57, claims c7, c39): a claim is fulfilled by the latest run of a check of it, when the
% verdict of that run is meets and still counts (counts/2). An introduce or a retire claim also
% needs the control: the check failed before it passed (was_red/1). The rules of 0.7.2 are kept
% under the names *_072 below (the grandfather rule reads them).
fulfilled(C) :- claim(C, preserve, _), counts(_, C), not refuted(C).
fulfilled(C) :- claim(C, L, _), L \= preserve, check(K, C), latest_run(K, A), counts(A, C),
                was_red(K), not refuted(C).
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
% 0.8.0 (D57, c41): done is the done of 0.7.2 with the new fulfilled/1, and nothing of stage 2
% is open: no conflict without a location, no location that waits for its confirmation, no
% not-wanted case without a hypothesis, no open conflict with existing behavior, and the human
% judged the goal satisfied. An unresolved or stale verdict and a run that was not carried over
% leave their claim under. The second clause is the grandfather rule (c20, q27): a KB from
% before the upgrade that was done by the rules of 0.7.2 is done, with no write to it.
done :- not any_under, not any_over, not any_to_ask, not any_burn_open,
        not any_flare_open, not any_project_conflict, not any_request_stale, not any_supersede_cycle, not no_current_claim,
        not any_stage2_open.
done :- kb_before_upgrade, done_072.
% D21: contests on a visual claim escalate to its flare, not to a proof.
burn_reason(C) :- contested_twice(C), not visual(C).
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
% D42 (c_k_f_1b; Ty, q_k_f_1b: "Decided result, bounds shown. A waiver still closes it."):
% a burn has two kinds. A universal claim, a claim whose proof the human asked for, and a
% claim that replaces one of them need a Lean proof. A claim that was only contested twice
% owes a formal statement in the language that fits it: a Lean proof, or a decided result of
% a trusted model that encodes it (what has_falsifier counts), closes it. A counted case that
% breaks the claim closes nothing. The rules of trust are in core.pl.
burn_lean_reason(C) :- universal(C).
burn_lean_reason(C) :- burn_requested(C).
burn_needs_lean(C) :- burn_lean_reason(C).
burn_needs_lean(C) :- supersedes_closure(C, O), burn_lean_reason(O).
burn_model_settled(C) :- encodes(M, C), model_trusted(M), model_decided(M, C).
burn_model_broken(C) :- model_breaks(_, C).
burn_model_closed(C) :- burn_model_settled(C), not burn_model_broken(C), not burn_needs_lean(C).
burn_open(C) :- burn(C), current(C), not burn_proved(C), not burn_waived(C), not burn_model_closed(C).
any_burn_open :- burn_open(_).
% D21 (issue #9): burns get proved, flares get shown. A visual claim, or a
% claim that replaces one, needs a human approval of a demo subject at its
% current digest, or a human waiver. A new file under the same subject
% makes the approval stale, and the flare opens again. An edit of the
% file on disk does too (F3b): orbit-kb adds demo_changed(S) when it
% reads the KB, as it adds proof_changed(A) for a proof.
flare(C) :- visual(C).
flare(C) :- supersedes_closure(C, O), visual(O).
flare_shown(C) :- demo(S, C), attest(_, approval, S, digest(D), human, _), subject(S, _, D),
                  not demo_changed(S).
flare_waived(C) :- attest(W, waiver, _, waive(C, _, _), human, _), not waiver_lapsed(W).
flare_open(C) :- flare(C), current(C), not flare_shown(C), not flare_waived(C).
any_flare_open :- flare_open(_).
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
% D22 (T03): what blocks done. done does not read blocking/1. With this
% module, done holds exactly when blocking(_) has no answer. rules.pl
% cannot add clauses to these rules (lint E16).
item_open(C) :- under(C).
item_open(C) :- burn_open(C).
item_open(C) :- flare_open(C).
item_open(K) :- check(K, C), under(C).
blocking(under(C)) :- under(C).
blocking(over(X)) :- over(X).
blocking(burn_open(C)) :- burn_open(C).
blocking(flare_open(C)) :- flare_open(C).
blocking(no_claim) :- no_current_claim.
% 0.8.0 (D57, c7): a check whose latest verdict is unresolved is not a failing check.
blocking(check_failing(K)) :- check(K, C), under(C), check_ran(K), not passed(K), not check_unresolved(K).
blocking(check_unresolved(K)) :- check(K, C), under(C), check_unresolved(K).
blocking(verdict_stale(K)) :- check(K, C), under(C), latest_run(K, A), verdict(A, meets), stale_counts(A, C).
blocking(not_carried(A)) :- not_carried_run(A).
blocking(conflict_unlocated(A)) :- conflict_unlocated(A).
blocking(location_unconfirmed(L)) :- location_unconfirmed(L).
blocking(case_unplaced(J)) :- case_unplaced(J).
blocking(goal_unjudged(G)) :- goal_unjudged(G).
blocking(behavior_open(B)) :- behavior_open(B).
blocking(check_unrun(K)) :- check(K, C), under(C), not check_ran(K).
blocking(waiver_lapsed(W)) :- attest(W, waiver, _, waive(C, _, _), human, _), waiver_lapsed(W), burn_open(C).
blocking(waiver_lapsed(W)) :- attest(W, waiver, _, waive(C, _, _), human, _), waiver_lapsed(W), flare_open(C).
blocking(waiver_lapsed(W)) :- attest(W, waiver, _, waive(K, _, _), human, _), waiver_lapsed(W),
                              check(K, C), under(C).
blocking(waiver_lapsed(W)) :- attest(W, waiver, _, waive(Q, _, _), human, _), waiver_lapsed(W), to_ask(Q).
% D28 (T25): independent verification. A verdict counts only when it is
% upheld, its actor differs in role and in session from the actor of the
% last change of the claim, it is after that change, and it rests on a
% run of a check of the claim by the same actor after that change. done
% does not read it. Lint warns (WR1) in a KB that records actors.
% rules.pl cannot add clauses to these rules (lint E16).
later_change(C, T) :- claim_change(C, Y), change_at(Y, T2), T2 @> T.
last_change(C, X) :- claim_change(C, X), change_at(X, T), not later_change(C, T).
has_actor(X) :- actor(X, _, _).
% T38 c3: the changes of a claim are the changes that serve it; a claim that no change serves
% (a preserve claim) is compared with every change of the KB. Old data fails closed: a change
% of the claim with no change_at, or no change at all, makes every verdict not independent.
claim_served(C) :- serves(_, C).
claim_change(C, X) :- serves(X, C).
claim_change(C, X) :- claim(C, _, _), not claim_served(C), change(X, _).
has_claim_change(C) :- claim_change(C, _).
change_dated(X) :- change_at(X, _).
undated_change(C) :- claim_change(C, X), not change_dated(X).
verdict_not_independent(V, C) :- attest(V, disproof, _, verdict(C, _), _, _), not has_claim_change(C).
verdict_not_independent(V, C) :- attest(V, disproof, _, verdict(C, _), _, _), undated_change(C).
verdict_not_independent(V, C) :- attest(V, disproof, _, verdict(C, _), _, _), last_change(C, X), not has_actor(X).
verdict_not_independent(V, C) :- attest(V, disproof, _, verdict(C, _), _, _), last_change(C, X),
                                  actor(V, R, _), actor(X, R, _).
verdict_not_independent(V, C) :- attest(V, disproof, _, verdict(C, _), _, _), last_change(C, X),
                                  actor(V, _, S), actor(X, _, S).
verdict_not_independent(V, C) :- attest(V, disproof, _, verdict(C, _), _, TV), last_change(C, X),
                                  change_at(X, TX), TV @=< TX.
run_before_last_change(A, C) :- attest(A, test_result, _, _, _, TA), last_change(C, X),
                                change_at(X, TX), TA @=< TX.
verdict_fresh_run(V, C) :- attest(V, disproof, _, verdict(C, _), _, _), actor(V, R, S),
                           rests_on_run(V, A), attest(A, test_result, _, result(K, _, _), _, _),
                           check(K, C), actor(A, R, S), not run_before_last_change(A, C).
% T38 c2: only the latest verdict on C counts (later_verdict/1: orbit-kb computes it from the
% order of kb.pl, the order of the Review section of report).
independently_verified(C) :- attest(V, disproof, _, verdict(C, upheld(_)), _, _), has_actor(V),
                             not later_verdict(V),
                             not verdict_not_independent(V, C), verdict_fresh_run(V, C).
verification_recorded :- actor(_, _, _).
verification_recorded :- review_saw(_, _, _).
lint_issue('WR1', C, 'No fresh-eyes verdict verifies this claim yet. A reviewer of another role and session must rerun a check of the claim after its last change (orbit-kb run --as ROLE), then record an upheld verdict that rests on that run (attest disproof --rests-on). orbit-kb report lists the review. This does not block done.') :-
    verification_recorded, review_due, current(C), not independently_verified(C).
% T38 c5: WR1 waits until a review is due: no current claim is under.
review_due :- not any_under.


% =====================================================================
% 0.8.0, stage 2: experiments and verdicts in the build (D55 to D62)
% =====================================================================
% rules.pl cannot add clauses to these rules (lint E16).

decl(rule, change_after_run(ref(change), ref(attest)),
     'The change has a change time, and it was recorded after the run: at a later time, or at the same time on a later line of kb.pl.',
     'change @(1) was recorded after run @(2)').
decl(rule, change_before_run(ref(change), ref(attest)),
     'The change was recorded before the run.',
     'change @(1) was recorded before run @(2)').
decl(rule, verdict_stale(ref(attest), ref(claim)),
     'The run is a run of a check of the claim, and a change that serves the claim was recorded after it: the verdict is of an older state (claim c39). A change with no change time makes no run stale.',
     'the verdict of run @(1) is stale for claim @(2): a later change serves the claim').
decl(rule, stale_counts(ref(attest), ref(claim)),
     'The stale verdict takes the fulfilment away. In a KB that was done before the upgrade, only a change that was recorded after the upgrade does that.',
     'the stale verdict of run @(1) does not count for claim @(2)').
decl(rule, stale_grandfathered(ref(attest), ref(claim)),
     'The verdict is stale, and the ticket was done before the upgrade: the tool lists it, and it blocks nothing.',
     'the verdict of run @(1) for claim @(2) is stale (done before the upgrade)').
decl(rule, counts(ref(attest), ref(claim)),
     'The run is the latest run of a check of the claim, its verdict is meets, the verdict is not stale, and the run counts for the current goal.',
     'run @(1) counts for claim @(2)').
decl(rule, control(ref(attest)),
     'The run is the control of an introduce or a retire claim: it conflicts, and no change that serves the claim was recorded before it. A control needs no location (claim c40).',
     'run @(1) is the control: it conflicts before any change').
decl(rule, served_before_run(ref(claim), ref(attest)),
     'A change that serves the claim was recorded before the run.',
     'a change that serves claim @(1) was recorded before run @(2)').
decl(rule, located(ref(attest)),
     'A location is recorded for the run.',
     'the conflict of run @(1) has a location').
decl(rule, conflict_open(ref(attest)),
     'The run is the latest run of its check, its verdict is conflicts, the claim is current, the run is not a control, and no location is recorded for it.',
     'the conflict of run @(1) has no location').
decl(rule, check_is_waived(ref(check)),
     'A human waived the check, and the due time of the waiver is not past.',
     'a human waived check @(1)').
decl(rule, before_upgrade_record(ref(attest)),
     'The ticket was done before the upgrade, and the attestation was recorded before the upgrade.',
     '@(1) was recorded before the upgrade of a ticket that was done').
decl(rule, conflict_unlocated(ref(attest)),
     'The conflict of the run has no location, and it blocks done: locate it in the build, the measurement, a premise, the hypothesis, or a claim (orbit-kb locate).',
     'the conflict of run @(1) needs a location').
decl(rule, location_outside(ref(attest)),
     'The location places the conflict outside the build.',
     'location @(1) is outside the build').
decl(rule, confirmer_dependent(ref(attest)),
     'The confirmation is not independent of the build: its actor has the role or the session of the actor of a change, or a change has no actor.',
     'confirmation @(1) is not independent of the build').
decl(rule, location_confirmed(ref(attest)),
     'The human confirmed the location, or an actor whose role and session both differ from the actor of every change of the KB (a pane that did not build).',
     'location @(1) is confirmed').
decl(rule, location_unconfirmed(ref(attest)),
     'The location is outside the build, it is of the latest run of its check, and nobody who did not build confirmed it.',
     'location @(1) waits for a confirmation').
decl(rule, to_discovery(ref),
     'The item goes back to discovery: a hypothesis that a confirmed location defeats, a claim of the goal with a confirmed conflict in the claim, or a not-wanted case that no hypothesis is named for.',
     '@(1) goes to discovery').
decl(rule, goal_judgment(ref(attest), ref, oneof([satisfied, not_satisfied])),
     'A judgment of the human of the goal as a whole. A case that the human judged not wanted counts as not satisfied.',
     'judgment @(1) says that goal @(2) is @(3)').
decl(rule, later_goal_judgment(ref(attest), ref),
     'A later judgment of the goal follows this one in kb.pl.',
     'a later judgment of goal @(2) follows @(1)').
decl(rule, goal_satisfied(ref),
     'The latest judgment of the human on the goal says satisfied.',
     'the human judged goal @(1) satisfied').
decl(rule, goal_unjudged(ref),
     'The goal is current, and the latest judgment of the human does not say that it is satisfied. It blocks done, except in a ticket that was done before the upgrade.',
     'the human has not judged goal @(1) satisfied').
decl(rule, case_not_wanted(ref(attest), ref),
     'The human judged the case on the goal not wanted.',
     'the human judged case @(1) on goal @(2) not wanted').
decl(rule, case_placed(ref(attest)),
     'The not-wanted case is recorded against a hypothesis.',
     'case @(1) is recorded against a hypothesis').
decl(rule, goal_has_current_hypothesis(ref),
     'The goal has a current hypothesis.',
     'goal @(1) has a current hypothesis').
decl(rule, case_unplaced(ref(attest)),
     'The human judged the case not wanted, its goal has a current hypothesis, and the case is recorded against no hypothesis (case_against).',
     'the not-wanted case @(1) is recorded against no hypothesis').
decl(rule, formal(ref(subject), ref(claim)),
     'The subject is a formal statement of the claim: a formal_statement fact, or a model that encodes the claim.',
     'subject @(1) states claim @(2) formally').
decl(rule, formal_accepted(ref(subject), ref(claim)),
     'The human accepted that the formal statement says what the claim means.',
     'the human accepted the formal statement @(1) of claim @(2)').
decl(rule, formal_unaccepted(ref(subject), ref(claim)),
     'The formal statement of a current claim has no accepts judgment of the human. report lists it.',
     'the human has not accepted the formal statement @(1) of claim @(2)').
decl(rule, behavior_named(ref(behavior_conflict)),
     'A current claim names the behavior of the conflict.',
     'a current claim names the behavior of conflict @(1)').
decl(rule, behavior_waived(ref(behavior_conflict)),
     'A human waived the conflict, and the due time of the waiver is not past.',
     'a human waived conflict @(1)').
decl(rule, behavior_open(ref(behavior_conflict)),
     'The behavior of the conflict is open for review: no current claim names it, and no human waived it.',
     'the behavior of conflict @(1) is open for review').
decl(rule, before_goal(ref, ref),
     'The record (a hypothesis, a claim, or a run) stands before the fact of the goal in kb.pl, and the goal replaces an older goal. orbit-kb computes it when it reads the KB.',
     '@(1) was recorded before goal @(2) replaced the older goal').
decl(rule, carried_over(ref, ref),
     'The record is carried over to the goal: by a carried fact, or as a claim of a hypothesis that is carried over.',
     '@(1) is carried over to goal @(2)').
decl(rule, not_carried(ref),
     'The record is of an older goal, and no record carries it over to the current goal. It does not count for the current goal.',
     '@(1) is not carried over to the current goal').
decl(rule, not_carried_run(ref(attest)),
     'The run is the latest run of a check of a current claim that is not fulfilled, and it is not carried over to the current goal: the claim needs a new run or a carried record.',
     'run @(1) is not carried over, and its claim needs it').
decl(rule, any_stage2_open,
     'A conflict has no location, a location waits for its confirmation, a not-wanted case has no hypothesis, a conflict with existing behavior is open, or the human has not judged the goal satisfied.',
     'an item of the experiments or of the judgment of the goal is open').
decl(rule, done_before_upgrade,
     'The ticket was done by the rules of 0.7.2 before orbit-kb 0.8.0 or later wrote to the KB: the fact done_before_upgrade/2, or a KB from before the upgrade in which done_072 holds.',
     'the ticket was done before the upgrade').
decl(rule, after_upgrade_change(ref(change)),
     'The change was recorded at or after the first write of orbit-kb 0.8.0 or later.',
     'change @(1) was recorded after the upgrade').
% The rules of 0.7.2, verbatim (D57; the names have the suffix _072).
decl(rule, current_072(ref(claim)), 'current/1 as orbit-kb 0.7.2 had it.', 'claim @(1) is current (0.7.2)').
decl(rule, passed_072(ref(check)), 'passed/1 as orbit-kb 0.7.2 had it.', 'check @(1) passed (0.7.2)').
decl(rule, failed_after_072(ref(check), int), 'failed_after/2 as orbit-kb 0.7.2 had it.', 'check @(1) failed after run @(2) (0.7.2)').
decl(rule, was_red_072(ref(check)), 'was_red/1 as orbit-kb 0.7.2 had it.', 'check @(1) failed before it passed (0.7.2)').
decl(rule, fulfilled_072(ref(claim)), 'fulfilled/1 as orbit-kb 0.7.2 had it.', 'claim @(1) is fulfilled (0.7.2)').
decl(rule, under_072(ref(claim)), 'under/1 as orbit-kb 0.7.2 had it.', 'claim @(1) is under (0.7.2)').
decl(rule, any_under_072, 'any_under as orbit-kb 0.7.2 had it.', 'some claim is under (0.7.2)').
decl(rule, to_ask_072(ref(question)), 'to_ask/1 as orbit-kb 0.7.2 had it.', 'question @(1) must be asked (0.7.2)').
decl(rule, any_to_ask_072, 'any_to_ask as orbit-kb 0.7.2 had it.', 'some question must be asked (0.7.2)').
decl(rule, burn_open_072(ref(claim)), 'burn_open/1 as orbit-kb 0.7.2 had it.', 'the burn of claim @(1) is open (0.7.2)').
decl(rule, any_burn_open_072, 'any_burn_open as orbit-kb 0.7.2 had it.', 'some burn is open (0.7.2)').
decl(rule, flare_open_072(ref(claim)), 'flare_open/1 as orbit-kb 0.7.2 had it.', 'the flare of claim @(1) is open (0.7.2)').
decl(rule, any_flare_open_072, 'any_flare_open as orbit-kb 0.7.2 had it.', 'some flare is open (0.7.2)').
decl(rule, any_current_claim_072, 'any_current_claim as orbit-kb 0.7.2 had it.', 'some claim is current (0.7.2)').
decl(rule, no_current_claim_072, 'no_current_claim as orbit-kb 0.7.2 had it.', 'no claim is current (0.7.2)').
decl(rule, done_072,
     'done as orbit-kb 0.7.2 had it: the grandfather rule reads it for a KB from before the upgrade.',
     'the work is done by the rules of 0.7.2').

% --- The rules of 0.7.2, verbatim -------------------------------------
current_072(C) :- claim(C, _, _), not superseded(C).
passed_072(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after_072(K, R).
failed_after_072(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
was_red_072(K) :- attest(_, test_result, _, result(K, R1, fail), _, _),
                  attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
fulfilled_072(C) :- claim(C, preserve, _), check(K, C), passed_072(K), not refuted(C).
fulfilled_072(C) :- claim(C, L, _), L \= preserve, check(K, C), passed_072(K), was_red_072(K),
                    not refuted(C).
under_072(C) :- current_072(C), not fulfilled_072(C), not check_waived(C).
any_under_072 :- under_072(_).
to_ask_072(Q) :- question(Q, C, _), current_072(C), contested(C), not answered(Q),
                 not question_waived(Q).
to_ask_072(Q) :- migration_question(Q), not answered(Q), not question_waived(Q).
any_to_ask_072 :- to_ask_072(_).
burn_open_072(C) :- burn(C), current_072(C), not burn_proved(C), not burn_waived(C), not burn_model_closed(C).
any_burn_open_072 :- burn_open_072(_).
flare_open_072(C) :- flare(C), current_072(C), not flare_shown(C), not flare_waived(C).
any_flare_open_072 :- flare_open_072(_).
any_current_claim_072 :- current_072(_).
no_current_claim_072 :- not any_current_claim_072.
done_072 :- not any_under_072, not any_over, not any_to_ask_072, not any_burn_open_072,
            not any_flare_open_072, not any_project_conflict_072, not any_request_stale, not any_supersede_cycle, not no_current_claim_072.

% --- The grandfather rule (D57; c20, c39, q27) ------------------------
% kb_before_upgrade is a fact that orbit-kb computes when it reads a KB whose newest
% "% Made by orbit-kb V." line is below 0.8.0 (or absent) and that holds no upgraded/2 fact.
% The first write of orbit-kb 0.8.0 or later to such a KB records upgraded/2, and
% done_before_upgrade/2 when done_072 held.
done_before_upgrade :- done_before_upgrade(_, _).
done_before_upgrade :- kb_before_upgrade, done_072.
after_upgrade_change(X) :- upgraded(_, TU), change_at(X, TX), TX @>= TU.
before_upgrade_record(_) :- done_before_upgrade, kb_before_upgrade.
before_upgrade_record(A) :- done_before_upgrade, upgraded(_, TU), attest(A, _, _, _, _, TA), TA @< TU.

% --- Stale verdicts and what counts (D56; c39) ------------------------
change_after_run(X, A) :- change_at(X, TX), attest(A, test_result, _, _, _, TA), TX @> TA.
change_after_run(X, A) :- change_at(X, TX), attest(A, test_result, _, _, _, TX),
                          record_line(X, LX), record_line(A, LA), LX > LA.
change_before_run(X, A) :- change_at(X, TX), attest(A, test_result, _, _, _, TA), TX @< TA.
change_before_run(X, A) :- change_at(X, TX), attest(A, test_result, _, _, _, TX),
                           record_line(X, LX), record_line(A, LA), LX < LA.
change_before_run(X, A) :- change(X, _), not change_dated(X), attest(A, test_result, _, _, _, _),
                           record_line(X, LX), record_line(A, LA), LX < LA.
verdict_stale(A, C) :- attest(A, test_result, _, result(K, _, _), _, _), check(K, C),
                       serves(X, C), change_after_run(X, A).
stale_counts(A, C) :- verdict_stale(A, C), not done_before_upgrade.
stale_counts(A, C) :- done_before_upgrade, attest(A, test_result, _, result(K, _, _), _, _), check(K, C),
                      serves(X, C), change_after_run(X, A), after_upgrade_change(X).
stale_grandfathered(A, C) :- done_before_upgrade, check(K, C), latest_run(K, A), verdict_stale(A, C),
                             not stale_counts(A, C).
counts(A, C) :- check(K, C), latest_run(K, A), verdict(A, meets), not stale_counts(A, C),
                not not_carried(A).
% The control (c40): the red run of an introduce or a retire claim before any change.
served_before_run(C, A) :- serves(X, C), change_before_run(X, A).
control(A) :- attest(A, test_result, _, result(K, _, fail), _, _), check(K, C), claim(C, L, _),
              L \= preserve, not served_before_run(C, A).

% --- The kinds of experiment that the build adds (D55; c6) ------------
experiment(A, proof, C) :- attest(A, lean_proof, _, proof(C, _), script, _).
verdict(A, meets) :- attest(A, lean_proof, _, proof(_, _), script, _), not proof_changed(A).
verdict(A, unresolved) :- attest(A, lean_proof, _, proof(_, _), script, _), proof_changed(A).
experiment(A, demo, C) :- attest(A, approval, S, digest(_), human, _), demo(S, C).
verdict(A, meets) :- attest(A, approval, S, digest(D), human, _), demo(S, _), subject(S, _, D),
                     not demo_changed(S).
verdict(A, unresolved) :- attest(A, approval, S, digest(_), human, _), demo(S, _), stale(A).
verdict(A, unresolved) :- attest(A, approval, S, digest(D), human, _), demo(S, _), subject(S, _, D),
                          demo_changed(S).

% --- The location of a conflict (D58; c9, c40) ------------------------
located(A) :- attest(_, location, A, located(_, _), _, _).
check_is_waived(K) :- attest(W, waiver, _, waive(K, _, _), human, _), check(K, _), not waiver_lapsed(W).
conflict_open(A) :- check(K, C), current(C), latest_run(K, A), verdict(A, conflicts),
                    not control(A), not located(A).
conflict_unlocated(A) :- conflict_open(A), attest(A, test_result, _, result(K, _, _), _, _),
                         not check_is_waived(K), not before_upgrade_record(A).
location_outside(L) :- attest(L, location, _, located(W, _), _, _), W \= build.
confirmer_dependent(F) :- attest(F, confirmation, _, _, _, _), actor(F, R, _), change(X, _), actor(X, R, _).
confirmer_dependent(F) :- attest(F, confirmation, _, _, _, _), actor(F, _, S), change(X, _), actor(X, _, S).
confirmer_dependent(F) :- attest(F, confirmation, _, _, _, _), change(X, _), not has_actor(X).
location_confirmed(L) :- attest(L, location, _, _, _, _), attest(_, confirmation, L, confirms(_), human, _).
location_confirmed(L) :- attest(L, location, _, _, _, _), attest(F, confirmation, L, confirms(_), agent, _),
                         has_actor(F), not confirmer_dependent(F).
location_unconfirmed(L) :- location_outside(L), attest(L, location, A, _, _, _),
                           attest(A, test_result, _, result(K, _, _), _, _), latest_run(K, A),
                           not location_confirmed(L).
% A confirmed location in the measurement: the verdict of the run is unresolved, and the check
% owes a new run.
run_voided(A) :- attest(L, location, A, located(measurement, _), _, _), location_confirmed(L).
% A confirmed location in a hypothesis, or in a premise of it: the hypothesis is defeated
% (builder K1 has the first clause, defeat/3), and it goes to discovery.
hypothesis_defeated(H) :- attest(L, location, _, located(hypothesis(H), _), _, _), location_confirmed(L),
                          hypothesis_of(H, _).
hypothesis_defeated(H) :- attest(L, location, _, located(premise(P), _), _, _), location_confirmed(L),
                          premise(P, H, _), hypothesis_of(H, _).
hypothesis_defeated(H) :- case_against(J, H), case_not_wanted(J, _), hypothesis_of(H, _).
to_discovery(H) :- attest(L, location, _, located(hypothesis(H), _), _, _), location_confirmed(L).
to_discovery(H) :- attest(L, location, _, located(premise(P), _), _, _), location_confirmed(L),
                   premise(P, H, _).
to_discovery(C) :- attest(L, location, _, located(claim(C), _), _, _), location_confirmed(L).
to_discovery(J) :- case_not_wanted(J, G), goal_current(G), not case_placed(J).

% --- The judgment of the human (D59; c10, c41) ------------------------
goal_judgment(A, G, satisfied) :- attest(A, judgment, G, satisfied, human, _).
goal_judgment(A, G, not_satisfied) :- attest(A, judgment, G, not_satisfied, human, _).
goal_judgment(A, G, not_satisfied) :- attest(A, judgment, G, case(_, not_wanted), human, _).
later_goal_judgment(A, G) :- goal_judgment(A, G, _), goal_judgment(B, G, _),
                             record_line(A, LA), record_line(B, LB), LB > LA.
goal_satisfied(G) :- goal_judgment(A, G, satisfied), not later_goal_judgment(A, G).
goal_unjudged(G) :- goal_current(G), not goal_satisfied(G), not done_before_upgrade.
case_not_wanted(J, G) :- attest(J, judgment, G, case(_, not_wanted), human, _).
case_placed(J) :- case_against(J, _).
goal_has_current_hypothesis(G) :- hypothesis_of(H, G), hypothesis_current(H).
case_unplaced(J) :- case_not_wanted(J, G), goal_current(G), goal_has_current_hypothesis(G),
                    not case_placed(J).
formal(S, C) :- formal_statement(S, C).
formal(M, C) :- encodes(M, C).
formal_accepted(S, C) :- attest(_, judgment, S, accepts(C), human, _).
formal_unaccepted(S, C) :- formal(S, C), current(C), not formal_accepted(S, C).

% --- Sound Basis (D60; c16) -------------------------------------------
behavior_named(B) :- names(C, B), current(C).
behavior_waived(B) :- behavior_conflict(B, _), attest(W, waiver, _, waive(B, _, _), human, _),
                      not waiver_lapsed(W).
behavior_open(B) :- behavior_conflict(B, _), not behavior_named(B), not behavior_waived(B).

% --- A change of the goal (D61; c42) ----------------------------------
% before_goal/2 has no clauses here: orbit-kb adds its facts when it reads the KB.
carried_over(X, G) :- carried(X, G).
carried_over(C, G) :- predicts(H, C), carried(H, G).
not_carried(X) :- before_goal(X, G), goal_current(G), not carried_over(X, G).
not_carried_run(A) :- not_carried(A), attest(A, test_result, _, result(K, _, _), _, _),
                      latest_run(K, A), check(K, C), under(C).

any_stage2_open :- conflict_unlocated(_).
any_stage2_open :- location_unconfirmed(_).
any_stage2_open :- case_unplaced(_).
any_stage2_open :- goal_unjudged(_).
any_stage2_open :- behavior_open(_).

lint_issue('W17', K, 'This check of a current claim has no procedure and no run: the experiment does not say how it is carried out. Add procedure(K, Text), or run the check (the command of the last run is then the procedure).') :-
    check(K, C), current(C), not procedure(K, _), not check_ran(K).
lint_issue('W18', S, 'This formal statement does not say which decision its precision could change. Add could_change(S, Text) (formalize the smallest claim whose precision could change what the human or the agent does next).') :-
    made_by_new, formal(S, _), not could_change(S, _).
lint_issue('W18', S, 'This formal statement (could_change) names no claim. Add formal_statement(S, C), or encodes(M, C) for a model.') :-
    made_by_new, could_change(S, _), not formal(S, _).
