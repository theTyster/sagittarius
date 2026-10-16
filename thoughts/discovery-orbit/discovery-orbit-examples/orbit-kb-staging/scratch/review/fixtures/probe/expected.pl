% Review probes on a copy of fixtures/discovery-a/kb.pl.
% Convention: discovery_ready / model_trusted / finding_lead / touched_system expectations
% state what the draft INTENDS. A FAIL on both engines shows a defect.
% lint_issue(...) none expectations record what the module DOES: a PASS means lint is silent.

expect(base, 'discovery_ready', true).

% P1: a second calibration case differs from the current system (draft: model and system
% disagree; fix the model before you use any of its verdicts).
variant(p1_calibration_differs, [
    add(attest(a18, model_result, run_now, calibration(m_now, onecode, differs), agent, '2026-10-15T09:23:00Z')),
    add(note(a18, 'One code of $5.00 on $40.00: the model gives 3500 cents, the log shows 3000 cents.'))]).
expect(p1_calibration_differs, 'model_trusted(M)', none).
expect(p1_calibration_differs, 'discovery_ready', none).
expect(p1_calibration_differs, 'lint_issue(Code, Id, _)', none).

% P2: the agent records the model-system disagreement as a core divergence on the model.
variant(p2_model_divergence, [
    add(attest(a18, divergence, run_now, model(m_now), agent, '2026-10-15T09:23:00Z')),
    add(note(a18, 'One code of $5.00 on $40.00: the model gives 3500 cents, the log shows 3000 cents.'))]).
expect(p2_model_divergence, 'model_trusted(M)', none).
expect(p2_model_divergence, 'discovery_ready', none).
expect(p2_model_divergence, 'lint_issue(Code, Id, _)', none).

% P3: the existing-world model does not reproduce the reported bad case.
variant(p3_bad_case_unsat_on_now, [
    replace(attest(a5, model_result, run_now, verdict(m_now, bad_case, sat), agent, '2026-10-15T09:22:00Z'),
            attest(a5, model_result, run_now, verdict(m_now, bad_case, unsat), agent, '2026-10-15T09:22:00Z'))]).
expect(p3_bad_case_unsat_on_now, 'discovery_ready', none).
expect(p3_bad_case_unsat_on_now, 'lint_issue(Code, Id, _)', none).

% P4: the only model check of c2b came back unknown (a gap, never UNSAT).
variant(p4_unknown, [
    replace(attest(a15, model_result, run_target, verdict(m_target, preserve(c2b), unsat), agent, '2026-10-15T10:20:00Z'),
            attest(a15, model_result, run_target, verdict(m_target, preserve(c2b), unknown), agent, '2026-10-15T10:20:00Z'))]).
expect(p4_unknown, 'no_falsifier(C)', ['C = c2b']).
expect(p4_unknown, 'discovery_ready', none).
expect(p4_unknown, 'lint_issue(Code, Id, _)', none).

% P5: vacuity: the introduced rule can never apply (honesty rule 4).
variant(p5_vacuous_applies, [
    replace(attest(a16, model_result, run_target, verdict(m_target, applies(c1), sat), agent, '2026-10-15T10:20:00Z'),
            attest(a16, model_result, run_target, verdict(m_target, applies(c1), unsat), agent, '2026-10-15T10:20:00Z'))]).
expect(p5_vacuous_applies, 'discovery_ready', none).
expect(p5_vacuous_applies, 'lint_issue(Code, Id, _)', none).

% P6: the target model violates the preserved claim c2b (a counterexample), no disproof filed.
variant(p6_target_violates_preserve, [
    replace(attest(a15, model_result, run_target, verdict(m_target, preserve(c2b), unsat), agent, '2026-10-15T10:20:00Z'),
            attest(a15, model_result, run_target, verdict(m_target, preserve(c2b), sat), agent, '2026-10-15T10:20:00Z'))]).
expect(p6_target_violates_preserve, 'discovery_ready', none).
expect(p6_target_violates_preserve, 'lint_issue(Code, Id, _)', none).

