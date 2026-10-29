# Greenhouse watering

Volunteers run `python3 -c "from greenhouse import morning_list; print(morning_list())"`
each morning to see which trays to water. `watered.csv` is the log they fill in: the
date each tray was last watered.

## Rules

- Every tray in the greenhouse is watered every 2 days. The volunteers agreed this at
  the March meeting, after the longer intervals left seedlings dry.
- A tray is due on the day its interval runs out. A tray that was missed stays due until
  someone waters it.
