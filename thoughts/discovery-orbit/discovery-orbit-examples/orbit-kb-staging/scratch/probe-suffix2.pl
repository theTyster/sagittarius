% H3 probe: do run_1 and run_3 collapse to one atom in s(CASP) 1.1.4?
p(run_1).
p(order4417).
p(c2b).
p('Order 4417').
p(x_1y).
gap :- p(run_1), not p(run_3).
same :- run_1 = run_3.
