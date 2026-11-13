# Seat holds

The box office of a small theatre keeps a seat on hold while a buyer fills in the checkout form.

- `hold(seat, buyer, minute)` puts a seat on hold for a buyer. It returns False when another
  buyer holds the seat.
- `touch(seat, buyer, minute)` is called whenever the buyer does something on the checkout page.
- `is_held(seat, minute)` says whether the seat is still on hold.

The rule: a hold lasts 15 minutes after the buyer's last action. A seat whose hold has run out
can be held by anyone. Times are whole minutes since the box office opened.

Tests: `python3 -m unittest`
