; FLYBY example A, existing world: current checkout pricing.
; SURVEY source (invented for the example): CheckoutService.ApplyCodes clamps
; the price to the floor after the first code, then takes off the second code.
; Prices are in cents. Each code takes off a fixed amount.
(set-option :produce-models true)
(set-logic QF_LIA)

(declare-const list_price Int)
(declare-const floor_price Int)
(declare-const code1 Int)
(declare-const code2 Int)

(define-fun clamp ((x Int) (lo Int)) Int (ite (< x lo) lo x))
; Current rule.
(define-fun price_now () Int (- (clamp (- list_price code1) floor_price) code2))
; Suspected root cause, changed: clamp after both codes.
(define-fun price_fix () Int (clamp (- (- list_price code1) code2) floor_price))

(assert (and (< 0 floor_price) (<= floor_price list_price) (<= list_price 100000)))
(assert (and (<= 0 code1 2000) (<= 0 code2 2000)))

; 1. Sanity: the rules admit an order. Expect sat.
(check-sat)
(get-value (list_price floor_price code1 code2 price_now))

; 2. Calibrate with order 4417: list $40.00, floor $30.00, codes $5.00 and $10.00.
;    The payment log shows $25.00 charged. Expect sat, and price_now = 2500.
(push)
(assert (and (= list_price 4000) (= floor_price 3000) (= code1 500) (= code2 1000)))
(check-sat)
(get-value (price_now))
(pop)

; 3. The reported bad case: a price below the floor. Expect sat.
(push)
(assert (< price_now floor_price))
(check-sat)
(get-value (list_price floor_price code1 code2 price_now))
(pop)

; 4. Root cause: with the clamp after both codes, the bad case is gone. Expect unsat.
(push)
(assert (< price_fix floor_price))
(check-sat)
(pop)

; 5. The change keeps normal cases: one code only. Expect unsat.
(push)
(assert (= code2 0))
(assert (distinct price_now price_fix))
(check-sat)
(pop)

; 6. The change keeps normal cases: both codes stay above the floor. Expect unsat.
(push)
(assert (>= (- (- list_price code1) code2) floor_price))
(assert (distinct price_now price_fix))
(check-sat)
(pop)
