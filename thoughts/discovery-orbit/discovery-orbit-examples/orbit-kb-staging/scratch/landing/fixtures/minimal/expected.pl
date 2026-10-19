% Intended answers, written before the run.
% R7 call 3: "Discovery is ready with no current claim only on the not_reproduced (NO-GO) path."
% So the reproduced Small path with no claims is not ready (and the draft's Small size,
% "SIGNAL, SURVEY, and GO", can never reach discovery_ready).
expect(base, 'touched_system', true).
expect(base, 'discovery_has_outcome', none).
expect(base, 'discovery_ready', none).
expect(base, 'lint_issue(Code, Id, _)', none).

% R7 call 3, NO-GO path: no claim, the problem did not reproduce: ready, with WD6.
variant(nr, [
    replace(attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z'),
            attest(a1, reproduction, log4417, result(h1, not_reproduced), agent, '2026-10-15T09:10:00Z'))]).
expect(nr, 'discovery_has_outcome', true).
expect(nr, 'discovery_ready', true).
expect(nr, 'discovery_decide', true).
expect(nr, 'lint_issue(''WD6'', Id, _)', ['Id = a1']).

% The not_reproduced result is on an untagged subject: not a NO-GO outcome (kills m099, x027).
variant(nr_untagged, [
    replace(attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z'),
            attest(a1, reproduction, log4417, result(h1, not_reproduced), agent, '2026-10-15T09:10:00Z')),
    delete(discovery_evidence(log4417, system))]).
expect(nr_untagged, 'discovery_has_outcome', none).
expect(nr_untagged, 'discovery_ready', none).

% No hypothesis, no claim, only a request and a lap (REVIEW E3): not ready; decide only
% when the budget is spent.
variant(request_only, [
    delete(hypothesis(h1, defect, 'Two discount codes can price an order below the floor price.')),
    delete(attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z')),
    replace(budget(laps, 3), budget(laps, 1)),
    add(lap_done(1))]).
expect(request_only, 'discovery_ready', none).
expect(request_only, 'discovery_decide', true).
