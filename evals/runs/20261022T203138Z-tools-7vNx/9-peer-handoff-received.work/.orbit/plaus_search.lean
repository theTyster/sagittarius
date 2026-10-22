import Plausible
import Reserveburn
-- counterexample search over stock, prior reserved, and qty for one SKU
example (st r q : Int) :
    (reserve ⟨fun _ => st, fun _ => r⟩ "a" q).isNone = decide (r + q > st) ∧
    (reserve ⟨fun _ => st, fun _ => r⟩ "a" q).all (fun p => decide (p.1.reserved "a" ≤ st)) = true := by
  plausible (config := { numInst := 1000 })
