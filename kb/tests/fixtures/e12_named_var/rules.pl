% rules for e12_named_var
bad_over(X) :- change(X, _), not serves(X, Y).  % <-- E12
