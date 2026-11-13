# Fleet fuel log

Drivers write one row in `log.csv` for each fill-up: the date, the vehicle, the odometer reading
in km, and the litres filled. `python3 fuel.py log.csv` prints the fuel use of each vehicle in
km per litre.

The method: fill the tank every time. The litres of a fill-up are what the vehicle used since
its last fill-up, so a vehicle's figure is the km driven since its first fill-up divided by the
litres of all later fill-ups. A vehicle with one row has no figure.

Vehicle V-2 is an old van with a five-digit odometer: it counts to 99999 and starts again at 0.
The other vehicles have six digits.

Tests: `python3 -m unittest`
