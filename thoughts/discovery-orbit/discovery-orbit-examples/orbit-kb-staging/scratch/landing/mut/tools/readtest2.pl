:- initialization(main, main).
main(Argv) :- format("argv=~q~n", [Argv]), Argv = [F|_],
  ( current_op(P, T, scasp_syntax:not) -> format("op ~w ~w~n", [P, T]) ; writeln(noop) ),
  op(900, fy, scasp_syntax:not),
  ( current_op(P2, T2, scasp_syntax:not) -> format("op ~w ~w~n", [P2, T2]) ; writeln(noop) ),
  open(F, read, S), read_term(S, X, [module(scasp_syntax)]), print(X), nl.
