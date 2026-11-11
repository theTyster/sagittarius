# HEURISTICS.md

How to attack each kind of work problem. One section per problem type: **Shape** (how to recognize
it), **Move** (what to do), **Trap** (the failure that actually happened here).

The bar for a new section: the trap is a real event, not a hypothetical. An honest gap beats an
invented section.

## A proof or test suite came back green

**Shape.** Everything passes. It looks done.

**Move.** Assume the green run checked the wrong thing until shown otherwise. Mutate the code: break
the rule the test is named for, and confirm the test goes red. A test that has never failed shows
nothing.

**Trap.** (Write your own first one here.)
