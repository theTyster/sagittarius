/-! Model of `Inventory.reserve` in inventory.py.
A SKU that is not in the stock has stock 0 and reservation 0. -/

namespace Stock

structure Inv where
  stock : String → Int
  reserved : String → Int

def Inv.set (inv : Inv) (sku : String) (v : Int) : Inv :=
  { inv with reserved := fun k => if k = sku then v else inv.reserved k }

/-- `some (inv', total)` on success; `none` means ValueError, and the caller keeps `inv`. -/
def reserve (inv : Inv) (sku : String) (qty : Int) : Option (Inv × Int) :=
  if inv.reserved sku + qty > inv.stock sku then none
  else some (inv.set sku (inv.reserved sku + qty), inv.reserved sku + qty)

/-- Run a sequence of calls. A refused call leaves the state unchanged. -/
def runAll (inv : Inv) : List (String × Int) → Inv
  | [] => inv
  | (sku, qty) :: rest =>
    match reserve inv sku qty with
    | none => runAll inv rest
    | some (inv', _) => runAll inv' rest

def ok (inv : Inv) : Prop := ∀ k, inv.reserved k ≤ inv.stock k

def apple5 : Inv := ⟨fun k => if k = "apple" then 5 else 0, fun _ => 0⟩

#eval (reserve apple5 "apple" 2).map (·.2)                                  -- some 2
#eval ((reserve apple5 "apple" 4).bind fun (i, _) => reserve i "apple" 2).map (·.2) -- none
#eval ((reserve apple5 "apple" 2).bind fun (i, _) => reserve i "apple" 3).map (·.2) -- some 5
#eval (reserve apple5 "pear" 1).map (·.2)                                   -- none

/-- A call is refused exactly when the new total would exceed the stock. -/
theorem reserve_refuses_iff (inv : Inv) (sku : String) (qty : Int) :
    reserve inv sku qty = none ↔ inv.reserved sku + qty > inv.stock sku := by
  unfold reserve
  split <;> simp_all

/-- A call that succeeds returns the new total and changes only that SKU. -/
theorem reserve_some (inv inv' : Inv) (sku : String) (qty t : Int)
    (h : reserve inv sku qty = some (inv', t)) :
    t = inv.reserved sku + qty ∧ t ≤ inv.stock sku ∧ inv' = inv.set sku t := by
  unfold reserve at h
  split at h
  · simp at h
  · simp only [Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨h1, h2⟩ := h
    subst h1 h2
    exact ⟨rfl, by omega, rfl⟩

/-- One call keeps every reservation within stock. -/
theorem reserve_preserves_ok (inv inv' : Inv) (sku : String) (qty t : Int)
    (hok : ok inv) (h : reserve inv sku qty = some (inv', t)) : ok inv' := by
  obtain ⟨-, hle, rfl⟩ := reserve_some inv inv' sku qty t h
  intro k
  simp only [Inv.set]
  split
  · subst_vars; exact hle
  · exact hok k

/-- For every sequence of calls, from any state within stock,
    no reservation ever exceeds its stock. -/
theorem never_exceeds_stock (calls : List (String × Int)) (inv : Inv) (hok : ok inv) :
    ok (runAll inv calls) := by
  induction calls generalizing inv with
  | nil => exact hok
  | cons c rest ih =>
    obtain ⟨sku, qty⟩ := c
    simp only [runAll]
    split
    · exact ih inv hok
    · rename_i inv' t h
      exact ih inv' (reserve_preserves_ok inv inv' sku qty t hok h)

/-- The combined claim c1: a refused call is exactly one that would exceed stock,
    and every sequence of calls keeps all reservations within stock. -/
theorem c1_claim :
    (∀ inv sku qty, reserve inv sku qty = none ↔ inv.reserved sku + qty > inv.stock sku) ∧
    (∀ calls inv, ok inv → ok (runAll inv calls)) :=
  ⟨reserve_refuses_iff, never_exceeds_stock⟩

end Stock
