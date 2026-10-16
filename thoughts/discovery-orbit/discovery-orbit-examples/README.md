# Discovery orbit examples

Worked examples for `../discovery-orbit-draft.md`. The code units, orders, and logs
are invented. Verified on 2026-10-15 with Z3 5.1.0, cvc5 1.3.4, and TLC 2.19
(08 August 2024, rev 5a47802).

## Example A: FLYBY (SMT)

```sh
z3 -T:10 discount-now.smt2
cvc5 --incremental --tlimit=10000 discount-now.smt2
z3 -T:10 discount-target.smt2
cvc5 --incremental --tlimit=10000 discount-target.smt2
```

cvc5 needs `--incremental` because the files use `push` and `pop`.

## Example B: TRAJECTORY (TLA+)

```sh
heavy tlc -config sanity-paid.cfg   -metadir states/a Checkout.tla
heavy tlc -config sanity-failed.cfg -metadir states/b Checkout.tla
heavy tlc -config now.cfg           -metadir states/c Checkout.tla
heavy tlc -config target.cfg        -metadir states/d Checkout.tla
heavy tlc -config target-final.cfg  -metadir states/e Checkout.tla
heavy tlc -config target-fail.cfg   -metadir states/f Checkout.tla
rm -r states
```

Expected results are in the comments of each file and in Part 4 of the draft.
