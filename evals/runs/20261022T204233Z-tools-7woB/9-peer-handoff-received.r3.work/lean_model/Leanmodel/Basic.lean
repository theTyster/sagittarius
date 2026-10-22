/-! Model of `Inventory.reserve` for one SKU. `reserved` and `qty` are `Int`,
as in Python; `stock` is the stock on hand (0 for an unknown SKU). -/

/-- `none` models `raise ValueError`; `some t` is the new reserved total. -/
def reserve (stock reserved qty : Int) : Option Int :=
  if reserved + qty > stock then none else some (reserved + qty)

/-- Apply reserves in order. A refused reserve leaves the total unchanged. -/
def reserveAll (stock : Int) : Int → List Int → Int
  | r, [] => r
  | r, q :: qs => reserveAll stock ((reserve stock r q).getD r) qs

#eval reserve 5 0 2   -- some 2
#eval reserve 5 4 2   -- none
#eval reserve 5 4 1   -- some 5
#eval reserve 0 0 1   -- none
#eval reserveAll 5 0 [4, 2, 1]  -- 5

/-- c1: reserve refuses exactly when the new total would exceed the stock. -/
theorem reserve_refuses_iff (stock reserved qty : Int) :
    reserve stock reserved qty = none ↔ reserved + qty > stock := by
  unfold reserve; split <;> simp_all

/-- c1: from a total within stock, no sequence of reserves takes it above stock. -/
theorem reserveAll_within_stock (stock r : Int) (qs : List Int) (h : r ≤ stock) :
    reserveAll stock r qs ≤ stock := by
  induction qs generalizing r with
  | nil => exact h
  | cons q qs ih =>
    unfold reserveAll reserve
    split
    · exact ih r h
    · simp only [Option.getD_some]; exact ih _ (by omega)