% P6b: the target bad case is SAT: c1 fails in the target model, no disproof filed.
variant(p6b_target_bad_case_sat, [
    replace(attest(a14, model_result, run_target, verdict(m_target, bad_case, unsat), agent, '2026-10-15T10:20:00Z'),
            attest(a14, model_result, run_target, verdict(m_target, bad_case, sat), agent, '2026-10-15T10:20:00Z'))]).
expect(p6b_target_bad_case_sat, 'discovery_ready', none).
expect(p6b_target_bad_case_sat, 'lint_issue(Code, Id, _)', none).

% P7: second solver disagrees on the same check (draft: a disagreement is loud).
variant(p7_solver_disagree, [
    add(attest(a18, model_result, run_target, verdict(m_target, preserve(c2b), sat), agent, '2026-10-15T10:21:00Z')),
    add(note(a18, 'cvc5 gives sat for check 3. Z3 gives unsat (a15).'))]).
expect(p7_solver_disagree, 'discovery_ready', none).
expect(p7_solver_disagree, 'lint_issue(Code, Id, _)', none).

% P8: the target model was edited and its sanity check is now UNSAT (encoding broken).
variant(p8_sanity_unsat_later, [
    add(attest(a18, model_result, run_target, verdict(m_target, sanity, unsat), agent, '2026-10-15T10:30:00Z'))]).
expect(p8_sanity_unsat_later, 'model_trusted(M)', ['M = m_now']).
expect(p8_sanity_unsat_later, 'discovery_ready', none).

% P9: the lead f1 is "confirmed" by the solver log of the model that produced it.
variant(p9_confirm_by_model_log, [
    replace(attest(a9, reproduction, log4417, confirms(f1), agent, '2026-10-15T09:35:00Z'),
            attest(a9, reproduction, run_now, confirms(f1), agent, '2026-10-15T09:35:00Z'))]).
expect(p9_confirm_by_model_log, 'finding_lead(F)', ['F = f1']).
expect(p9_confirm_by_model_log, 'lint_issue(Code, Id, _)', none).

% P9b: ... or by the model file itself.
variant(p9b_confirm_by_model_file, [
    replace(attest(a9, reproduction, log4417, confirms(f1), agent, '2026-10-15T09:35:00Z'),
            attest(a9, reproduction, m_now, confirms(f1), agent, '2026-10-15T09:35:00Z'))]).
expect(p9b_confirm_by_model_file, 'finding_lead(F)', ['F = f1']).
expect(p9b_confirm_by_model_file, 'lint_issue(Code, Id, _)', none).

