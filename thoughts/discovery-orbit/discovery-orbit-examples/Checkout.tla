------------------------------ MODULE Checkout ------------------------------
(* TRAJECTORY example B. Existing world: the checkout client retries a payment
   after a timeout. SURVEY sources (invented for the example):
   CheckoutService.PayAsync, PaymentGateway.Charge, RetryPolicy (one retry). *)
EXTENDS Naturals

CONSTANTS
    MaxRetries,  \* retries that RetryPolicy allows
    Dedupe       \* TRUE in the target: the gateway ignores a repeat charge for the order

VARIABLES
    attempts,    \* requests that the client has sent
    inflight,    \* requests that the gateway has not processed yet
    charges,     \* charges that the gateway has made for the order
    client       \* "waiting", "paid", or "failed"

vars == <<attempts, inflight, charges, client>>

Init ==
    /\ attempts = 1
    /\ inflight = 1
    /\ charges = 0
    /\ client = "waiting"

\* PaymentGateway.Charge processes one request.
GatewayCharge ==
    /\ inflight > 0
    /\ inflight' = inflight - 1
    /\ charges' = IF Dedupe /\ charges > 0 THEN charges ELSE charges + 1
    /\ UNCHANGED <<attempts, client>>

\* The gateway response reaches the client.
ClientGetsResponse ==
    /\ client = "waiting"
    /\ charges > 0
    /\ client' = "paid"
    /\ UNCHANGED <<attempts, inflight, charges>>

\* RetryPolicy: the client times out and sends the request again.
ClientRetries ==
    /\ client = "waiting"
    /\ attempts <= MaxRetries
    /\ attempts' = attempts + 1
    /\ inflight' = inflight + 1
    /\ UNCHANGED <<charges, client>>

\* The client gives up after its last retry times out.
ClientGivesUp ==
    /\ client = "waiting"
    /\ attempts > MaxRetries
    /\ client' = "failed"
    /\ UNCHANGED <<attempts, inflight, charges>>

Next == GatewayCharge \/ ClientGetsResponse \/ ClientRetries \/ ClientGivesUp

Spec == Init /\ [][Next]_vars

\* c1 (introduce): an order is charged at most once.
NoDoubleCharge == charges <= 1

\* Not asked for by the report: a customer who sees "failed" was not charged.
NoChargeOnFailure == client = "failed" => charges = 0

\* Sanity witnesses: TLC must find a trace that reaches each of these states.
NeverPaid == client # "paid"
NeverFailed == client # "failed"
=============================================================================
