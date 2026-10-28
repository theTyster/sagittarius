/-
  Renewal transport change: design proof.

  Models the PROPOSED change: the renewal credential moves from the request body into an
  HttpOnly cookie. Pure functions and Hoare-style statements; no traces or timing this pass.

  `storedRenewalOk` is the server's stored renewal record for the session.
  The cookie's content is left opaque (`cookieValue`).
-/

inductive Outcome | renewed | signedOut
  deriving DecidableEq, Repr

structure Session where
  storedRenewalOk : Bool
  cookieValue     : Nat   -- opaque
  cookiePresent   : Bool

def renewViaBody (s : Session) : Outcome :=
  if s.storedRenewalOk then .renewed else .signedOut

def renewViaCookie (s : Session) : Outcome :=
  if s.cookiePresent then (if s.storedRenewalOk then .renewed else .signedOut) else .signedOut

/-- R-1: with the cookie present, the change is transport-only, not semantic. -/
theorem transport_only (s : Session) (h : s.cookiePresent = true) :
    renewViaCookie s = renewViaBody s := by
  unfold renewViaCookie renewViaBody; simp [h]

/-- R-2: a valid renewal never signs the user out. -/
theorem valid_renewal_keeps_session (s : Session) (hc : s.cookiePresent = true)
    (hv : s.storedRenewalOk = true) : renewViaCookie s = .renewed := by
  simp [renewViaCookie, hc, hv]

/-- R-3: a missing cookie signs out (no silent success). -/
theorem no_cookie_signs_out (s : Session) (hc : s.cookiePresent = false) :
    renewViaCookie s = .signedOut := by
  simp [renewViaCookie, hc]
