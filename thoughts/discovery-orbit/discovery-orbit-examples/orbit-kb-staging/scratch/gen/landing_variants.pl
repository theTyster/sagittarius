% Variants imported from the LANDING MODULE review (evidence/landing-review.md), probe
% and qwait fixtures. Intended answers, written by the reviewer before the run.
% Left out (accepted-risk candidates or intentional core lint errors): pl_div_model_file_fixed (LM13), pl_no_budget_default (LM18), pl_lap_gap (LM18), pl_stale_ratification (LM16), pl_ready_with_ed1 (LM17), pl_ready_with_ed8 (LM17), pl_explore_rerun (LM14), pl_normal_case_sat (LM15), pl_model_run_no_model_fact (L19 (core E3/E4 on purpose)), pl_two_hypotheses (LM19).

% L1. DISPROVE step: "Use inconclusive or abstained when it applies." ED5 text: "File a
% disproof with the case." REVIEW 2: preserve(C) sat "when no disproof exists". An abstained
% disproof is not a disproof with the case, so the break stays open.
variant(pl_disproof_abstained, [
    replace(attest(a15, model_result, run_target, verdict(m_target, preserve(c2b), unsat), agent, '2026-10-15T10:20:00Z'),
            attest(a15, model_result, run_target, verdict(m_target, preserve(c2b), sat), agent, '2026-10-15T10:20:00Z')),
    add(attest(a18, disproof, m_target, verdict(c2b, abstained), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_disproof_abstained, 'model_unfiled_break(C)', ['C = c2b']).
expect(pl_disproof_abstained, 'discovery_ready', none).
expect(pl_disproof_abstained, 'lint_issue(''ED5'', Id, _)', ['Id = c2b']).

variant(pl_disproof_inconclusive, [
    replace(attest(a15, model_result, run_target, verdict(m_target, preserve(c2b), unsat), agent, '2026-10-15T10:20:00Z'),
            attest(a15, model_result, run_target, verdict(m_target, preserve(c2b), sat), agent, '2026-10-15T10:20:00Z')),
    add(attest(a18, disproof, m_target, verdict(c2b, inconclusive), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_disproof_inconclusive, 'model_unfiled_break(C)', ['C = c2b']).
expect(pl_disproof_inconclusive, 'discovery_ready', none).

% L1c. A disproof of another claim does not file the break of c2b (identity of the claim).
variant(pl_disproof_other_claim, [
    replace(attest(a15, model_result, run_target, verdict(m_target, preserve(c2b), unsat), agent, '2026-10-15T10:20:00Z'),
            attest(a15, model_result, run_target, verdict(m_target, preserve(c2b), sat), agent, '2026-10-15T10:20:00Z')),
    add(attest(a18, disproof, m_target, verdict(c1, inconclusive), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_disproof_other_claim, 'model_unfiled_break(C)', ['C = c2b']).
expect(pl_disproof_other_claim, 'discovery_ready', none).

% L2. Draft "Divergences": "A model and the current system disagree ... Use model(M)."
% The draft does not name the subject. REVIEW 1 P2. The system log is a natural subject.
variant(pl_div_on_system_log, [
    add(attest(a18, divergence, log4417, model(m_now), agent, '2026-10-15T11:00:00Z')),
    add(note(a18, 'One code of $5.00 on $40.00: the model gives 3500 cents, the log shows 3000 cents.'))]).
expect(pl_div_on_system_log, 'model_diverges(M)', ['M = m_now']).
expect(pl_div_on_system_log, 'discovery_ready', none).

% L3. The same divergence with the model file as subject (module clause, untested).
variant(pl_div_on_model_file, [
    add(attest(a18, divergence, m_now, model(m_now), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_div_on_model_file, 'model_diverges(M)', ['M = m_now']).
expect(pl_div_on_model_file, 'discovery_ready', none).

% L3c. Same fix path, divergence recorded on the run log (the module's documented path).
variant(pl_div_run_fixed, [
    add(attest(a18, divergence, run_now, model(m_now), agent, '2026-10-15T11:00:00Z')),
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'),
            subject(m_now, 'models/discount-now-v2.smt2', 'sha256:be087eaf26d6d7b83f5902ffb939fe1a7844451a3d66b144f86eeb2283be0025')),
    add(subject(run_now2, 'logs/discount-now.log', 'sha256:28a3707031369687b040d9bdf2ad89bba2123be3af93c78b285975c970478db0')),
    add(model_run(run_now2, m_now, 'sha256:be087eaf26d6d7b83f5902ffb939fe1a7844451a3d66b144f86eeb2283be0025')),
    add(attest(a19, model_result, run_now2, verdict(m_now, sanity, sat), agent, '2026-10-15T11:10:00Z')),
    add(attest(a20, model_result, run_now2, calibration(m_now, example(c1), matches), agent, '2026-10-15T11:10:00Z')),
    add(attest(a21, model_result, run_now2, verdict(m_now, bad_case, sat), agent, '2026-10-15T11:10:00Z'))]).
expect(pl_div_run_fixed, 'model_diverges(M)', none).
expect(pl_div_run_fixed, 'model_trusted(M)', ['M = m_now', 'M = m_target']).
expect(pl_div_run_fixed, 'discovery_ready', true).
expect(pl_div_run_fixed, 'lint_issue(''WD8'', Id, _)', ['Id = a3', 'Id = a4', 'Id = a5', 'Id = a6', 'Id = a7', 'Id = a8']).

% L3d. Divergence on a run at the current digest, but the model was NOT changed: still diverges.
variant(pl_div_run_not_fixed, [
    add(attest(a18, divergence, run_now, model(m_now), agent, '2026-10-15T11:00:00Z')),
    add(subject(run_now2, 'logs/discount-now.log', 'sha256:28a3707031369687b040d9bdf2ad89bba2123be3af93c78b285975c970478db0')),
    add(model_run(run_now2, m_now, 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db')),
    add(attest(a19, model_result, run_now2, verdict(m_now, sanity, sat), agent, '2026-10-15T11:10:00Z'))]).
expect(pl_div_run_not_fixed, 'model_diverges(M)', ['M = m_now']).

% L4. REVIEW 1 P3: the existing-world model must reproduce the bad case. A self-loop or a
% cycle in derived_from must not make it a "target" that skips this check.
variant(pl_derived_self_loop, [
    add(derived_from(m_now, m_now)),
    replace(attest(a5, model_result, run_now, verdict(m_now, bad_case, sat), agent, '2026-10-15T09:22:00Z'),
            attest(a5, model_result, run_now, verdict(m_now, bad_case, unsat), agent, '2026-10-15T09:22:00Z'))]).
% Changed from the review: m_now is no root, so m_target (a14: bad_case unsat) is no target either.
expect(pl_derived_self_loop, 'model_diverges(M)', ['M = m_now', 'M = m_target']).
expect(pl_derived_self_loop, 'discovery_ready', none).
expect(pl_derived_self_loop, 'lint_issue(''ED9'', Id, _)', ['Id = m_now', 'Id = m_target']).

variant(pl_derived_cycle, [
    add(derived_from(m_now, m_target)),
    replace(attest(a5, model_result, run_now, verdict(m_now, bad_case, sat), agent, '2026-10-15T09:22:00Z'),
            attest(a5, model_result, run_now, verdict(m_now, bad_case, unsat), agent, '2026-10-15T09:22:00Z'))]).
% Changed from the review: in a cycle neither model is a target, so both get the
% existing-world bad-case check, and m_target (a14: bad_case unsat) diverges too. ED9 flags the cycle.
expect(pl_derived_cycle, 'model_diverges(M)', ['M = m_now', 'M = m_target']).
expect(pl_derived_cycle, 'discovery_ready', none).
expect(pl_derived_cycle, 'lint_issue(''ED9'', Id, _)', ['Id = m_now', 'Id = m_target']).

% L5c. The decl says the largest budget counts (REVIEW 6 P13): a lowered budget is ignored.
variant(pl_budget_lowered, [
    add(budget(laps, 1)),
    replace(attest(a17, model_result, run_target, mutation(m_target, clamp, killed), agent, '2026-10-15T10:20:00Z'),
            attest(a17, model_result, run_target, mutation(m_target, clamp, survived), agent, '2026-10-15T10:20:00Z'))]).
expect(pl_budget_lowered, 'budget_spent', none).

% L5d. Raised budget, reached: spent (kills x158).
variant(pl_budget_raised_reached, [
    add(budget(laps, 5)),
    add(lap_done(2)), add(lap_done(3)), add(lap_done(4)), add(lap_done(5)),
    replace(attest(a17, model_result, run_target, mutation(m_target, clamp, killed), agent, '2026-10-15T10:20:00Z'),
            attest(a17, model_result, run_target, mutation(m_target, clamp, survived), agent, '2026-10-15T10:20:00Z'))]).
expect(pl_budget_raised_reached, 'budget_spent', true).
expect(pl_budget_raised_reached, 'discovery_decide', true).

% L6. Draft: "Only the human changes the scope." REVIEW 7 fix: "blocks readiness when a
% supersedes fact has no human answer or decision behind it." The agent alone supersedes
% c1, which is not refuted.
variant(pl_agent_supersedes_unrefuted, [
    add(claim(c1b, introduce, 'No order is charged below its floor price after all codes.')),
    add(cites(c1b, 'paid less than our minimum price')),
    add(supersedes(c1b, c1)),
    add(encodes(m_target, c1b)),
    add(attest(a18, model_result, run_target, verdict(m_target, applies(c1b), sat), agent, '2026-10-15T11:00:00Z'))]).

% Decision D4 (TICKET.md): superseding an undisputed claim needs no human answer.
expect(pl_agent_supersedes_unrefuted, 'discovery_unratified(C)', none).
expect(pl_agent_supersedes_unrefuted, 'discovery_ready', true).

% L6c. An unanswered question about c2b does not ratify (kills m171, x146).
variant(pl_unanswered_question, [
    add(question(q5, c2b, 'c2b fails when the floor is above the list price. Restrict it?')),
    add(assumed(q5, restrict)),
    add(attest(a18, disproof, m_target, verdict(c2b, refuted), agent, '2026-10-15T11:00:00Z')),
    add(claim(c2c, preserve, 'Each code takes off its full amount, down to the floor price, when the floor is at most the list price.')),
    add(cites(c2c, 'used two discount codes')),
    add(supersedes(c2c, c2b)),
    add(encodes(m_target, c2c)),
    add(attest(a19, model_result, run_target, verdict(m_target, preserve(c2c), unsat), agent, '2026-10-15T11:05:00Z'))]).
expect(pl_unanswered_question, 'discovery_unratified(C)', ['C = c2c']).
expect(pl_unanswered_question, 'discovery_ready', none).

% L6d. A human answer about the NEW claim ratifies it (decl of discovery_unratified; kills m175).
variant(pl_ratified_via_new, [
    add(attest(a18, disproof, m_target, verdict(c2b, refuted), agent, '2026-10-15T11:00:00Z')),
    add(claim(c2c, preserve, 'Each code takes off its full amount, down to the floor price, when the floor is at most the list price.')),
    add(cites(c2c, 'used two discount codes')),
    add(supersedes(c2c, c2b)),
    add(encodes(m_target, c2c)),
    add(attest(a19, model_result, run_target, verdict(m_target, preserve(c2c), unsat), agent, '2026-10-15T11:05:00Z')),
    add(question(q6, c2c, 'Restrict c2b to floors at most the list price?')),
    add(assumed(q6, yes)),
    add(answer(q6, yes, human))]).
expect(pl_ratified_via_new, 'discovery_unratified(C)', none).
expect(pl_ratified_via_new, 'discovery_ready', true).

% L8. A subject tagged both system and model is a model artifact (REVIEW 4; module comment).
variant(pl_tagged_both, [
    add(discovery_evidence(log4417, model))]).
expect(pl_tagged_both, 'lint_issue(''ED1'', Id, _)', ['Id = a1', 'Id = a9']).
expect(pl_tagged_both, 'discovery_hypothesis_touched(H)', none).
expect(pl_tagged_both, 'touched_system', true).
expect(pl_tagged_both, 'discovery_ready', none).

% L8b. A solver log tagged system is still not system evidence (kills m003).
variant(pl_run_tagged_system, [
    add(discovery_evidence(run_now, system)),
    replace(attest(a9, reproduction, log4417, confirms(f1), agent, '2026-10-15T09:35:00Z'),
            attest(a9, reproduction, run_now, confirms(f1), agent, '2026-10-15T09:35:00Z'))]).
expect(pl_run_tagged_system, 'finding_lead(F)', ['F = f1']).
expect(pl_run_tagged_system, 'lint_issue(''ED1'', Id, _)', ['Id = a9']).

% L8c. A model file tagged system is still not system evidence (kills m002).
variant(pl_model_tagged_system, [
    add(discovery_evidence(m_now, system)),
    replace(attest(a9, reproduction, log4417, confirms(f1), agent, '2026-10-15T09:35:00Z'),
            attest(a9, reproduction, m_now, confirms(f1), agent, '2026-10-15T09:35:00Z'))]).
expect(pl_model_tagged_system, 'finding_lead(F)', ['F = f1']).
expect(pl_model_tagged_system, 'lint_issue(''ED1'', Id, _)', ['Id = a9']).

% L8d. The only touch is a test result on an untagged check (kills m095, x024).
variant(pl_untagged_check_only, [
    delete(attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z')),
    delete(note(a1, 'The payment log shows that order 4417 was charged $25.00. Its floor is $30.00.')),
    delete(attest(a9, reproduction, log4417, confirms(f1), agent, '2026-10-15T09:35:00Z')),
    delete(note(a9, 'The log of order 4417 shows the clamp after the first code, and no clamp after the second code.')),
    delete(discovery_evidence(t1, system))]).
expect(pl_untagged_check_only, 'touched_system', none).
expect(pl_untagged_check_only, 'discovery_ready', none).

% L8e. The hypothesis result is on an untagged log while t1 is tagged (kills m097, x025).
variant(pl_untagged_log_hyp, [
    delete(discovery_evidence(log4417, system))]).
expect(pl_untagged_log_hyp, 'discovery_hypothesis_touched(H)', none).
expect(pl_untagged_log_hyp, 'lint_issue(''WD7'', Id, _)', ['Id = h1']).

% L9. REVIEW 5 / draft SIGNAL 3: no hypothesis means not ready (kills m186).
variant(pl_no_hypothesis, [
    delete(hypothesis(h1, defect, 'Two discount codes can price an order below the floor price.')),
    delete(attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z')),
    delete(note(a1, 'The payment log shows that order 4417 was charged $25.00. Its floor is $30.00.'))]).
expect(pl_no_hypothesis, 'discovery_ready', none).

% L10. Core D5: a dormant question on a contested current claim is to_ask; ready is clean
% only (R7), so it blocks (kills m197).
variant(pl_to_ask_blocks, [
    add(attest(a18, divergence, run_target, claim(c1), agent, '2026-10-15T11:00:00Z')),
    add(question(q2, c1, 'Is the floor per order or per item?')),
    add(assumed(q2, per_order))]).
expect(pl_to_ask_blocks, 'to_ask(Q)', ['Q = q2']).
expect(pl_to_ask_blocks, 'discovery_ready', none).

% L11. REVIEW 2 P7: a disagreement on a check that breaks nothing still blocks (kills m069).
variant(pl_disagree_root_cause, [
    add(attest(a18, model_result, run_now, verdict(m_now, root_cause(clamp_after_both_codes), sat), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_disagree_root_cause, 'lint_issue(''ED6'', Id, _)', ['Id = m_now']).
expect(pl_disagree_root_cause, 'discovery_ready', none).

% L12. REVIEW 1: a diverging model that encodes nothing still blocks (kills m066).
variant(pl_diverging_explorer, [
    add(subject(m_x, 'models/discount-target.smt2', 'sha256:ac17a45536f31f4c27d0f85194dc4690e2aca118122023697632ec30908b664b')),
    add(model(m_x, smt)),
    add(subject(run_x, 'logs/discount-target.log', 'sha256:5355c75966ab906302c1bf6e59c2347af104709df24b6acd5d653c266d232608')),
    add(model_run(run_x, m_x, 'sha256:ac17a45536f31f4c27d0f85194dc4690e2aca118122023697632ec30908b664b')),
    add(attest(a18, model_result, run_x, verdict(m_x, sanity, sat), agent, '2026-10-15T11:00:00Z')),
    add(attest(a19, model_result, run_x, calibration(m_x, case('Order 4417 with one code'), differs), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_diverging_explorer, 'model_diverges(M)', ['M = m_x']).
expect(pl_diverging_explorer, 'discovery_ready', none).

% L15. Draft TRAJECTORY verdicts: violated (with a trace) or holds. A TLA target that
% violates a preserved claim breaks it (kills x014, x213).
variant(pl_tla_preserve_violated, [
    add(subject(m_tla, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db')),
    add(model(m_tla, tla)),
    add(subject(run_tla, 'logs/discount-now.log', 'sha256:28a3707031369687b040d9bdf2ad89bba2123be3af93c78b285975c970478db0')),
    add(model_run(run_tla, m_tla, 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db')),
    add(attest(a18, model_result, run_tla, verdict(m_tla, sanity, reached), agent, '2026-10-15T11:00:00Z')),
    add(attest(a19, model_result, run_tla, calibration(m_tla, example(c1), matches), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, model_result, run_tla, verdict(m_tla, bad_case, violated), agent, '2026-10-15T11:00:00Z')),
    add(subject(m_tlt, 'models/discount-target.smt2', 'sha256:ac17a45536f31f4c27d0f85194dc4690e2aca118122023697632ec30908b664b')),
    add(model(m_tlt, tla)),
    add(subject(run_tlt, 'logs/discount-target.log', 'sha256:5355c75966ab906302c1bf6e59c2347af104709df24b6acd5d653c266d232608')),
    add(model_run(run_tlt, m_tlt, 'sha256:ac17a45536f31f4c27d0f85194dc4690e2aca118122023697632ec30908b664b')),
    add(derived_from(m_tlt, m_tla)),
    add(encodes(m_tlt, c2b)),
    add(attest(a21, model_result, run_tlt, verdict(m_tlt, sanity, reached), agent, '2026-10-15T11:00:00Z')),
    add(attest(a22, model_result, run_tlt, verdict(m_tlt, preserve(c2b), violated), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_tla_preserve_violated, 'model_unfiled_break(C)', ['C = c2b']).
expect(pl_tla_preserve_violated, 'discovery_ready', none).

% L15b. An existing-world TLA model whose bad-case invariant holds does not reproduce the
% problem (kills x016, x215).
variant(pl_tla_now_holds, [
    add(subject(m_tla, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db')),
    add(model(m_tla, tla)),
    add(subject(run_tla, 'logs/discount-now.log', 'sha256:28a3707031369687b040d9bdf2ad89bba2123be3af93c78b285975c970478db0')),
    add(model_run(run_tla, m_tla, 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db')),
    add(attest(a18, model_result, run_tla, verdict(m_tla, sanity, reached), agent, '2026-10-15T11:00:00Z')),
    add(attest(a19, model_result, run_tla, calibration(m_tla, example(c1), matches), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, model_result, run_tla, verdict(m_tla, bad_case, holds), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_tla_now_holds, 'model_diverges(M)', ['M = m_tla']).

% L15c. A clean TLA pair: decided checks with holds and reached make c2b falsifiable by a
% trusted TLA target (kills x009, x011).
variant(pl_tla_target_ok, [
    delete(encodes(m_target, c2b)),
    add(subject(m_tla, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db')),
    add(model(m_tla, tla)),
    add(subject(run_tla, 'logs/discount-now.log', 'sha256:28a3707031369687b040d9bdf2ad89bba2123be3af93c78b285975c970478db0')),
    add(model_run(run_tla, m_tla, 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db')),
    add(attest(a18, model_result, run_tla, verdict(m_tla, sanity, reached), agent, '2026-10-15T11:00:00Z')),
    add(attest(a19, model_result, run_tla, calibration(m_tla, example(c1), matches), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, model_result, run_tla, verdict(m_tla, bad_case, violated), agent, '2026-10-15T11:00:00Z')),
    add(subject(m_tlt, 'models/discount-target.smt2', 'sha256:ac17a45536f31f4c27d0f85194dc4690e2aca118122023697632ec30908b664b')),
    add(model(m_tlt, tla)),
    add(subject(run_tlt, 'logs/discount-target.log', 'sha256:5355c75966ab906302c1bf6e59c2347af104709df24b6acd5d653c266d232608')),
    add(model_run(run_tlt, m_tlt, 'sha256:ac17a45536f31f4c27d0f85194dc4690e2aca118122023697632ec30908b664b')),
    add(derived_from(m_tlt, m_tla)),
    add(encodes(m_tlt, c2b)),
    add(attest(a21, model_result, run_tlt, verdict(m_tlt, sanity, reached), agent, '2026-10-15T11:00:00Z')),
    add(attest(a22, model_result, run_tlt, verdict(m_tlt, preserve(c2b), holds), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_tla_target_ok, 'no_falsifier(C)', none).
expect(pl_tla_target_ok, 'model_trusted(M)', ['M = m_now', 'M = m_target', 'M = m_tla', 'M = m_tlt']).
expect(pl_tla_target_ok, 'discovery_ready', true).

% L16. REVIEW 2 P4 for applies: an introduced claim whose only check is unknown has no
% falsifier (kills m135, x091).
variant(pl_applies_unknown_only, [
    add(claim(c3, introduce, 'A code never takes off more than the list price.')),
    add(cites(c3, 'used two discount codes')),
    add(encodes(m_target, c3)),
    add(attest(a18, model_result, run_target, verdict(m_target, applies(c3), unknown), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_applies_unknown_only, 'no_falsifier(C)', ['C = c3']).
expect(pl_applies_unknown_only, 'discovery_ready', none).

% L17. REVIEW 11 m047: the falsifying model itself must be trusted (k_no_sanity_target does
% not assert this; kills x120).
variant(pl_untrusted_target_falsifier, [
    delete(attest(a13, model_result, run_target, verdict(m_target, sanity, sat), agent, '2026-10-15T10:20:00Z')),
    delete(note(a13, 'Check 4 is sat, so the target rules admit an order.'))]).
expect(pl_untrusted_target_falsifier, 'no_falsifier(C)', ['C = c2b']).
expect(pl_untrusted_target_falsifier, 'discovery_ready', none).

% L17b. A target derived from an uncalibrated model does not inherit from a different
% calibrated model (kills x079, x083).
variant(pl_derived_from_uncalibrated, [
    add(subject(m_x, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db')),
    add(model(m_x, smt)),
    add(subject(run_x, 'logs/discount-now.log', 'sha256:28a3707031369687b040d9bdf2ad89bba2123be3af93c78b285975c970478db0')),
    add(model_run(run_x, m_x, 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db')),
    add(attest(a18, model_result, run_x, verdict(m_x, sanity, sat), agent, '2026-10-15T11:00:00Z')),
    replace(derived_from(m_target, m_now), derived_from(m_target, m_x))]).
expect(pl_derived_from_uncalibrated, 'model_trusted(M)', ['M = m_now']).
expect(pl_derived_from_uncalibrated, 'no_falsifier(C)', ['C = c2b']).

% L17c. REVIEW 12: a reason for another rule of the same model does not excuse clamp
% (kills x142, x145, x166).
variant(pl_reason_other_rule, [
    replace(attest(a17, model_result, run_target, mutation(m_target, clamp, killed), agent, '2026-10-15T10:20:00Z'),
            attest(a17, model_result, run_target, mutation(m_target, clamp, survived), agent, '2026-10-15T10:20:00Z')),
    add(reason(m_target, floor_guard, 'The floor guard is checked elsewhere.'))]).
expect(pl_reason_other_rule, 'weak_rule(R)', ['R = clamp']).
expect(pl_reason_other_rule, 'lint_issue(''WD3'', Id, _)', ['Id = a17']).

% L18. REVIEW 3: an edited model keeps none of its old verdicts. Here the agent re-ran only
% the calibration at the new digest; the old sanity must not count (kills x254 alone).
variant(pl_edit_rerun_calibration_only, [
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'),
            subject(m_now, 'models/discount-now-v2.smt2', 'sha256:be087eaf26d6d7b83f5902ffb939fe1a7844451a3d66b144f86eeb2283be0025')),
    add(subject(run_now2, 'logs/discount-now.log', 'sha256:28a3707031369687b040d9bdf2ad89bba2123be3af93c78b285975c970478db0')),
    add(model_run(run_now2, m_now, 'sha256:be087eaf26d6d7b83f5902ffb939fe1a7844451a3d66b144f86eeb2283be0025')),
    add(attest(a18, model_result, run_now2, calibration(m_now, example(c1), matches), agent, '2026-10-15T11:10:00Z'))]).
expect(pl_edit_rerun_calibration_only, 'model_sane(M)', ['M = m_target']).
expect(pl_edit_rerun_calibration_only, 'model_trusted(M)', none).

% L18b. The reverse: the agent re-ran only the sanity check; the old calibration must not
% count (kills x255 alone).
variant(pl_edit_rerun_sanity_only, [
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'),
            subject(m_now, 'models/discount-now-v2.smt2', 'sha256:be087eaf26d6d7b83f5902ffb939fe1a7844451a3d66b144f86eeb2283be0025')),
    add(subject(run_now2, 'logs/discount-now.log', 'sha256:28a3707031369687b040d9bdf2ad89bba2123be3af93c78b285975c970478db0')),
    add(model_run(run_now2, m_now, 'sha256:be087eaf26d6d7b83f5902ffb939fe1a7844451a3d66b144f86eeb2283be0025')),
    add(attest(a18, model_result, run_now2, verdict(m_now, sanity, sat), agent, '2026-10-15T11:10:00Z'))]).
expect(pl_edit_rerun_sanity_only, 'model_calibrated(M)', none).
expect(pl_edit_rerun_sanity_only, 'model_trusted(M)', none).

% L20. A disproof on a claim that is no longer current does not block (core current/1).
variant(pl_disproof_superseded, [
    add(attest(a18, disproof, m_target, verdict(c2, refuted), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_disproof_superseded, 'refuted(C)', ['C = c2']).
expect(pl_disproof_superseded, 'some_current_refuted', none).
expect(pl_disproof_superseded, 'discovery_unratified(C)', none).
expect(pl_disproof_superseded, 'discovery_ready', true).

variant(pl_disproof_superseded_unanswered, [
    delete(answer(q1, floor_wins, human)),
    add(attest(a18, disproof, m_target, verdict(c2, refuted), agent, '2026-10-15T11:00:00Z'))]).
expect(pl_disproof_superseded_unanswered, 'question_waits(Q)', ['Q = q1']).
expect(pl_disproof_superseded_unanswered, 'discovery_unratified(C)', ['C = c2b']).
expect(pl_disproof_superseded_unanswered, 'discovery_ready', none).

% Intended (R7 "clean": no question waits; REVIEW 10 "keep the question_waits expectation as
% the guard"): a raised, unanswered question blocks readiness, with nothing else open.
variant(qw_hypothesis_question, [
    add(question(q2, c1, 'Order 4417 did not reproduce on staging. Is the log from production?')),
    add(assumed(q2, production)),
    add(raised_by(q2, h1))]).
expect(qw_hypothesis_question, 'question_waits(Q)', ['Q = q2']).
expect(qw_hypothesis_question, 'discovery_unratified(C)', none).
expect(qw_hypothesis_question, 'discovery_ready', none).

% cf1_no_answer after F3: the guard is masked by ED7 on c2b.
variant(qw_cf1, [delete(answer(q1, floor_wins, human))]).
expect(qw_cf1, 'question_waits(Q)', ['Q = q1']).
expect(qw_cf1, 'discovery_unratified(C)', ['C = c2b']).
