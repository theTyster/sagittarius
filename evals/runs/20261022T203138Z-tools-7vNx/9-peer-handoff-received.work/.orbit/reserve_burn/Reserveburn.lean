import Plausible

/-! Model of `Inventory.reserve` in inventory.py.
A SKU that is not in the stock dict has stock 0; a SKU that is not in
the reserved dict has 0 reserved. `none` models `raise ValueError`. -/

structure Store where
  stock : String → Int
  reserved : String → Int

def reserve (s : Store) (sku : String) (qty : Int) : Option (Store × Int) :=
  let total := s.reserved sku + qty
  if total > s.stock sku then none
  else some ({ s with reserved := Function.update' s.reserved sku total }, total)
where
  Function.update' (f : String → Int) (k : String) (v : Int) : String → Int :=
    fun k' => if k' = k then v else f k'

def apple5 : Store := { stock := fun k => if k = "apple" then 5 else 0, reserved := fun _ => 0 }

#eval (reserve apple5 "apple" 4).map (·.2)                                    -- some 4
#eval ((reserve apple5 "apple" 4).bind fun (s, _) => reserve s "apple" 2).map (·.2) -- none
#eval ((reserve apple5 "apple" 2).bind fun (s, _) => reserve s "apple" 3).map (·.2) -- some 5
#eval (reserve apple5 "pear" 1).map (·.2)                                     -- none

/-- c1: `reserve` refuses exactly when the new total would be more than the
stock on hand; when it accepts, the SKU's reserved total is that new total,
and it is at most the stock. -/
theorem reserve_refuses_over_stock (s : Store) (sku : String) (qty : Int) :
    (reserve s sku qty = none ↔ s.reserved sku + qty > s.stock sku) ∧
    ∀ s' t, reserve s sku qty = some (s', t) →
      s'.reserved sku = s.reserved sku + qty ∧ s'.reserved sku ≤ s.stock sku := by
  unfold reserve
  by_cases h : s.reserved sku + qty > s.stock sku
  · simp [h]
  · simp only [h, if_false]
    refine ⟨by simp [h], ?_⟩
    intro s' t hst
    simp only [Option.some.injEq, Prod.mk.injEq] at hst
    obtain ⟨rfl, -⟩ := hst
    simp [reserve.Function.update']
    omega
