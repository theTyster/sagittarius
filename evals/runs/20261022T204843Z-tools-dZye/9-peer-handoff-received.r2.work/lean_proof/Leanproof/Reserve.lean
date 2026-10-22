import Plausible

/-! Model of `Inventory.reserve` for one sku.
`stock` is the stock on hand, `reserved` the total reserved so far, `qty` the request.
`none` models `raise ValueError` (state unchanged); `some t` models the new total `t`.
A missing sku has stock 0. Quantities are natural numbers. -/

def reserve (stock reserved qty : Nat) : Option Nat :=
  if reserved + qty > stock then none else some (reserved + qty)

/-- Apply a sequence of requests; a refused request leaves the state unchanged. -/
def reserveAll (stock : Nat) : Nat → List Nat → Nat
  | r, [] => r
  | r, q :: qs => reserveAll stock ((reserve stock r q).getD r) qs

#eval reserve 5 0 2   -- some 2
#eval reserve 5 4 2   -- none
#eval reserve 5 4 1   -- some 5
#eval reserve 0 0 1   -- none (missing sku)
#eval reserveAll 5 0 [4, 2, 1]  -- 5

/-- c1: reserve refuses exactly when the total would exceed the stock on hand,
and otherwise records the new total. -/
theorem reserve_refuses_over_stock (stock reserved qty : Nat) :
    (reserve stock reserved qty = none ↔ reserved + qty > stock) ∧
    (∀ t, reserve stock reserved qty = some t → t = reserved + qty ∧ t ≤ stock) := by
  unfold reserve
  constructor
  · split <;> simp_all
  · intro t h
    split at h
    · simp at h
    · simp at h; omega

/-- c1 over any sequence: from a state within stock, reserved never exceeds stock. -/
theorem reserveAll_within_stock (stock : Nat) :
    ∀ (qs : List Nat) (r : Nat), r ≤ stock → reserveAll stock r qs ≤ stock := by
  intro qs
  induction qs with
  | nil => intro r h; exact h
  | cons q qs ih =>
    intro r h
    apply ih
    unfold reserve
    split <;> simp <;> omega
