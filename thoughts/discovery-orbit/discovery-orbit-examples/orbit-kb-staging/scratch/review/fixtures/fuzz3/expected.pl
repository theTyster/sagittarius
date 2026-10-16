% Expectations for the discovery-a fixture (Example A of the discovery orbit).
%
% variant(Name, Edits): Edits is a list of delete(Term), replace(OldTerm, NewTerm), or
%   add(Term). Edits match kb.pl terms by term equality. The base variant has no edits,
%   and it is implicit.
% expect(Variant, 'GOAL', Answers): Answers is true, none, or a list of binding atoms.
%   A list is compared as a set. Variables whose names start with _ are not shown.

% --- base: after lap 2, before GO. Nothing waits for the human. ---
expect(base, 'discovery_ready', true).
expect(base, 'touched_system', true).
expect(base, 'no_falsifier(C)', none).
expect(base, 'question_waits(Q)', none).
expect(base, 'unasked_finding(F)', none).
expect(base, 'finding_lead(F)', none).
expect(base, 'weak_rule(R)', none).
expect(base, 'model_trusted(M)', ['M = m_now', 'M = m_target']).
expect(base, 'current(C)', ['C = c1', 'C = c2b']).
expect(base, 'contested(C)', ['C = c1', 'C = c2']).
expect(base, 'to_ask(Q)', none).
expect(base, 'refuted(C)', none).
expect(base, 'about_system(F)', ['F = f1']).
expect(base, 'budget_spent', none).
expect(base, 'stale(A)', none).
expect(base, 'lint_issue(Code, Id, _)', none).
% Bindings that hold the renamed atoms. With log_4417, s(CASP) would bind S = log (H3).
expect(base, 'attest(A, reproduction, S, _, agent, _)', ['A = a1, S = log4417', 'A = a9, S = log4417']).
expect(base, 'attest(A, model_result, _, calibration(M, Case, R), _, _)', ['A = a4, M = m_now, Case = order4417, R = matches']).

% --- CF1: the human did not answer q1. ---
variant(cf1_no_answer, [delete(answer(q1, floor_wins, human))]).
expect(cf1_no_answer, 'question_waits(Q)', ['Q = q1']).
expect(cf1_no_answer, 'to_ask(Q)', ['Q = q1']).
expect(cf1_no_answer, 'discovery_ready', none).

% --- CF2: no calibration of m_now. Check t1 still falsifies c1, so only c2b is left. ---
variant(cf2_no_calibration, [
    delete(attest(a4, model_result, run_now, calibration(m_now, order4417, matches), agent, '2026-10-15T09:21:00Z')),
    delete(note(a4, 'The model gives 2500 cents for order 4417. The payment log shows 2500 cents.'))]).
expect(cf2_no_calibration, 'model_trusted(M)', none).
expect(cf2_no_calibration, 'no_falsifier(C)', ['C = c2b']).
expect(cf2_no_calibration, 'discovery_ready', none).
expect(cf2_no_calibration, 'lint_issue(Code, Id, _)', ['Code = ''WD2'', Id = m_target']).

% --- CF2b: no calibration and no check t1. Then c1 has no falsifier too. ---
variant(cf2b_no_calibration_no_check, [
    delete(attest(a4, model_result, run_now, calibration(m_now, order4417, matches), agent, '2026-10-15T09:21:00Z')),
    delete(note(a4, 'The model gives 2500 cents for order 4417. The payment log shows 2500 cents.')),
    delete(check(t1, c1)),
    delete(attest(a2, test_result, t1, result(t1, 1, fail), script, '2026-10-15T09:15:00Z'))]).
expect(cf2b_no_calibration_no_check, 'no_falsifier(C)', ['C = c1', 'C = c2b']).
expect(cf2b_no_calibration_no_check, 'discovery_ready', none).

% --- CF3: the current system did not confirm f1. A lead does not block readiness. ---
variant(cf3_no_confirmation, [
    delete(attest(a9, reproduction, log4417, confirms(f1), agent, '2026-10-15T09:35:00Z')),
    delete(note(a9, 'The log of order 4417 shows the clamp after the first code, and no clamp after the second code.'))]).
expect(cf3_no_confirmation, 'finding_lead(F)', ['F = f1']).
expect(cf3_no_confirmation, 'discovery_ready', true).
expect(cf3_no_confirmation, 'lint_issue(Code, Id, _)', ['Code = ''WD4'', Id = f1']).

% --- CF4: the conflict f2 raised no question. ---
variant(cf4_no_raised_by, [delete(raised_by(q1, f2))]).
expect(cf4_no_raised_by, 'unasked_finding(F)', ['F = f2']).
expect(cf4_no_raised_by, 'question_waits(Q)', none).
expect(cf4_no_raised_by, 'discovery_ready', none).
expect(cf4_no_raised_by, 'lint_issue(Code, Id, _)', ['Code = ''WD1'', Id = f2']).

% --- CF5: the clamp survived its mutation check. ---
variant(cf5_survived, [
    replace(attest(a17, model_result, run_target, mutation(m_target, clamp, killed), agent, '2026-10-15T10:20:00Z'),
            attest(a17, model_result, run_target, mutation(m_target, clamp, survived), agent, '2026-10-15T10:20:00Z'))]).
expect(cf5_survived, 'weak_rule(R)', ['R = clamp']).
expect(cf5_survived, 'discovery_ready', none).
expect(cf5_survived, 'lint_issue(Code, Id, _)', ['Code = ''WD3'', Id = a17']).

