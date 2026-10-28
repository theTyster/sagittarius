# Cookie renewal

Move the renewal credential out of the request body and into an HttpOnly cookie, so page
scripts cannot read it.

- Server: `renew` reads the cookie when the body has no token (shipped).
- Web client: posts `{}` to `/renew` (shipped).
- Safety: the change is transport-only. Proved in `proofs/Renewal.lean`: R-1, R-2, R-3, all
  with no `sorry`.
- End-to-end: a 25-minute session on staging renewed at natural expiry.
