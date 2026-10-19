uses([discovery]).
% LANDING probe: a "Small" discovery (draft "Sizes and speed": SIGNAL, SURVEY, and GO; the
% reproduction is the evidence). No claims.
request(r1, 'A customer used two discount codes and paid less than our minimum price.').
hypothesis(h1, defect, 'Two discount codes can price an order below the floor price.').
budget(laps, 3).
subject(log4417, 'logs/order-4417.log', 'sha256:eb7c1b78c9b566eecc2b843bcfa4714537b0e739caf9608fc7aac528c3d94599').
discovery_evidence(log4417, system).
attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z').
