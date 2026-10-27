# Milk pickups

`milk.py` prices the milk the co-op collects from member farms. The monthly payout run calls
`pickup_payment` for each row of `pickups.csv` and `monthly_statement` for each farm, and pays the
result.

The co-op pays 0.42 per litre. The `unit` column says what the farm's meter measured: `L` for
litres, `gal` for US gallons (1 US gallon is 3.785 litres). The `taken_at` times are UTC. The
dairy runs on UTC-7 all year (it does not change its clocks), and a pickup belongs to the month in
which it happened at the dairy.