% --- CF5b: the clamp survived, and the agent recorded why. ---
variant(cf5b_survived_with_reason, [
    replace(attest(a17, model_result, run_target, mutation(m_target, clamp, killed), agent, '2026-10-15T10:20:00Z'),
            attest(a17, model_result, run_target, mutation(m_target, clamp, survived), agent, '2026-10-15T10:20:00Z')),
    add(reason(clamp, 'Another rule of the model also keeps the price at the floor.'))]).
expect(cf5b_survived_with_reason, 'weak_rule(R)', none).
expect(cf5b_survived_with_reason, 'discovery_ready', true).
expect(cf5b_survived_with_reason, 'lint_issue(Code, Id, _)', none).

% --- CF6 (decision 4): a solver counterexample refutes c2b. ---
variant(cf6_disproof, [
    add(attest(a18, disproof, m_target, verdict(c2b, refuted), agent, '2026-10-15T10:40:00Z')),
    add(note(a18, 'Without the domain bound floor <= list, Z3 finds an order whose floor is above its list price. The clamp then charges more than the list price.')),
    add(example(c2b, 'List $20.00, floor $30.00, one code $5.00. Charge $30.00, above the list price.'))]).
expect(cf6_disproof, 'refuted(C)', ['C = c2b']).
expect(cf6_disproof, 'some_current_refuted', true).
expect(cf6_disproof, 'discovery_ready', none).

% --- CF7: the budget is spent. Discovery is ready even with a weak rule open. ---
variant(cf7_budget_spent, [
    replace(attest(a17, model_result, run_target, mutation(m_target, clamp, killed), agent, '2026-10-15T10:20:00Z'),
            attest(a17, model_result, run_target, mutation(m_target, clamp, survived), agent, '2026-10-15T10:20:00Z')),
    replace(budget(laps, 3), budget(laps, 1))]).
expect(cf7_budget_spent, 'budget_spent', true).
expect(cf7_budget_spent, 'weak_rule(R)', ['R = clamp']).
expect(cf7_budget_spent, 'discovery_ready', true).

% --- CF8: the dormant question of the draft, on c1. The unsat-core divergence a11 contests
%     c1 for good, so the core to_ask/1 forces the question, and discovery is not ready. ---
variant(cf8_dormant_on_contested, [
    add(question(q2, c1, 'Is the floor per order or per item?')),
    add(assumed(q2, per_order))]).
expect(cf8_dormant_on_contested, 'to_ask(Q)', ['Q = q2']).
expect(cf8_dormant_on_contested, 'question_waits(Q)', none).
expect(cf8_dormant_on_contested, 'discovery_ready', none).

% --- GO (decision 5): the human approves the ticket at its digest. ---
variant(go, [
    add(subject(tk, 'ticket.md', 'sha256:5e571e9d0bdf90e0400972a7e2a8714b7bf5bdc1e81809a716fb5110d42142c0')),
    add(ticket(tk)),
    add(attest(a18, approval, tk, digest('sha256:5e571e9d0bdf90e0400972a7e2a8714b7bf5bdc1e81809a716fb5110d42142c0'), human, '2026-10-15T11:00:00Z'))]).
expect(go, 'stale(A)', none).
expect(go, 'discovery_ready', true).

% --- GO, then the ticket changed and orbit-kb subject recorded the new digest. ---
variant(go_stale, [
    add(subject(tk, 'ticket.md', 'sha256:6a41722a51e76235b68a3927463d330757b7a46dbe029f3d9eb41bcb94067db8')),
    add(ticket(tk)),
    add(attest(a18, approval, tk, digest('sha256:5e571e9d0bdf90e0400972a7e2a8714b7bf5bdc1e81809a716fb5110d42142c0'), human, '2026-10-15T11:00:00Z'))]).
expect(go_stale, 'stale(A)', ['A = a18']).

% --- HOLD (decision 5): a discovery decision by the human. It does not change readiness. ---
variant(hold, [
    add(attest(a18, decision, h1, hold(h1, 'Wait for the pricing team to confirm the floor rule.'), human, '2026-10-15T11:00:00Z'))]).
expect(hold, 'attest(A, decision, _, hold(H, _), human, _)', ['A = a18, H = h1']).
expect(hold, 'discovery_ready', true).

% --- The discovery lint errors: evidence on an id with no digest, a verdict on the model file. ---
variant(ed_bad_subjects, [
    replace(attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z'),
            attest(a1, reproduction, h1, result(h1, reproduced), agent, '2026-10-15T09:10:00Z')),
    replace(attest(a3, model_result, run_now, verdict(m_now, sanity, sat), agent, '2026-10-15T09:20:00Z'),
            attest(a3, model_result, m_now, verdict(m_now, sanity, sat), agent, '2026-10-15T09:20:00Z')),
    replace(attest(a5, model_result, run_now, verdict(m_now, bad_case, sat), agent, '2026-10-15T09:22:00Z'),
            attest(a5, model_result, t1, verdict(m_now, bad_case, sat), agent, '2026-10-15T09:22:00Z'))]).
expect(ed_bad_subjects, 'lint_issue(Code, Id, _)',
       ['Code = ''ED1'', Id = a1', 'Code = ''ED1'', Id = a5', 'Code = ''ED2'', Id = a3']).

% --- With the build module too: a model pass is not evidence about the code. ---
variant(with_build, [replace(uses([discovery]), uses([build, discovery]))]).
expect(with_build, 'fulfilled(C)', none).
expect(with_build, 'under(C)', ['C = c1', 'C = c2b']).
expect(with_build, 'done', none).
expect(with_build, 'discovery_ready', true).
