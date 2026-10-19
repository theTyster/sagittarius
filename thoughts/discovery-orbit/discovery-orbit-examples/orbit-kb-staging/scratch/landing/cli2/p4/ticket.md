# Ticket: two discount codes price an order below the floor

Invented for Example A of the discovery orbit. The GO variants of the fixture approve this file.

## Problem

Two discount codes can price an order below the floor price. Order 4417 was charged $25.00.
Its floor is $30.00. The payment log and test t1 show it.

Root cause: `CheckoutService.ApplyCodes` applies the floor after the first code, before the
second code. The log of order 4417 confirms it.

## Scope

- In: two or more fixed-amount codes at checkout.
- Out: gift cards.

## Risk

The change alters the price of each order whose codes cross the floor. It changes one
function, so it is easy to undo. The models leave out percentage codes.

## Claims

- c1, introduce: no order is charged below its floor price.
  Example: order 4417 (list $40.00, floor $30.00, codes $5.00 and $10.00) is charged $30.00.
  Example: list $40.00, floor $30.00, codes $5.00 and $5.01 is charged $30.00.
- c2b, preserve: each code takes off its full amount, down to the floor price.
  It supersedes c2. Example: list $40.00, floor $20.00, codes $5.00 and $10.00 is charged $25.00.
  Example: list $40.00, floor $30.00, one code $5.00 is charged $35.00.

## Answers and dormant questions

- q1: for order 4417, full codes and the floor cannot both hold. The human chose: the floor wins.

## Models

- models/discount-now.smt2: sane, and calibrated with order 4417 (2500 cents). Z3 and cvc5 agree.
- models/discount-target.smt2: c1 holds, c2b holds, the clamp can apply, and the mutation
  that deletes the clamp is killed. Z3 and cvc5 agree. Prices up to $1000.00, codes up to $20.00.

## Not explored

Percentage codes; codes on single items; refunds of orders with codes.
