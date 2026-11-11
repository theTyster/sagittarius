/-!
# A properly written hypothesis

Definitions and theorems for `docs/PHILOSOPHY.md`, section "A properly written hypothesis".
Written by Fable on 2026-11-11 for the author's review. Nothing here is ratified.

How to read this file. The definitions are the part to judge: do they say what you mean?
Each theorem only shows what follows from the definitions. The Lean kernel checked every
proof. The last lines of the file print the axioms that each theorem uses.

Sections 1 to 8 are the definitions and what follows from them. Sections 9 and 10 are two
examples: a defect ("members got the wrong loyalty points") and a feature ("add a dark
mode", with the author's own attempt at its hypothesis). Section 11 shows what the
definition does not decide. Astra's review of the first version of this file found it.

Two words stay apart in this file. **Held** is about the statement: the statement needs
the word. A **guess** is about the human: the statement speaks about a case that nobody
has judged. A hypothesis can have every word held, and still guess. Section 3 has both.
Astra's review of the second version asked for this.

The author's words that this file tries to state exactly:

* "A properly written hypothesis is the weakest form of a statement that doesn't collapse
  (it is provable) and doesn't generalize so far as to lose its intent."
* "Remove words until one more removal makes the hypothesis collapse or change its meaning."
* "We call it a hypothesis because it's an attempt at defining the actual intent that the
  user is chasing."
* The question that a case asks the human: "is this case your intent?"
* "now you've got clear defaults to work from" (a default is a guess: section 3)
* "narrow down what was liked and what was disliked" (section 7)
-/

namespace Sagittarius

/-! ## 1. Cases and judgments

A `Case` is one concrete behavior: something that the system can show, and that the human
can judge. "A Gold member buys for 100 and gets 200 points" is a case.

Nothing in this file stands for the intent itself, because nobody holds it. All that exists
is what the human has said about cases so far.

The judgments belong to one ticket. The question is always: "is this case what you want
with this request?" A new wish that changes nothing in an old result is a new ticket, with
judgments of its own (section 7). -/

/-- What the human has judged so far. `some true`: "this case is my intent".
`some false`: "this case is not my intent". `none`: nobody has asked yet. -/
abbrev Judgments (Case : Type) := Case → Option Bool

/-- A statement of the intent, as a requirement: the cases that it accepts. -/
abbrev Req (Case : Type) := Case → Prop

section
variable {Case : Type}

/-- The human said that case `c` is the intent. -/
def Wanted (j : Judgments Case) (c : Case) : Prop := j c = some true

/-- The human said that case `c` is not the intent. -/
def Unwanted (j : Judgments Case) (c : Case) : Prop := j c = some false

/-- An intent falsifier of `R`: a judged case where `R` and the human disagree.
Either the human wants a case that `R` rejects, or the human rejects a case that `R`
accepts. The human is the witness. -/
def IntentFalsifier (j : Judgments Case) (R : Req Case) (c : Case) : Prop :=
  (Wanted j c ∧ ¬ R c) ∨ (Unwanted j c ∧ R c)

/-- `R` fits the judgments: no judged case disagrees with it. While the intent is still
being found, this is all that "does not lose its intent" can mean. -/
def Fits (j : Judgments Case) (R : Req Case) : Prop := ∀ c, ¬ IntentFalsifier j R c

/-- `R` has collapsed: it accepts every case. No result can show a build wrong. -/
def Collapsed (R : Req Case) : Prop := ∀ c, R c

/-- A statement is out: a judged case refutes it, or it has collapsed. -/
def Out (j : Judgments Case) (R : Req Case) : Prop :=
  (∃ c, IntentFalsifier j R c) ∨ Collapsed R

/-- No case is both wanted and unwanted. -/
theorem not_wanted_and_unwanted (j : Judgments Case) (c : Case)
    (hw : Wanted j c) (hu : Unwanted j c) : False := by
  have h : some true = some false := hw.symm.trans hu
  cases h

/-! ## 2. A hypothesis is premises and claims

A premise says when the hypothesis applies. A claim says what must then hold.
Each premise and each claim is one "word": one part that can be removed. -/

/-- A hypothesis: named premises and named claims. -/
structure Hyp (Case : Type) where
  Premise : Type
  Claim : Type
  premise : Premise → Req Case
  claim : Claim → Req Case

/-- What a hypothesis requires of a case: if every premise holds, then every claim holds. -/
def Hyp.req (h : Hyp Case) : Req Case :=
  fun c => (∀ p, h.premise p c) → ∀ q, h.claim q c

/-- The hypothesis with the premise `p₀` removed. -/
def Hyp.withoutPremise (h : Hyp Case) (p₀ : h.Premise) : Req Case :=
  fun c => (∀ p, p ≠ p₀ → h.premise p c) → ∀ q, h.claim q c

/-- The hypothesis with the claim `q₀` removed. -/
def Hyp.withoutClaim (h : Hyp Case) (q₀ : h.Claim) : Req Case :=
  fun c => (∀ p, h.premise p c) → ∀ q, q ≠ q₀ → h.claim q c

/-- "Assume little." With one premise less, the hypothesis demands more: a case that it
still accepts, the full hypothesis accepted too. -/
theorem fewer_premises_demand_more (h : Hyp Case) (p₀ : h.Premise) (c : Case) :
    h.withoutPremise p₀ c → h.req c :=
  fun hw hp => hw (fun p _ => hp p)

/-- With one claim less, the hypothesis demands less: it accepts all that it accepted
before, and maybe more. -/
theorem fewer_claims_demand_less (h : Hyp Case) (q₀ : h.Claim) (c : Case) :
    h.req c → h.withoutClaim q₀ c :=
  fun hr hp q _ => hr hp q

/-- A premise is held in place: the statement needs it. Without it, the statement is out. -/
def PremiseHeld (j : Judgments Case) (h : Hyp Case) (p : h.Premise) : Prop :=
  Out j (h.withoutPremise p)

/-- A claim is held in place: the statement needs it. Without it, the statement is out.

A word that is not held is spare: without it, the statement still fits, and it can still
fail. Remove a spare word, or show the human the case that would hold it.

"Held" is about the statement. It does not say that the human agrees with what the word
says. Section 3 keeps the two apart. -/
def ClaimHeld (j : Judgments Case) (h : Hyp Case) (q : h.Claim) : Prop :=
  Out j (h.withoutClaim q)

/-- The hypothesis has an example: a case that meets its premises and its claims.
A statement with no example cannot be met: no build can fulfill it. -/
def Hyp.HasExample (h : Hyp Case) : Prop :=
  ∃ c, (∀ p, h.premise p c) ∧ ∀ q, h.claim q c

/-- **Properly written**, for the judgments so far.

1. `fits`: it does not lose the intent. No judged case disagrees with it.
2. `can_hold`: it has an example. Some case meets it, so a build can fulfill it.
3. `can_fail`: it has a falsifier. Some case would show a build wrong.
4. `premises_held`, `claims_held`: no word can be removed. Every premise and every claim
   is held in place. No word is spare.

Points 2 and 3 together are "it does not collapse": it is not true of every case, and it
is not false of every case.

Properly written is a test of the form of an attempt, for what is known so far. It is not
a confirmation by the human (section 3). -/
structure ProperlyWritten (j : Judgments Case) (h : Hyp Case) : Prop where
  fits : Fits j h.req
  can_hold : h.HasExample
  can_fail : ¬ Collapsed h.req
  premises_held : ∀ p, PremiseHeld j h p
  claims_held : ∀ q, ClaimHeld j h q

/-! ## 3. What holds each word in place, and what a guess is

"Held" and "confirmed" are two judgments. Held: the statement needs the word. Confirmed:
the human judged a case that way. This section keeps them apart.

* A premise of a properly written hypothesis always has a judged case behind it
  (`premise_held_by_wanted_case`).
* A claim has a judged case behind it (`ClaimSupported`), or it is all that keeps the
  statement from collapse (`ClaimIsCore`), or both (`claim_held_two_ways`).
* With no judgment at all, a statement can still be properly written
  (`proper_with_no_judgments`). So "properly written" does not mean "confirmed".
* A guess is what a statement says about a case that nobody has judged (`Unjudged`). The
  judgments do not test it (`fits_ignores_unjudged`).

This is why "is this case your intent?" is the question to ask. A judged case is the only
thing that turns a guess into support. -/

/-- What holds a premise in place: a case that the human wants, and that the hypothesis
would reject without that premise. -/
theorem premise_held_by_wanted_case (j : Judgments Case) (h : Hyp Case)
    (hp : ProperlyWritten j h) (p₀ : h.Premise) :
    ∃ c, Wanted j c ∧ ¬ h.withoutPremise p₀ c := by
  cases hp.premises_held p₀ with
  | inl hf =>
    cases hf with
    | intro c hc =>
      cases hc with
      | inl hw => exact ⟨c, hw⟩
      | inr hu =>
        exact absurd (Or.inr ⟨hu.1, fewer_premises_demand_more h p₀ c hu.2⟩) (hp.fits c)
  | inr hcol =>
    exact absurd (fun c => fewer_premises_demand_more h p₀ c (hcol c)) hp.can_fail

/-- The human supports the claim `q`: the human rejected a case that the hypothesis
rejects, and that it would accept without `q`. -/
def ClaimSupported (j : Judgments Case) (h : Hyp Case) (q : h.Claim) : Prop :=
  ∃ c, Unwanted j c ∧ ¬ h.req c ∧ h.withoutClaim q c

/-- The claim `q` is the core of the attempt: without it, the statement accepts every
case. The statement needs `q`. That alone is no support from the human. -/
def ClaimIsCore (h : Hyp Case) (q : h.Claim) : Prop := Collapsed (h.withoutClaim q)

/-- What holds a claim in place, in a properly written hypothesis. The human supports
it, or it is the core of the attempt. Both can be true at once. -/
theorem claim_held_two_ways (j : Judgments Case) (h : Hyp Case)
    (hp : ProperlyWritten j h) (q₀ : h.Claim) :
    ClaimSupported j h q₀ ∨ ClaimIsCore h q₀ := by
  cases hp.claims_held q₀ with
  | inl hf =>
    cases hf with
    | intro c hc =>
      cases hc with
      | inl hw =>
        exact absurd
          (Or.inl ⟨hw.1, fun hr => hw.2 (fewer_claims_demand_less h q₀ c hr)⟩) (hp.fits c)
      | inr hu =>
        exact Or.inl ⟨c, hu.1, fun hr => hp.fits c (Or.inr ⟨hu.1, hr⟩), hu.2⟩
  | inr hcol => exact Or.inr hcol

/-- At such a case, the claim itself is false. So the case is the falsifier of that claim:
the concrete behavior that this claim, and no other, forbids. -/
theorem claim_false_at_its_case (h : Hyp Case) [DecidableEq h.Claim] (q₀ : h.Claim) (c : Case)
    (hr : ¬ h.req c) (hw : h.withoutClaim q₀ c) : ¬ h.claim q₀ c :=
  fun hq => hr (fun hp q =>
    if e : q = q₀ then e ▸ hq else hw hp q e)

/-- A hypothesis with no premise and one claim. -/
def oneClaim (R : Req Case) : Hyp Case where
  Premise := Empty
  Claim := Unit
  premise := fun p => nomatch p
  claim := fun _ => R

/-- **Held is not confirmed.** The human has judged nothing. A statement with one claim
that some case meets and some case fails is properly written all the same. Its claim is
held only against collapse. No judgment supports what it says. -/
theorem proper_with_no_judgments (R : Req Case) (c₁ c₂ : Case) (h₁ : R c₁) (h₂ : ¬ R c₂) :
    ProperlyWritten (fun _ => none) (oneClaim R) where
  fits := by
    intro c hf
    cases hf with
    | inl hw =>
      have e : (none : Option Bool) = some true := hw.1
      cases e
    | inr hu =>
      have e : (none : Option Bool) = some false := hu.1
      cases e
  can_hold := ⟨c₁, And.intro (fun p => nomatch p) (fun _ => h₁)⟩
  can_fail := fun hc => h₂ (hc c₂ (fun p => nomatch p) ())
  premises_held := fun p => nomatch p
  claims_held := fun _ => Or.inr (fun _ _ q hq => absurd rfl hq)

/-- Nobody has judged the case `c` yet. What a statement says about `c` is a **guess**: a
default of its writer, with no support from the human. -/
def Unjudged (j : Judgments Case) (c : Case) : Prop := j c = none

/-- **The judgments do not test a guess.** When two statements agree on every judged
case, and one of them fits, the other fits too. What each one says about the other cases
is free. -/
theorem fits_ignores_unjudged (j : Judgments Case) (R R' : Req Case)
    (hsame : ∀ c, ¬ Unjudged j c → (R c ↔ R' c)) : Fits j R → Fits j R' := by
  intro hf c hc
  cases hc with
  | inl hw =>
    have hj : ¬ Unjudged j c := fun hn => by
      have e : some true = none := hw.1.symm.trans hn
      cases e
    exact hf c (Or.inl ⟨hw.1, fun hr => hw.2 ((hsame c hj).mp hr)⟩)
  | inr hu =>
    have hj : ¬ Unjudged j c := fun hn => by
      have e : some false = none := hu.1.symm.trans hn
      cases e
    exact hf c (Or.inr ⟨hu.1, (hsame c hj).mpr hu.2⟩)

/-! ## 4. The system is the second witness -/

/-- A system: the cases that it can show. -/
abbrev System (Case : Type) := Case → Prop

/-- A system falsifier of `R`: a case that the system shows and that `R` rejects.
A failing check is one. The system is the witness. -/
def SystemFalsifier (S : System Case) (R : Req Case) (c : Case) : Prop := S c ∧ ¬ R c

/-- The system fulfills `R`: `R` accepts every case that the system shows. -/
def Fulfills (S : System Case) (R : Req Case) : Prop := ∀ c, S c → R c

/-- A collapsed statement cannot fail: every system fulfills it. Its checks pass, and the
pass says nothing. This is the quiet failure. -/
theorem collapsed_cannot_fail (R : Req Case) (hc : Collapsed R) (S : System Case) :
    Fulfills S R :=
  fun c _ => hc c

/-- A failing check shows that the statement can fail. This is why a check of a change
must fail before the change. -/
theorem red_shows_it_can_fail (S : System Case) (R : Req Case) (c : Case)
    (hf : SystemFalsifier S R c) : ¬ Collapsed R :=
  fun hc => hf.2 (hc c)

/-- A premise that the system never meets: the hypothesis cannot fail for that system,
whatever its claims say. A theorem that rests on a fact that the system does not have is
of this kind. -/
theorem unmet_premise_cannot_fail (S : System Case) (h : Hyp Case)
    (hu : ∀ c, S c → ¬ ∀ p, h.premise p c) : Fulfills S h.req :=
  fun c hs hp => absurd hp (hu c hs)

/-! ## 5. Which one is wrong: the build, or the hypothesis?

The system shows a case, and the hypothesis rejects it. That alone does not say which one
is wrong. The human's judgment of that case says it. -/

/-- The human rejects the case too. The hypothesis is right about it, so the build is
wrong. Fix the build. -/
theorem stay_in_build (j : Judgments Case) (S : System Case) (R : Req Case) (c : Case)
    (hs : S c) (hr : ¬ R c) (hj : Unwanted j c) :
    SystemFalsifier S R c ∧ ¬ IntentFalsifier j R c := by
  refine ⟨⟨hs, hr⟩, ?_⟩
  intro hf
  cases hf with
  | inl hw => exact not_wanted_and_unwanted j c hw.1 hj
  | inr hu => exact hr hu.2

/-- The human wants the case. It is an intent falsifier, so the hypothesis is wrong.
The hypothesis must change. -/
theorem hypothesis_must_change (j : Judgments Case) (R : Req Case) (c : Case)
    (hr : ¬ R c) (hj : Wanted j c) : IntentFalsifier j R c :=
  Or.inl ⟨hj, hr⟩

/-! ## 6. Discovery keeps what it learned -/

/-- The later judgments keep every earlier one. -/
def Extends (j j' : Judgments Case) : Prop := ∀ c v, j c = some v → j' c = some v

/-- A falsifier that was found stays found. -/
theorem falsifier_stays (j j' : Judgments Case) (R : Req Case) (c : Case)
    (he : Extends j j') : IntentFalsifier j R c → IntentFalsifier j' R c := by
  intro hf
  cases hf with
  | inl hw => exact Or.inl ⟨he c true hw.1, hw.2⟩
  | inr hu => exact Or.inr ⟨he c false hu.1, hu.2⟩

/-- A statement that was out stays out. -/
theorem out_stays (j j' : Judgments Case) (R : Req Case) (he : Extends j j') :
    Out j R → Out j' R := by
  intro ho
  cases ho with
  | inl hf =>
    cases hf with
    | intro c hc => exact Or.inl ⟨c, falsifier_stays j j' R c he hc⟩
  | inr hc => exact Or.inr hc

/-- A new judgment can break a fit. It cannot make one. -/
theorem fits_before (j j' : Judgments Case) (R : Req Case) (he : Extends j j') :
    Fits j' R → Fits j R :=
  fun hf c hc => hf c (falsifier_stays j j' R c he hc)

/-- A premise that is held stays held. (A word that nothing holds can become held. The
reverse does not happen while the judgments are kept.) -/
theorem premise_held_stays (j j' : Judgments Case) (h : Hyp Case) (p : h.Premise)
    (he : Extends j j') : PremiseHeld j h p → PremiseHeld j' h p :=
  fun ho => out_stays j j' (h.withoutPremise p) he ho

/-- A claim that is held stays held. -/
theorem claim_held_stays (j j' : Judgments Case) (h : Hyp Case) (q : h.Claim)
    (he : Extends j j') : ClaimHeld j h q → ClaimHeld j' h q :=
  fun ho => out_stays j j' (h.withoutClaim q) he ho

/-- A properly written hypothesis stays properly written until a new judgment disagrees
with it. Only an intent falsifier unseats it. That is the sense in which it is an attempt,
and the law of its ticket while it stands. -/
theorem proper_until_falsified (j j' : Judgments Case) (h : Hyp Case) (he : Extends j j')
    (hp : ProperlyWritten j h) (hf : Fits j' h.req) : ProperlyWritten j' h :=
  ⟨hf, hp.can_hold, hp.can_fail,
   fun p => premise_held_stays j j' h p he (hp.premises_held p),
   fun q => claim_held_stays j j' h q he (hp.claims_held q)⟩

/-! ## 7. When the intent moves: keep what the human still wants

The human liked a result, and now wants part of it changed. Some judgments reverse.
`D` is the part that the change touches: the cases whose judgment can change.
"Narrow down what was liked and what was disliked" is: make `D` as small as it can be. -/

/-- The later judgments keep every earlier one outside `D`. -/
def KeepsOutside (D : Case → Prop) (j j' : Judgments Case) : Prop :=
  ∀ c v, ¬ D c → j c = some v → j' c = some v

/-- When the change touches nothing, every judgment is kept: this is plain discovery.
A new wish that changes nothing in the old result is of this kind. It is a new ticket. -/
theorem keepsOutside_nothing (j j' : Judgments Case) :
    KeepsOutside (fun _ => False) j j' ↔ Extends j j' :=
  ⟨fun h c v hj => h c v (fun hd => hd) hj, fun h c v _ hj => h c v hj⟩

/-- Outside the part that changed, a falsifier that was found stays found. -/
theorem falsifier_stays_outside (D : Case → Prop) (j j' : Judgments Case) (R : Req Case)
    (c : Case) (hk : KeepsOutside D j j') (hc : ¬ D c) :
    IntentFalsifier j R c → IntentFalsifier j' R c := by
  intro hf
  cases hf with
  | inl hw => exact Or.inl ⟨hk c true hc hw.1, hw.2⟩
  | inr hu => exact Or.inr ⟨hk c false hc hu.1, hu.2⟩

/-- The narrower the change, the more is kept. -/
theorem narrower_keeps_more (D D' : Case → Prop) (j j' : Judgments Case)
    (hsub : ∀ c, D c → D' c) : KeepsOutside D j j' → KeepsOutside D' j j' :=
  fun hk c v hc hj => hk c v (fun hd => hc (hsub c hd)) hj

/-! ## 8. One case decides between two attempts (the oscillation, as one step) -/

/-- Two statements disagree on a case: `R` accepts it and `R'` rejects it. Show that case
to the human and ask: "is this case your intent?" Whatever the answer is, exactly one of
the two statements gets an intent falsifier.

For a word of a hypothesis, take `R` and `R'` to be the hypothesis with the word and
without it. The case on which they disagree is the case just past the boundary. The
answer holds the word in place, or it removes the word. -/
theorem one_case_decides (j : Judgments Case) (R R' : Req Case) (c : Case)
    (hr : R c) (hr' : ¬ R' c) :
    (Wanted j c → IntentFalsifier j R' c ∧ ¬ IntentFalsifier j R c) ∧
    (Unwanted j c → IntentFalsifier j R c ∧ ¬ IntentFalsifier j R' c) := by
  constructor
  · intro hw
    refine ⟨Or.inl ⟨hw, hr'⟩, ?_⟩
    intro hf
    cases hf with
    | inl h => exact h.2 hr
    | inr h => exact not_wanted_and_unwanted j c hw h.1
  · intro hu
    refine ⟨Or.inr ⟨hu, hr⟩, ?_⟩
    intro hf
    cases hf with
    | inl h => exact not_wanted_and_unwanted j c h.1 hu
    | inr h => exact hr' h.2

end

/-! ## 9. A defect: "members got the wrong loyalty points"

Three attempts at one report. The definitions give each the verdict that the prompt gives
it: too strong, collapsed, and fit. -/

/-- One purchase, as the system shows it. -/
structure Purchase where
  amount : Nat
  gold : Bool        -- the member's tier on that day
  staleCache : Bool  -- the tier came from a cache that loaded once (a cause)
  points : Nat       -- the points that the system gave
  deriving DecidableEq

/-- The points that the amount and the tier give. -/
def rightPoints (c : Purchase) : Nat := if c.gold then 2 * c.amount else c.amount

/-- The reported case: a Gold member bought for 100 and got 100 points. -/
def reported : Purchase := ⟨100, true, true, 100⟩

/-- The same wrong points, but the cache was fresh. -/
def freshButWrong : Purchase := ⟨100, true, false, 100⟩

/-- The same purchase with 200 points. -/
def rightCase : Purchase := ⟨100, true, false, 200⟩

/-- What the human said about these three cases. Nobody asked about any other case. -/
def said : Judgments Purchase := fun c =>
  if c = reported then some false
  else if c = freshButWrong then some false
  else if c = rightCase then some true
  else none

/-- Fit: "The amount of a purchase and the member's tier on that day decide its points."
No premise, one claim. (The prompt gives this sentence a premise: the points table did not
change in that time. The cases here have one table, so this small version has none.) -/
def fitHyp : Hyp Purchase where
  Premise := Empty
  Claim := Unit
  premise := fun p => nomatch p
  claim := fun _ c => c.points = rightPoints c

/-- Too strong: "The tier is read from a cache that loads once." The cause is a premise:
the hypothesis speaks only about purchases with a stale cache. -/
def causeHyp : Hyp Purchase where
  Premise := Unit
  Claim := Unit
  premise := fun _ c => c.staleCache = true
  claim := fun _ c => c.points = rightPoints c

/-- Collapsed: "Points depend on something other than the purchase." No single case
contradicts it. -/
def vagueHyp : Hyp Purchase where
  Premise := Empty
  Claim := Unit
  premise := fun p => nomatch p
  claim := fun _ _ => True

theorem said_wanted (c : Purchase) (h : Wanted said c) : c = rightCase := by
  unfold Wanted said at h
  split at h
  · cases h
  · split at h
    · cases h
    · split at h
      · assumption
      · cases h

theorem said_unwanted (c : Purchase) (h : Unwanted said c) :
    c = reported ∨ c = freshButWrong := by
  unfold Unwanted said at h
  split at h
  · exact Or.inl (by assumption)
  · split at h
    · exact Or.inr (by assumption)
    · split at h
      · cases h
      · cases h

/-- The fit hypothesis rejects the reported case. This is the red check. -/
theorem fit_rejects_reported : ¬ fitHyp.req reported :=
  fun h => absurd (h (fun p => nomatch p) ())
    (show ¬ (reported.points = rightPoints reported) by decide)

/-- The fit hypothesis rejects the fresh-cache case too. -/
theorem fit_rejects_freshButWrong : ¬ fitHyp.req freshButWrong :=
  fun h => absurd (h (fun p => nomatch p) ())
    (show ¬ (freshButWrong.points = rightPoints freshButWrong) by decide)

/-- The fit hypothesis accepts the right case. -/
theorem fit_accepts_rightCase : fitHyp.req rightCase :=
  fun _ _ => show rightCase.points = rightPoints rightCase by decide

/-- **Fit.** For what the human has said, the fit hypothesis is properly written. -/
theorem fit_properly_written : ProperlyWritten said fitHyp where
  fits := by
    intro c hf
    cases hf with
    | inl hw =>
      have hc := said_wanted c hw.1
      subst hc
      exact hw.2 fit_accepts_rightCase
    | inr hu =>
      cases said_unwanted c hu.1 with
      | inl hc => subst hc; exact fit_rejects_reported hu.2
      | inr hc => subst hc; exact fit_rejects_freshButWrong hu.2
  can_hold := ⟨rightCase,
    And.intro (fun p => nomatch p) (fit_accepts_rightCase (fun p => nomatch p))⟩
  can_fail := fun hc => fit_rejects_reported (hc reported)
  premises_held := fun p => nomatch p
  claims_held := fun _ => Or.inr (fun _ _ q hq => absurd rfl hq)

/-- The one claim of the fit hypothesis is the core of the attempt, and the human
supports it too: the human rejected the reported case, and only this claim forbids it. -/
theorem fit_claim_supported : ClaimSupported said fitHyp () :=
  ⟨reported, show said reported = some false by decide, fit_rejects_reported,
    fun _ q hq => absurd rfl hq⟩

/-- **Too strong.** The cause hypothesis accepts a case that the human rejects: wrong
points with a fresh cache. The cause added meaning that the human did not give. -/
theorem cause_has_intent_falsifier : IntentFalsifier said causeHyp.req freshButWrong :=
  Or.inr ⟨show said freshButWrong = some false by decide,
    fun hp => absurd (hp ()) (show ¬ (freshButWrong.staleCache = true) by decide)⟩

theorem cause_not_properly_written : ¬ ProperlyWritten said causeHyp :=
  fun hp => hp.fits freshButWrong cause_has_intent_falsifier

/-- **Collapsed.** The vague hypothesis accepts every case. -/
theorem vague_collapsed : Collapsed vagueHyp.req :=
  fun _ _ _ => True.intro

theorem vague_not_properly_written : ¬ ProperlyWritten said vagueHyp :=
  fun hp => hp.can_fail vague_collapsed

/-! ## 10. A feature: "add a dark mode"

The author's attempt at this hypothesis (2026-11-11), wide on purpose:

> "The app must contain and use a compatible dark-colored scheme that supports dark mode
> without violating accessibility, readability, or useability across the entire
> application and its microservices."

The author's reason: "That way in case the human just meant 'only on this page' or 'only
this service', then it becomes clear where the assumed failure was."

This section is a small version of that sentence, and it is this file's reading of it.

* A `Screen` is one screen of the app in one state.
* "Accessibility, readability, or useability" is one flag here: `readable`.
* "The entire application and its microservices" is every `Page`. There are two.
* The small version says nothing about a screen while dark mode is off. The sentence may
  say something: the word "mode" can carry it. The case `alwaysDark` (below) is how to
  find out. -/

inductive Page where
  | settings
  | reports
  deriving DecidableEq

structure Screen where
  page : Page
  darkOn : Bool     -- dark mode is switched on
  dark : Bool       -- the screen shows the dark scheme
  readable : Bool   -- the text still meets the standard
  deriving DecidableEq

/-- Today's behavior, and the gap that the request names: dark mode is on, and the screen
stays light. -/
def staysLight : Screen := ⟨Page.settings, true, false, true⟩

/-- Dark, but the text is hard to read. -/
def unreadable : Screen := ⟨Page.settings, true, true, false⟩

/-- Dark and readable. -/
def goodDark : Screen := ⟨Page.settings, true, true, true⟩

/-- Another page stays light while dark mode is on. ("Only on this page.") -/
def reportsLight : Screen := ⟨Page.reports, true, false, true⟩

/-- The screen is dark while dark mode is off. (The app is dark for everyone.) -/
def alwaysDark : Screen := ⟨Page.settings, false, true, true⟩

/-- At first: the request, and one standing judgment. The human rejects today's behavior
(the request says so). The human rejects a screen that is hard to read (an outcome of
earlier work that the human still wants). The human accepts a dark, readable screen. -/
def saidFirst : Judgments Screen := fun c =>
  if c = staysLight then some false
  else if c = unreadable then some false
  else if c = goodDark then some true
  else none

/-- Later, two answers come. "Only on this page": the other page may stay light. And the
human rejects a screen that is dark while dark mode is off. -/
def saidLater : Judgments Screen := fun c =>
  if c = reportsLight then some true
  else if c = alwaysDark then some false
  else saidFirst c

/-- The wide attempt has two claims. -/
inductive WideClaim where
  | usesDark        -- when dark mode is on, the screen is dark
  | staysReadable   -- the screen is readable
  deriving DecidableEq

/-- The wide attempt: no premise, so it speaks about every page. -/
def wideHyp : Hyp Screen where
  Premise := Empty
  Claim := WideClaim
  premise := fun p => nomatch p
  claim := fun (q : WideClaim) => match q with
    | WideClaim.usesDark => fun c => c.darkOn = true → c.dark = true
    | WideClaim.staysReadable => fun c => c.readable = true

/-- The claims of the narrowed attempt: one more than the wide attempt. -/
inductive DarkClaim where
  | usesDark        -- when dark mode is on, the screen is dark
  | staysReadable   -- the screen is readable
  | keepsLight      -- when dark mode is off, the screen is light
  deriving DecidableEq

/-- The narrowed attempt, after the two answers: one premise (the page is the settings
page), and three claims. -/
def narrowHyp : Hyp Screen where
  Premise := Unit
  Claim := DarkClaim
  premise := fun _ c => c.page = Page.settings
  claim := fun (q : DarkClaim) => match q with
    | DarkClaim.usesDark => fun c => c.darkOn = true → c.dark = true
    | DarkClaim.staysReadable => fun c => c.readable = true
    | DarkClaim.keepsLight => fun c => c.darkOn = false → c.dark = false

/-! ### Small facts for the example. Each is a computation on one case. Skip them. -/

theorem saidFirst_wanted (c : Screen) (h : Wanted saidFirst c) : c = goodDark := by
  unfold Wanted saidFirst at h
  split at h
  · cases h
  · split at h
    · cases h
    · split at h
      · assumption
      · cases h

theorem saidFirst_unwanted (c : Screen) (h : Unwanted saidFirst c) :
    c = staysLight ∨ c = unreadable := by
  unfold Unwanted saidFirst at h
  split at h
  · exact Or.inl (by assumption)
  · split at h
    · exact Or.inr (by assumption)
    · split at h
      · cases h
      · cases h

theorem saidLater_wanted (c : Screen) (h : Wanted saidLater c) :
    c = reportsLight ∨ c = goodDark := by
  unfold Wanted saidLater at h
  split at h
  · exact Or.inl (by assumption)
  · split at h
    · cases h
    · exact Or.inr (saidFirst_wanted c h)

theorem saidLater_unwanted (c : Screen) (h : Unwanted saidLater c) :
    c = alwaysDark ∨ c = staysLight ∨ c = unreadable := by
  unfold Unwanted saidLater at h
  split at h
  · cases h
  · split at h
    · exact Or.inl (by assumption)
    · exact Or.inr (saidFirst_unwanted c h)

theorem wide_accepts_goodDark : wideHyp.req goodDark := by
  intro _ (q : WideClaim)
  cases q
  · show goodDark.darkOn = true → goodDark.dark = true
    decide
  · show goodDark.readable = true
    decide

theorem wide_accepts_alwaysDark : wideHyp.req alwaysDark := by
  intro _ (q : WideClaim)
  cases q
  · show alwaysDark.darkOn = true → alwaysDark.dark = true
    decide
  · show alwaysDark.readable = true
    decide

theorem wide_rejects_staysLight : ¬ wideHyp.req staysLight := by
  intro h
  have h1 : staysLight.darkOn = true → staysLight.dark = true :=
    h (fun p => nomatch p) WideClaim.usesDark
  exact absurd (h1 rfl) (by decide)

theorem wide_rejects_unreadable : ¬ wideHyp.req unreadable := by
  intro h
  have h1 : unreadable.readable = true := h (fun p => nomatch p) WideClaim.staysReadable
  exact absurd h1 (by decide)

theorem wide_rejects_reportsLight : ¬ wideHyp.req reportsLight := by
  intro h
  have h1 : reportsLight.darkOn = true → reportsLight.dark = true :=
    h (fun p => nomatch p) WideClaim.usesDark
  exact absurd (h1 rfl) (by decide)

/-- On the settings page, the premise of the narrowed attempt holds. -/
theorem onSettings (c : Screen) (hc : c.page = Page.settings) :
    ∀ p, narrowHyp.premise p c :=
  fun _ => hc

theorem narrow_accepts_goodDark : narrowHyp.req goodDark := by
  intro _ (q : DarkClaim)
  cases q
  · show goodDark.darkOn = true → goodDark.dark = true
    decide
  · show goodDark.readable = true
    decide
  · show goodDark.darkOn = false → goodDark.dark = false
    decide

theorem narrow_accepts_reportsLight : narrowHyp.req reportsLight := by
  intro hp
  have h1 : reportsLight.page = Page.settings := hp ()
  exact absurd h1 (by decide)

theorem narrow_rejects_staysLight : ¬ narrowHyp.req staysLight := by
  intro h
  have h1 : staysLight.darkOn = true → staysLight.dark = true :=
    h (onSettings staysLight rfl) DarkClaim.usesDark
  exact absurd (h1 rfl) (by decide)

theorem narrow_rejects_unreadable : ¬ narrowHyp.req unreadable := by
  intro h
  have h1 : unreadable.readable = true :=
    h (onSettings unreadable rfl) DarkClaim.staysReadable
  exact absurd h1 (by decide)

theorem narrow_rejects_alwaysDark : ¬ narrowHyp.req alwaysDark := by
  intro h
  have h1 : alwaysDark.darkOn = false → alwaysDark.dark = false :=
    h (onSettings alwaysDark rfl) DarkClaim.keepsLight
  exact absurd (h1 rfl) (by decide)

theorem narrow_without_premise_accepts_goodDark : narrowHyp.withoutPremise () goodDark := by
  intro _ (q : DarkClaim)
  cases q
  · show goodDark.darkOn = true → goodDark.dark = true
    decide
  · show goodDark.readable = true
    decide
  · show goodDark.darkOn = false → goodDark.dark = false
    decide

theorem narrow_without_premise_rejects_reportsLight :
    ¬ narrowHyp.withoutPremise () reportsLight := by
  intro h
  have h1 : reportsLight.darkOn = true → reportsLight.dark = true :=
    h (fun p hp => absurd rfl hp) DarkClaim.usesDark
  exact absurd (h1 rfl) (by decide)

theorem narrow_without_keepsLight_rejects_staysLight :
    ¬ narrowHyp.withoutClaim DarkClaim.keepsLight staysLight := by
  intro h
  have h1 : staysLight.darkOn = true → staysLight.dark = true :=
    h (onSettings staysLight rfl) DarkClaim.usesDark
      (show (DarkClaim.usesDark : DarkClaim) ≠ DarkClaim.keepsLight by decide)
  exact absurd (h1 rfl) (by decide)

theorem narrow_without_keepsLight_rejects_unreadable :
    ¬ narrowHyp.withoutClaim DarkClaim.keepsLight unreadable := by
  intro h
  have h1 : unreadable.readable = true :=
    h (onSettings unreadable rfl) DarkClaim.staysReadable
      (show (DarkClaim.staysReadable : DarkClaim) ≠ DarkClaim.keepsLight by decide)
  exact absurd h1 (by decide)

/-! ### What the example shows -/

/-- The later judgments keep the first ones: the two answers added to what was known. -/
theorem later_extends_first : Extends saidFirst saidLater := by
  intro c v h
  unfold saidLater
  split
  · rename_i hc
    subst hc
    have hn : saidFirst reportsLight = none := by decide
    rw [hn] at h
    cases h
  · split
    · rename_i hc
      subst hc
      have hn : saidFirst alwaysDark = none := by decide
      rw [hn] at h
      cases h
    · exact h

/-- **At first, the wide attempt is properly written.** It fits what the human has said.
The gap that the request names shows that it can fail. Each of its two claims is held in
place by a case that the human rejects. It has no premise, so it assumes nothing about
the scope. -/
theorem wide_properly_written_at_first : ProperlyWritten saidFirst wideHyp where
  fits := by
    intro c hf
    cases hf with
    | inl hw =>
      have hc := saidFirst_wanted c hw.1
      subst hc
      exact hw.2 wide_accepts_goodDark
    | inr hu =>
      cases saidFirst_unwanted c hu.1 with
      | inl hc => subst hc; exact wide_rejects_staysLight hu.2
      | inr hc => subst hc; exact wide_rejects_unreadable hu.2
  can_hold := ⟨goodDark,
    And.intro (fun p => nomatch p) (wide_accepts_goodDark (fun p => nomatch p))⟩
  can_fail := fun hc => wide_rejects_staysLight (hc staysLight)
  premises_held := fun p => nomatch p
  claims_held := by
    intro (q : WideClaim)
    cases q
    · refine Or.inl ⟨staysLight, Or.inr ⟨show saidFirst staysLight = some false by decide, ?_⟩⟩
      intro _ (q : WideClaim)
      cases q
      · intro hq
        exact absurd rfl hq
      · intro _
        show staysLight.readable = true
        decide
    · refine Or.inl ⟨unreadable, Or.inr ⟨show saidFirst unreadable = some false by decide, ?_⟩⟩
      intro _ (q : WideClaim)
      cases q
      · intro _
        show unreadable.darkOn = true → unreadable.dark = true
        decide
      · intro hq
        exact absurd rfl hq

/-- **At first, the wide scope is a guess.** Nobody has judged a page that stays light
while dark mode is on. The wide attempt rejects that case: its default is "every page".
The attempt is properly written, and it still guesses. -/
theorem wide_guesses_the_scope :
    Unjudged saidFirst reportsLight ∧ ¬ wideHyp.req reportsLight :=
  ⟨show saidFirst reportsLight = none by decide, wide_rejects_reportsLight⟩

/-- **A narrower scope is a guess too.** The narrowed attempt accepts the same case, and
nobody has judged it. -/
theorem narrow_guesses_the_scope :
    Unjudged saidFirst reportsLight ∧ narrowHyp.req reportsLight :=
  ⟨show saidFirst reportsLight = none by decide, narrow_accepts_reportsLight⟩

/-- **At first, nothing holds a narrower scope.** No judgment holds the premise "only the
settings page" in place: the statement fits, and it can fail, without that premise. Of
the two guesses about the scope, the narrow one adds a premise that nobody gave. So the
wide attempt is the one to write. -/
theorem scope_not_held_at_first : ¬ PremiseHeld saidFirst narrowHyp () := by
  intro ho
  cases ho with
  | inl hf =>
    cases hf with
    | intro c hc =>
      cases hc with
      | inl hw =>
        have e := saidFirst_wanted c hw.1
        subst e
        exact hw.2 narrow_without_premise_accepts_goodDark
      | inr hu =>
        cases saidFirst_unwanted c hu.1 with
        | inl e =>
          subst e
          exact narrow_rejects_staysLight
            (fewer_premises_demand_more narrowHyp () staysLight hu.2)
        | inr e =>
          subst e
          exact narrow_rejects_unreadable
            (fewer_premises_demand_more narrowHyp () unreadable hu.2)
  | inr hcol =>
    exact narrow_rejects_staysLight
      (fewer_premises_demand_more narrowHyp () staysLight (hcol staysLight))

/-- **At first, nothing holds "light mode stays" either.** It is a sensible default. But
no judgment holds it in place until someone asks about the case `alwaysDark`. -/
theorem keepsLight_not_held_at_first :
    ¬ ClaimHeld saidFirst narrowHyp DarkClaim.keepsLight := by
  intro ho
  cases ho with
  | inl hf =>
    cases hf with
    | intro c hc =>
      cases hc with
      | inl hw =>
        have e := saidFirst_wanted c hw.1
        subst e
        exact hw.2
          (fewer_claims_demand_less narrowHyp DarkClaim.keepsLight goodDark
            narrow_accepts_goodDark)
      | inr hu =>
        cases saidFirst_unwanted c hu.1 with
        | inl e => subst e; exact narrow_without_keepsLight_rejects_staysLight hu.2
        | inr e => subst e; exact narrow_without_keepsLight_rejects_unreadable hu.2
  | inr hcol => exact narrow_without_keepsLight_rejects_staysLight (hcol staysLight)

/-- **"Only on this page."** That one answer refutes the wide attempt: the human accepts
a case that it rejects. The failure is in the scope, and the case shows where. -/
theorem wide_scope_falsified : IntentFalsifier saidLater wideHyp.req reportsLight :=
  Or.inl ⟨show saidLater reportsLight = some true by decide, wide_rejects_reportsLight⟩

/-- **A missing claim.** The wide attempt accepts a screen that is dark while dark mode
is off, and the human rejects that screen. -/
theorem wide_alwaysDark_falsified : IntentFalsifier saidLater wideHyp.req alwaysDark :=
  Or.inr ⟨show saidLater alwaysDark = some false by decide, wide_accepts_alwaysDark⟩

theorem wide_not_properly_written_later : ¬ ProperlyWritten saidLater wideHyp :=
  fun hp => hp.fits reportsLight wide_scope_falsified

/-- **After the two answers, the narrowed attempt is properly written.** The answer
"only on this page" holds its premise in place. The rejected case `alwaysDark` holds the
claim `keepsLight` in place. The two words that nothing held at first are held now. -/
theorem narrow_properly_written : ProperlyWritten saidLater narrowHyp where
  fits := by
    intro c hf
    cases hf with
    | inl hw =>
      cases saidLater_wanted c hw.1 with
      | inl hc => subst hc; exact hw.2 narrow_accepts_reportsLight
      | inr hc => subst hc; exact hw.2 narrow_accepts_goodDark
    | inr hu =>
      cases saidLater_unwanted c hu.1 with
      | inl hc => subst hc; exact narrow_rejects_alwaysDark hu.2
      | inr hc =>
        cases hc with
        | inl hc => subst hc; exact narrow_rejects_staysLight hu.2
        | inr hc => subst hc; exact narrow_rejects_unreadable hu.2
  can_hold := ⟨goodDark,
    And.intro (onSettings goodDark rfl) (narrow_accepts_goodDark (onSettings goodDark rfl))⟩
  can_fail := fun hc => narrow_rejects_staysLight (hc staysLight)
  premises_held := fun _ =>
    Or.inl ⟨reportsLight, Or.inl ⟨show saidLater reportsLight = some true by decide,
      narrow_without_premise_rejects_reportsLight⟩⟩
  claims_held := by
    intro (q : DarkClaim)
    cases q
    · refine Or.inl ⟨staysLight, Or.inr ⟨show saidLater staysLight = some false by decide, ?_⟩⟩
      intro _ (q : DarkClaim)
      cases q
      · intro hq
        exact absurd rfl hq
      · intro _
        show staysLight.readable = true
        decide
      · intro _
        show staysLight.darkOn = false → staysLight.dark = false
        decide
    · refine Or.inl ⟨unreadable, Or.inr ⟨show saidLater unreadable = some false by decide, ?_⟩⟩
      intro _ (q : DarkClaim)
      cases q
      · intro _
        show unreadable.darkOn = true → unreadable.dark = true
        decide
      · intro hq
        exact absurd rfl hq
      · intro _
        show unreadable.darkOn = false → unreadable.dark = false
        decide
    · refine Or.inl ⟨alwaysDark, Or.inr ⟨show saidLater alwaysDark = some false by decide, ?_⟩⟩
      intro _ (q : DarkClaim)
      cases q
      · intro _
        show alwaysDark.darkOn = true → alwaysDark.dark = true
        decide
      · intro _
        show alwaysDark.readable = true
        decide
      · intro hq
        exact absurd rfl hq

/-! ## 11. What the definition does not decide

Astra's review of the first version of this file found two things (2026-11-11).

* That version had no point 2. A statement that rejects every case passed it when the
  human had judged nothing. Point 2 (`can_hold`) is the answer.
* Two attempts can both be properly written, and still disagree on a case that nobody
  judged. This section shows it. So "properly written" does not mean "the only right
  statement". The definition tests each word of an attempt against the judgments. It
  does not choose between two attempts on a case that nobody judged. When two attempts
  disagree on a case, `one_case_decides` says what to do: show that case to the human.

One more limit follows. The definition tests the words as the writer cut them. It does
not test the cut: one claim that packs two demands is one word, and it passes. -/

inductive Three where
  | liked
  | disliked
  | notAsked
  deriving DecidableEq

/-- The human liked one case and disliked one. Nobody asked about the third. -/
def saidTwo : Judgments Three := fun c =>
  match c with
  | Three.liked => some true
  | Three.disliked => some false
  | Three.notAsked => none

/-- One claim: "the case is the one that the human liked." -/
def strictHyp : Hyp Three where
  Premise := Empty
  Claim := Unit
  premise := fun p => nomatch p
  claim := fun _ c => c = Three.liked

/-- One claim: "the case is not the one that the human disliked." -/
def looseHyp : Hyp Three where
  Premise := Empty
  Claim := Unit
  premise := fun p => nomatch p
  claim := fun _ c => c ≠ Three.disliked

theorem strict_properly_written : ProperlyWritten saidTwo strictHyp where
  fits := by
    intro c hf
    cases c with
    | liked =>
      cases hf with
      | inl hw => exact hw.2 (fun _ _ => rfl)
      | inr hu => exact absurd hu.1 (show ¬ saidTwo Three.liked = some false by decide)
    | disliked =>
      cases hf with
      | inl hw => exact absurd hw.1 (show ¬ saidTwo Three.disliked = some true by decide)
      | inr hu =>
        have h1 : Three.disliked = Three.liked := hu.2 (fun p => nomatch p) ()
        exact absurd h1 (by decide)
    | notAsked =>
      cases hf with
      | inl hw => exact absurd hw.1 (show ¬ saidTwo Three.notAsked = some true by decide)
      | inr hu => exact absurd hu.1 (show ¬ saidTwo Three.notAsked = some false by decide)
  can_hold := ⟨Three.liked, And.intro (fun p => nomatch p) (fun _ => rfl)⟩
  can_fail := by
    intro hc
    have h1 : Three.disliked = Three.liked := hc Three.disliked (fun p => nomatch p) ()
    exact absurd h1 (by decide)
  premises_held := fun p => nomatch p
  claims_held := fun _ => Or.inr (fun _ _ q hq => absurd rfl hq)

theorem loose_properly_written : ProperlyWritten saidTwo looseHyp where
  fits := by
    intro c hf
    cases c with
    | liked =>
      cases hf with
      | inl hw =>
        exact hw.2 (fun _ _ => show Three.liked ≠ Three.disliked by decide)
      | inr hu => exact absurd hu.1 (show ¬ saidTwo Three.liked = some false by decide)
    | disliked =>
      cases hf with
      | inl hw => exact absurd hw.1 (show ¬ saidTwo Three.disliked = some true by decide)
      | inr hu =>
        have h1 : Three.disliked ≠ Three.disliked := hu.2 (fun p => nomatch p) ()
        exact h1 rfl
    | notAsked =>
      cases hf with
      | inl hw => exact absurd hw.1 (show ¬ saidTwo Three.notAsked = some true by decide)
      | inr hu => exact absurd hu.1 (show ¬ saidTwo Three.notAsked = some false by decide)
  can_hold := ⟨Three.liked,
    And.intro (fun p => nomatch p) (fun _ => show Three.liked ≠ Three.disliked by decide)⟩
  can_fail := by
    intro hc
    have h1 : Three.disliked ≠ Three.disliked := hc Three.disliked (fun p => nomatch p) ()
    exact h1 rfl
  premises_held := fun p => nomatch p
  claims_held := fun _ => Or.inr (fun _ _ q hq => absurd rfl hq)

/-- Both attempts are properly written, and they disagree on the case that nobody
judged. That case is the next question for the human. -/
theorem proper_attempts_can_disagree :
    looseHyp.req Three.notAsked ∧ ¬ strictHyp.req Three.notAsked :=
  ⟨fun _ _ => show Three.notAsked ≠ Three.disliked by decide,
   fun h =>
    absurd (show Three.notAsked = Three.liked from h (fun p => nomatch p) ()) (by decide)⟩

/-- The statement that accepts the most cases and still fits: reject exactly the cases
that the human rejected. -/
def OnlyTheRejected {Case : Type} (j : Judgments Case) : Req Case := fun c => ¬ Unwanted j c

/-- The bare list of rejected cases fits the judgments. -/
theorem onlyTheRejected_fits {Case : Type} (j : Judgments Case) :
    Fits j (OnlyTheRejected j) := by
  intro c hf
  cases hf with
  | inl hw => exact hw.2 (fun hu => not_wanted_and_unwanted j c hw.1 hu)
  | inr hu => exact hu.2 hu.1

/-- Every statement that fits accepts no more than that list does. So the list is the
logically weakest statement that fits. It says nothing about a case that nobody judged.
A hypothesis must say more than the list: this is why "the weakest form" in this file is
about the words of a statement, and not about the set of cases that it accepts. -/
theorem fits_accepts_no_more {Case : Type} (j : Judgments Case) (R : Req Case)
    (hf : Fits j R) (c : Case) : R c → OnlyTheRejected j c :=
  fun hr hu => hf c (Or.inr ⟨hu, hr⟩)

/-! ## What this file does not state

1. A case here is one behavior. A claim about an order of steps or about time needs a case
   that is a sequence.
2. How the human's agreement with a sentence stands for cases that nobody showed yet. In
   the method, an accepted hypothesis is the law of its ticket: a failing check is judged
   against it, and nobody asks the human again until a case gives a reason to doubt it.
3. Changes and checks: which change serves which claim, and a change that serves no claim.
4. Who writes `Case`. The agent chooses it, so the human must read it: a requirement over
   the wrong cases can be properly written and still miss the point. Section 10 shows the
   risk: `Screen` has one flag for "accessibility, readability, or useability".
5. The agent's defaults. A default is an answer that the agent gives itself to a question
   that nobody asked the human. This file has only the human's judgments: a case that
   only a default covers is `Unjudged` here. The file also does not say how likely a
   guess is.
6. Which of two properly written attempts is the better one (section 11).
-/

end Sagittarius

/-! Every theorem of this file, and the axioms that it uses. -/
open Sagittarius in
#print axioms not_wanted_and_unwanted
open Sagittarius in
#print axioms fewer_premises_demand_more
open Sagittarius in
#print axioms fewer_claims_demand_less
open Sagittarius in
#print axioms premise_held_by_wanted_case
open Sagittarius in
#print axioms claim_held_two_ways
open Sagittarius in
#print axioms claim_false_at_its_case
open Sagittarius in
#print axioms proper_with_no_judgments
open Sagittarius in
#print axioms fits_ignores_unjudged
open Sagittarius in
#print axioms collapsed_cannot_fail
open Sagittarius in
#print axioms red_shows_it_can_fail
open Sagittarius in
#print axioms unmet_premise_cannot_fail
open Sagittarius in
#print axioms stay_in_build
open Sagittarius in
#print axioms hypothesis_must_change
open Sagittarius in
#print axioms falsifier_stays
open Sagittarius in
#print axioms out_stays
open Sagittarius in
#print axioms fits_before
open Sagittarius in
#print axioms premise_held_stays
open Sagittarius in
#print axioms claim_held_stays
open Sagittarius in
#print axioms proper_until_falsified
open Sagittarius in
#print axioms keepsOutside_nothing
open Sagittarius in
#print axioms falsifier_stays_outside
open Sagittarius in
#print axioms narrower_keeps_more
open Sagittarius in
#print axioms one_case_decides
open Sagittarius in
#print axioms said_wanted
open Sagittarius in
#print axioms said_unwanted
open Sagittarius in
#print axioms fit_rejects_reported
open Sagittarius in
#print axioms fit_rejects_freshButWrong
open Sagittarius in
#print axioms fit_accepts_rightCase
open Sagittarius in
#print axioms fit_properly_written
open Sagittarius in
#print axioms fit_claim_supported
open Sagittarius in
#print axioms cause_has_intent_falsifier
open Sagittarius in
#print axioms cause_not_properly_written
open Sagittarius in
#print axioms vague_collapsed
open Sagittarius in
#print axioms vague_not_properly_written
open Sagittarius in
#print axioms saidFirst_wanted
open Sagittarius in
#print axioms saidFirst_unwanted
open Sagittarius in
#print axioms saidLater_wanted
open Sagittarius in
#print axioms saidLater_unwanted
open Sagittarius in
#print axioms wide_accepts_goodDark
open Sagittarius in
#print axioms wide_accepts_alwaysDark
open Sagittarius in
#print axioms wide_rejects_staysLight
open Sagittarius in
#print axioms wide_rejects_unreadable
open Sagittarius in
#print axioms wide_rejects_reportsLight
open Sagittarius in
#print axioms onSettings
open Sagittarius in
#print axioms narrow_accepts_goodDark
open Sagittarius in
#print axioms narrow_accepts_reportsLight
open Sagittarius in
#print axioms narrow_rejects_staysLight
open Sagittarius in
#print axioms narrow_rejects_unreadable
open Sagittarius in
#print axioms narrow_rejects_alwaysDark
open Sagittarius in
#print axioms narrow_without_premise_accepts_goodDark
open Sagittarius in
#print axioms narrow_without_premise_rejects_reportsLight
open Sagittarius in
#print axioms narrow_without_keepsLight_rejects_staysLight
open Sagittarius in
#print axioms narrow_without_keepsLight_rejects_unreadable
open Sagittarius in
#print axioms later_extends_first
open Sagittarius in
#print axioms wide_properly_written_at_first
open Sagittarius in
#print axioms wide_guesses_the_scope
open Sagittarius in
#print axioms narrow_guesses_the_scope
open Sagittarius in
#print axioms scope_not_held_at_first
open Sagittarius in
#print axioms keepsLight_not_held_at_first
open Sagittarius in
#print axioms wide_scope_falsified
open Sagittarius in
#print axioms wide_alwaysDark_falsified
open Sagittarius in
#print axioms wide_not_properly_written_later
open Sagittarius in
#print axioms narrow_properly_written
open Sagittarius in
#print axioms strict_properly_written
open Sagittarius in
#print axioms loose_properly_written
open Sagittarius in
#print axioms proper_attempts_can_disagree
open Sagittarius in
#print axioms onlyTheRejected_fits
open Sagittarius in
#print axioms fits_accepts_no_more
