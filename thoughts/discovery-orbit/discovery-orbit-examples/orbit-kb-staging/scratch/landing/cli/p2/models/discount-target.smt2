; FLYBY example A, target world: the requirements for two discount codes.
(set-option :produce-models true)
(set-option :produce-unsat-cores true)
(set-logic QF_LIA)

(declare-const list_price Int)
(declare-const floor_price Int)
(declare-const code1 Int)
(declare-const code2 Int)
(declare-const charged Int)

(define-fun clamp ((x Int) (lo Int)) Int (ite (< x lo) lo x))
(define-fun after_codes () Int (- (- list_price code1) code2))

(assert (! (and (< 0 floor_price) (<= floor_price list_price) (<= list_price 100000)) :named dom_prices))
(assert (! (and (<= 0 code1 2000) (<= 0 code2 2000)) :named dom_codes))

; Claims:
;   c1 introduce: the charged price is never below the floor.
;   c2 preserve:  each code takes off its full amount.
; 1. Both claims for order 4417. Expect unsat. The core names the conflict.
(push)
(assert (! (>= charged floor_price) :named c1_floor))
(assert (! (= charged after_codes) :named c2_full_codes))
(assert (! (and (= list_price 4000) (= floor_price 3000) (= code1 500) (= code2 1000)) :named order_4417))
(check-sat)
(get-unsat-core)
(pop)

; The human answered: the floor wins. c2b supersedes c2:
;   c2b: each code takes off its full amount, but the charged price never
;        goes below the floor.
(define-fun c2b () Bool (= charged (clamp after_codes floor_price)))

; 2. c1 holds for every order in the domain. Expect unsat.
(push)
(assert c2b)
(assert (< charged floor_price))
(check-sat)
(pop)

; 3. Preserve: above the floor, each code takes off its full amount. Expect unsat.
(push)
(assert c2b)
(assert (>= after_codes floor_price))
(assert (distinct charged after_codes))
(check-sat)
(pop)

; 4. Non-vacuity: the clamp can apply. Expect sat, and a case to show the human.
(push)
(assert c2b)
(assert (< after_codes floor_price))
(check-sat)
(get-value (list_price floor_price code1 code2 charged))
(pop)

; 5. Mutation check: delete the clamp. The bad case must come back. Expect sat (killed).
(push)
(assert (= charged after_codes))
(assert (< charged floor_price))
(check-sat)
(pop)
