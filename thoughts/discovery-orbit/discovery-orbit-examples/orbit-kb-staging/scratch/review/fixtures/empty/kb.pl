uses([discovery]).
% Minimal KB: a request, a hypothesis, and one reproduction from the payment log.
% No claims, no models, no findings, no questions.
request(r1, 'A customer used two discount codes and paid less than our minimum price.').
hypothesis(h1, defect, 'Two discount codes can price an order below the floor price.').
subject(log4417, 'logs/order-4417.log', 'sha256:eb7c1b78c9b566eecc2b843bcfa4714537b0e739caf9608fc7aac528c3d94599').
attest(a1, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T09:10:00Z').
