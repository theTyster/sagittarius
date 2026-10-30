/-- Model of `LOAN_DAYS` in loans.py: days a patron may keep each kind of item. -/
inductive Kind | novel | magazine | dvd | tool | reference
  deriving DecidableEq

def loanDays : Kind → Nat
  | .novel => 21
  | .magazine => 21
  | .dvd => 21
  | .tool => 21
  | .reference => 3

#eval [Kind.novel, .magazine, .dvd, .tool, .reference].map loanDays

/-- c3: every kind except reference gets 21 days. -/
theorem loan_21_except_reference (k : Kind) (h : k ≠ .reference) : loanDays k = 21 := by
  cases k <;> simp_all [loanDays]
