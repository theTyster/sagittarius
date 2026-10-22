/-! Model of `Inventory.reserve` in inventory.py, for claim c1:
"reserve(sku, qty) raises ValueError and reserves nothing when the total reserved
for sku would exceed its stock on hand."

`stock` and `reserved` are total functions; an absent key reads as 0, as `dict.get(sku, 0)`.
Raising ValueError is modelled as `.error`, which carries no new state. -/

namespace Burn

structure Inv where
  stock : String → Int
  reserved : String → Int

def reserve (inv : Inv) (sku : String) (qty : Int) : Except String (Inv × Int) :=
  let total := inv.reserved sku + qty
  if total > inv.stock sku then .error "over stock"
  else .ok ({ inv with reserved := fun s => if s = sku then total else inv.reserved s }, total)

/-- Apply a sequence of calls. A refused call leaves the state as it was. -/
def run (inv : Inv) : List (String × Int) → Inv
  | [] => inv
  | (sku, qty) :: ops =>
    match reserve inv sku qty with
    | .ok (inv', _) => run inv' ops
    | .error _ => run inv ops

def Valid (inv : Inv) : Prop := ∀ s, inv.reserved s ≤ inv.stock s

def mk (stock : List (String × Int)) : Inv :=
  { stock := fun s => (stock.lookup s).getD 0, reserved := fun _ => 0 }

def outcome (inv : Inv) (sku : String) (qty : Int) : String :=
  match reserve inv sku qty with
  | .ok (_, t) => s!"ok {t}"
  | .error _ => "ValueError"

-- Examples (each matches a test in test_inventory.py).
#eval outcome (mk [("apple", 5)]) "apple" 2                    -- ok 2
#eval outcome (run (mk [("apple", 5)]) [("apple", 4)]) "apple" 2 -- ValueError
#eval (run (mk [("apple", 5)]) [("apple", 4), ("apple", 2)]).reserved "apple" -- 4
#eval outcome (mk [("apple", 5)]) "pear" 1                     -- ValueError
#eval outcome (run (mk [("apple", 5)]) [("apple", 4)]) "apple" 1 -- ok 5 (boundary)

-- Bounded counterexample search: every sequence of up to 3 calls with qty in -2..6
-- and stock 0..5 keeps reserved ≤ stock. Prints the number of failures.
#eval Id.run do
  let qs : List Int := [-2, -1, 0, 1, 2, 3, 4, 5, 6]
  let mut bad := 0
  for st in [0, 1, 2, 3, 4, 5] do
    for a in qs do for b in qs do for c in qs do
      let i := run (mk [("x", st)]) [("x", a), ("x", b), ("x", c)]
      if i.reserved "x" > i.stock "x" then bad := bad + 1
  return bad

theorem reserve_step (inv : Inv) (sku : String) (qty : Int) :
    (inv.reserved sku + qty > inv.stock sku → ∃ e, reserve inv sku qty = .error e) ∧
    (∀ inv' t, reserve inv sku qty = .ok (inv', t) →
      inv'.stock = inv.stock ∧ t = inv.reserved sku + qty ∧
      inv'.reserved sku = t ∧ inv'.reserved sku ≤ inv'.stock sku ∧
      ∀ s, s ≠ sku → inv'.reserved s = inv.reserved s) := by
  unfold reserve
  constructor
  · intro h; simp [h]
  · intro inv' t h
    by_cases hc : inv.reserved sku + qty > inv.stock sku
    · simp [hc] at h
    · simp [hc] at h
      obtain ⟨rfl, rfl⟩ := h
      refine ⟨rfl, rfl, by simp, by simp; omega, ?_⟩
      intro s hs; simp [hs]

theorem run_valid (inv : Inv) (ops : List (String × Int)) (h : Valid inv) :
    Valid (run inv ops) := by
  induction ops generalizing inv with
  | nil => exact h
  | cons op ops ih =>
    obtain ⟨sku, qty⟩ := op
    simp only [run]
    split
    · rename_i inv' t hr
      apply ih
      obtain ⟨hst, -, -, hle, hother⟩ := (reserve_step inv sku qty).2 inv' t hr
      intro s
      by_cases hs : s = sku
      · subst hs; exact hle
      · rw [hother s hs, hst]; exact h s
    · exact ih inv h

/-- Claim c1: a call that would take the reserved total above stock is refused with no
new state; an accepted call keeps reserved ≤ stock for its sku and touches no other sku;
and from any state with reserved ≤ stock, every sequence of calls keeps reserved ≤ stock. -/
theorem c1 :
    (∀ inv sku qty, inv.reserved sku + qty > inv.stock sku →
      ∃ e, reserve inv sku qty = .error e) ∧
    (∀ inv sku qty inv' t, reserve inv sku qty = .ok (inv', t) →
      inv'.stock = inv.stock ∧ t = inv.reserved sku + qty ∧ inv'.reserved sku = t ∧
      inv'.reserved sku ≤ inv'.stock sku ∧ ∀ s, s ≠ sku → inv'.reserved s = inv.reserved s) ∧
    (∀ inv ops, Valid inv → Valid (run inv ops)) :=
  ⟨fun inv sku qty => (reserve_step inv sku qty).1,
   fun inv sku qty => (reserve_step inv sku qty).2,
   run_valid⟩

end Burn
