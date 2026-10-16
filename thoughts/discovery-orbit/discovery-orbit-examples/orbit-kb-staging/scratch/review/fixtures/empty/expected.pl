% Empty inputs. Intended answers per the draft: a ticket needs claims (SPECTRUM, "The ticket"),
% and SIGNAL needs a falsifiable hypothesis ("Do not guess a hypothesis to continue").

% E1: no claims, no models, no findings.
expect(base, 'touched_system', true).
expect(base, 'current(C)', none).
expect(base, 'discovery_ready', none).
expect(base, 'lint_issue(Code, Id, _)', none).

% E2: no hypothesis and no claims; one system finding confirmed by the log.
variant(e2_no_hypothesis, [
    delete(hypothesis(h1, defect, 'Two discount codes can price an order below the floor price.')),
    add(finding(f1, root_cause(clamp_after_first_code), system)),
    replace(attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z'),
            attest(a1, reproduction, log4417, confirms(f1), agent, '2026-10-15T09:10:00Z'))]).
expect(e2_no_hypothesis, 'discovery_ready', none).

% E3: nothing but a request and a spent budget.
variant(e3_budget_only, [
    delete(hypothesis(h1, defect, 'Two discount codes can price an order below the floor price.')),
    delete(subject(log4417, 'logs/order-4417.log', 'sha256:eb7c1b78c9b566eecc2b843bcfa4714537b0e739caf9608fc7aac528c3d94599')),
    delete(attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z')),
    add(budget(laps, 1)), add(lap_done(1))]).
expect(e3_budget_only, 'touched_system', none).
expect(e3_budget_only, 'discovery_ready', none).

% E4: the problem does not reproduce, and no finding records the divergence.
variant(e4_not_reproduced, [
    replace(attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z'),
            attest(a1, reproduction, log4417, result(h1, not_reproduced), agent, '2026-10-15T09:10:00Z'))]).
expect(e4_not_reproduced, 'discovery_ready', true).
expect(e4_not_reproduced, 'lint_issue(Code, Id, _)', none).
