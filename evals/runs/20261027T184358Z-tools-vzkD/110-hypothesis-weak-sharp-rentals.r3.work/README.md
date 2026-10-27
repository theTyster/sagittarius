# Tool rentals

`rental.py` prices a rental. The weekly billing run calls `rental_total` for each
row of `rentals.csv` (the coupon column is split on `;`) and bills the result.
