import BurnModel

/-! `check.sh` runs this file. It prints the witness table and the axioms of each
theorem. `check.sh` fails when a theorem uses an axiom other than `propext`,
`Classical.choice`, and `Quot.sound` (for example `sorryAx`). -/

#eval Req.witnessTable

-- The requirements model is consistent (one system meets all twelve).
#print axioms Req.spec_satisfies
#print axioms Req.reach_iff
#print axioms Req.cycle_iff
#print axioms Req.open_blocks_done
#print axioms Req.progress_never_makes_done

-- The implementation model, on every state (LR2 and LR4: on the states where
-- each replaced claim is a claim).
#print axioms Rdz.impl_LR1
#print axioms Rdz.LR2_of
#print axioms Rdz.impl_LR3
#print axioms Rdz.LR4_of
#print axioms Rdz.impl_LR5
#print axioms Rdz.impl_LR6
#print axioms Rdz.impl_LR7
#print axioms Rdz.impl_not_LR8
#print axioms Rdz.impl_LR9
#print axioms Rdz.impl_LR10
#print axioms Rdz.impl_LR11
#print axioms Rdz.impl_LR12

-- The implementation model, on the well-formed states (lint E4 clean).
#print axioms Rdz.implWF_LR1
#print axioms Rdz.implWF_LR2
#print axioms Rdz.implWF_LR3
#print axioms Rdz.implWF_LR4
#print axioms Rdz.implWF_LR5
#print axioms Rdz.implWF_LR6
#print axioms Rdz.implWF_LR7
#print axioms Rdz.implWF_LR8
#print axioms Rdz.implWF_LR9
#print axioms Rdz.implWF_LR10
#print axioms Rdz.implWF_LR11
#print axioms Rdz.implWF_LR12
#print axioms Rdz.implWF_all

-- Fidelity of the implementation model, and the derived facts.
#print axioms Impl.any_burn_open_iff
#print axioms Impl.any_under_iff
#print axioms Impl.any_over_iff
#print axioms Impl.any_to_ask_iff
#print axioms Impl.derive_proof_changed
#print axioms Impl.derive_waiver_lapsed
#print axioms Impl.any_supersede_cycle_iff
#print axioms Impl.burn_iff
#print axioms Rdz.burn_of_burns
#print axioms Rdz.burns_of_burn
#print axioms Rdz.reach_eq
#print axioms Rdz.derive_addProgress
#print axioms Rdz.derive_addCheck