% P10: no evidence from the current system at all; only the model log is cited as a
% "reproduction". touched_system should be false.
variant(p10_touch_by_model_log, [
    delete(attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z')),
    delete(note(a1, 'The payment log shows that order 4417 was charged $25.00. Its floor is $30.00.')),
    delete(attest(a2, test_result, t1, result(t1, 1, fail), script, '2026-10-15T09:15:00Z')),
    replace(attest(a9, reproduction, log4417, confirms(f1), agent, '2026-10-15T09:35:00Z'),
            attest(a9, reproduction, run_now, confirms(f1), agent, '2026-10-15T09:35:00Z'))]).
expect(p10_touch_by_model_log, 'touched_system', none).
expect(p10_touch_by_model_log, 'discovery_ready', none).
expect(p10_touch_by_model_log, 'lint_issue(Code, Id, _)', none).

% P12: budget spent while a question waits and a current claim is refuted.
variant(p12_budget_hides, [
    replace(budget(laps, 3), budget(laps, 1)),
    delete(answer(q1, floor_wins, human)),
    add(attest(a18, disproof, m_target, verdict(c2b, refuted), agent, '2026-10-15T10:40:00Z'))]).
expect(p12_budget_hides, 'question_waits(Q)', ['Q = q1']).
expect(p12_budget_hides, 'some_current_refuted', true).
expect(p12_budget_hides, 'discovery_ready', true).
expect(p12_budget_hides, 'lint_issue(Code, Id, _)', none).

% P12b: budget spent, and discovery never touched the current system.
variant(p12b_budget_no_system, [
    replace(budget(laps, 3), budget(laps, 1)),
    delete(attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z')),
    delete(note(a1, 'The payment log shows that order 4417 was charged $25.00. Its floor is $30.00.')),
    delete(attest(a2, test_result, t1, result(t1, 1, fail), script, '2026-10-15T09:15:00Z')),
    delete(attest(a9, reproduction, log4417, confirms(f1), agent, '2026-10-15T09:35:00Z')),
    delete(note(a9, 'The log of order 4417 shows the clamp after the first code, and no clamp after the second code.')),
    delete(finding(f1, root_cause(clamp_after_first_code), model))]).
expect(p12b_budget_no_system, 'touched_system', none).
expect(p12b_budget_no_system, 'discovery_ready', true).
expect(p12b_budget_no_system, 'lint_issue(Code, Id, _)', none).

% P13: the human raised the budget to 5 laps (append-only KB), 3 laps done, a weak rule open.
variant(p13_budget_raised, [
    add(budget(laps, 5)), add(lap_done(2)), add(lap_done(3)),
    replace(attest(a17, model_result, run_target, mutation(m_target, clamp, killed), agent, '2026-10-15T10:20:00Z'),
            attest(a17, model_result, run_target, mutation(m_target, clamp, survived), agent, '2026-10-15T10:20:00Z'))]).
expect(p13_budget_raised, 'budget_spent', none).
expect(p13_budget_raised, 'discovery_ready', none).

% P14: a reason recorded for one model's surviving mutation excuses another model's.
variant(p14_reason_crosses_models, [
    add(attest(a18, model_result, run_now, mutation(m_now, clamp, survived), agent, '2026-10-15T09:26:00Z')),
    add(reason(clamp, 'In m_now the clamp after the first code never binds for one code.')),
    replace(attest(a17, model_result, run_target, mutation(m_target, clamp, killed), agent, '2026-10-15T10:20:00Z'),
            attest(a17, model_result, run_target, mutation(m_target, clamp, survived), agent, '2026-10-15T10:20:00Z'))]).
expect(p14_reason_crosses_models, 'weak_rule(R)', ['R = clamp']).
expect(p14_reason_crosses_models, 'lint_issue(Code, Id, _)', none).

% P15: calibration against a case that the KB never observed in the current system.
variant(p15_calibrate_free_atom, [
    replace(attest(a4, model_result, run_now, calibration(m_now, order4417, matches), agent, '2026-10-15T09:21:00Z'),
            attest(a4, model_result, run_now, calibration(m_now, whatever_the_report_says, matches), agent, '2026-10-15T09:21:00Z'))]).
expect(p15_calibrate_free_atom, 'model_trusted(M)', ['M = m_now', 'M = m_target']).
expect(p15_calibrate_free_atom, 'lint_issue(Code, Id, _)', none).

% P16: c2b is refuted; the agent alone supersedes it with c2c. No human answer.
variant(p16_supersede_launders, [
    add(attest(a18, disproof, m_target, verdict(c2b, refuted), agent, '2026-10-15T10:40:00Z')),
    add(note(a18, 'Without floor <= list, Z3 finds a floor above the list price.')),
    add(claim(c2c, preserve, 'Each code takes off its full amount, down to the floor price, when the floor is at most the list price.')),
    add(supersedes(c2c, c2b)),
    add(cites(c2c, 'used two discount codes')),
    add(encodes(m_target, c2c))]).
expect(p16_supersede_launders, 'some_current_refuted', none).
expect(p16_supersede_launders, 'discovery_ready', none).
expect(p16_supersede_launders, 'lint_issue(Code, Id, _)', none).

% P17: the two dormant questions of draft Example A, which says "Nothing waits for the
% human. ready holds."
variant(p17_draft_dormant_questions, [
    add(question(q2, c1, 'Is the floor per order or per item?')),
    add(assumed(q2, per_order)),
    add(question(q3, c2b, 'Do percentage codes behave the same?')),
    add(assumed(q3, out_of_scope))]).
expect(p17_draft_dormant_questions, 'to_ask(Q)', none).
expect(p17_draft_dormant_questions, 'discovery_ready', true).

% P18: with build loaded, one later divergence on c1 (say, from DISPROVE) makes c1 a BURN
% claim, because the unsat-core bookkeeping divergence a11 counts as the first one.
variant(p18_burn_from_core, [
    replace(uses([discovery]), uses([build, discovery])),
    add(attest(a18, divergence, m_target, claim(c1), agent, '2026-10-15T10:50:00Z')),
    add(note(a18, 'DISPROVE: the floor rounds per item in the cart service.'))]).
expect(p18_burn_from_core, 'contested_twice(C)', none).
expect(p18_burn_from_core, 'burn(C)', none).

% P19: a verdict about m_target cites the log of the m_now run.
variant(p19_verdict_wrong_log, [
    replace(attest(a13, model_result, run_target, verdict(m_target, sanity, sat), agent, '2026-10-15T10:20:00Z'),
            attest(a13, model_result, run_now, verdict(m_target, sanity, sat), agent, '2026-10-15T10:20:00Z'))]).
expect(p19_verdict_wrong_log, 'lint_issue(Code, Id, _)', none).

% P20: coverage of clauses the fixture never exercises: surprise, trace, scope findings.
variant(p20_kinds, [
    add(finding(f3, surprise(charged_but_failed), model)),
    add(finding(f4, trace(charge_retry_charge), model)),
    add(finding(f5, scope(gift_cards), system)),
    add(finding(f6, root_cause(no_idempotency_key), system))]).
expect(p20_kinds, 'about_system(F)', ['F = f1', 'F = f3', 'F = f4', 'F = f6']).
expect(p20_kinds, 'needs_question(F)', ['F = f2', 'F = f3', 'F = f5']).
expect(p20_kinds, 'unasked_finding(F)', ['F = f3', 'F = f5']).
expect(p20_kinds, 'finding_lead(F)', ['F = f3', 'F = f4']).
expect(p20_kinds, 'discovery_ready', none).

% P21: a TLA model whose sanity result is "violated", as TLC reports it (draft Example B).
variant(p21_tla_sanity_violated, [
    add(subject(m_tla, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db')),
    add(model(m_tla, tla)),
    add(attest(a18, model_result, run_now, verdict(m_tla, sanity, violated), agent, '2026-10-15T10:50:00Z')),
    add(attest(a19, model_result, run_now, calibration(m_tla, order4417, matches), agent, '2026-10-15T10:51:00Z')),
    add(encodes(m_tla, c1))]).
expect(p21_tla_sanity_violated, 'model_trusted(M)', ['M = m_now', 'M = m_target', 'M = m_tla']).

% P22: a TLA target derived from the SMT existing-world model inherits its trust
% (draft step 7: statements in two tools must be built independently).
variant(p22_cross_tool_inherit, [
    add(subject(m_tla, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db')),
    add(model(m_tla, tla)),
    add(derived_from(m_tla, m_now)),
    add(attest(a18, model_result, run_now, verdict(m_tla, sanity, reached), agent, '2026-10-15T10:50:00Z')),
    add(encodes(m_tla, c1))]).
expect(p22_cross_tool_inherit, 'model_trusted(M)', ['M = m_now', 'M = m_target']).

% P23: the agent edits m_now (clamp after both codes) and re-records its subject, as
% orbit-kb subject does. Z3 on the edited file: calibration gives 3000 cents (log: 2500),
% and the bad case is UNSAT. No verdict was re-run. W1 stays clean (digest is current).
variant(p23_model_edited_after_calibration, [
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'),
            subject(m_now, 'models/discount-now-v2.smt2', 'sha256:be087eaf26d6d7b83f5902ffb939fe1a7844451a3d66b144f86eeb2283be0025'))]).
expect(p23_model_edited_after_calibration, 'model_trusted(M)', ['M = m_target']).
expect(p23_model_edited_after_calibration, 'discovery_ready', none).
expect(p23_model_edited_after_calibration, 'lint_issue(Code, Id, _)', none).

% P24: a second hypothesis that nothing ever touched (SIGNAL 4: ask the human if two
% hypotheses are one ticket or two; SURVEY 3: reproduce each defect).
variant(p24_second_hypothesis, [
    add(hypothesis(h2, defect, 'A payment retry after a timeout can charge an order twice.'))]).
expect(p24_second_hypothesis, 'discovery_ready', none).
expect(p24_second_hypothesis, 'lint_issue(Code, Id, _)', none).
