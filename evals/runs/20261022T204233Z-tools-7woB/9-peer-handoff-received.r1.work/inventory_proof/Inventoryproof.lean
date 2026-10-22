import Plausible

/-! Lean model of `Inventory.reserve` in inventory.py.
`none` models `raise ValueError`. Quantities are `Nat`: negative qty is out of scope. -/

abbrev Stock := String → Nat
abbrev Reserved := String → Nat

/-- One call of `reserve(sku, qty)`. An unknown SKU has stock 0. -/
def reserve (stock : Stock) (r : Reserved) (sku : String) (qty : Nat) : Option Reserved :=
  let total := r sku + qty
  if total > stock sku then none
  else some (fun s => if s = sku then total else r s)

/-- A sequence of calls. A refused call raises, and the reservation does not change. -/
def runAll (stock : Stock) (r : Reserved) : List (String × Nat) → Reserved
  | [] => r
  | (sku, qty) :: ops => runAll stock ((reserve stock r sku qty).getD r) ops

def appleStock : Stock := fun s => if s = "apple" then 5 else 0
def empty : Reserved := fun _ => 0

#eval (reserve appleStock empty "apple" 2).map (· "apple")                          -- some 2
#eval runAll appleStock empty [("apple", 4)] "apple"                                -- 4
#eval (reserve appleStock (runAll appleStock empty [("apple", 4)]) "apple" 2).isNone -- true
#eval runAll appleStock empty [("apple", 4), ("apple", 2), ("apple", 1)] "apple"   -- 5
#eval (reserve appleStock empty "pear" 1).isNone                                    -- true

/-- Counterexample search: for any stock and sequence of calls on one SKU, the total
reserved never exceeds the stock. -/
example : ∀ (n : Nat) (ops : List Nat),
    runAll (fun _ => n) empty (ops.map (fun q => ("a", q))) "a" ≤ n := by
  plausible

/-- `reserve` refuses exactly when the running total would exceed the stock on hand. -/
theorem reserve_refuses_iff (stock : Stock) (r : Reserved) (sku : String) (qty : Nat) :
    reserve stock r sku qty = none ↔ r sku + qty > stock sku := by
  unfold reserve
  by_cases hc : r sku + qty > stock sku <;> simp [hc]

/-- Starting within stock, every sequence of calls stays within stock for every SKU. -/
theorem runAll_within_stock (stock : Stock) (r : Reserved) (ops : List (String × Nat))
    (h : ∀ s, r s ≤ stock s) : ∀ s, runAll stock r ops s ≤ stock s := by
  induction ops generalizing r with
  | nil => exact h
  | cons op ops ih =>
    obtain ⟨sku, qty⟩ := op
    apply ih
    intro s
    unfold reserve
    by_cases hc : r sku + qty > stock sku
    · simp [hc, h s]
    · by_cases hs : s = sku
      · subst hs; simp [hc]; omega
      · simp [hc, hs, h s]

/-- The claim c1 in one statement: refusal is exact, and from an empty reservation
no sequence of calls reserves more than the stock on hand. -/
theorem c1_reserve_within_stock (stock : Stock) (ops : List (String × Nat)) :
    (∀ r sku qty, reserve stock r sku qty = none ↔ r sku + qty > stock sku) ∧
    (∀ s, runAll stock empty ops s ≤ stock s) :=
  ⟨reserve_refuses_iff stock, runAll_within_stock stock empty ops (fun _ => Nat.zero_le _)⟩
