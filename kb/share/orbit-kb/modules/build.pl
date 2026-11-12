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
            waive(ref([claim, check, question]), time, text),
            [human],
            'A human waives an item until the due time, for the reason in the text: the proof and the demo of a claim, a check (its claim is covered for done, not fulfilled), or a question (it need not be asked).').

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
        not any_flare_open, not any_project_conflict, not any_request_stale, not any_supersede_cycle, not no_current_claim.
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
burn_open(C) :- burn(C), current(C), not burn_proved(C), not burn_waived(C).
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
blocking(check_failing(K)) :- check(K, C), under(C), check_ran(K), not passed(K).
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
