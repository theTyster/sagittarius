"""Seat holds for the box office. Times are whole minutes since opening."""
HOLD_MINUTES = 15


class Holds:
    def __init__(self):
        self._held = {}  # seat -> (buyer, minute of the hold)

    def is_held(self, seat, minute):
        entry = self._held.get(seat)
        return entry is not None and minute - entry[1] < HOLD_MINUTES

    def hold(self, seat, buyer, minute):
        entry = self._held.get(seat)
        if entry and entry[0] != buyer and self.is_held(seat, minute):
            return False
        self._held[seat] = (buyer, minute)
        return True

    def touch(self, seat, buyer, minute):
        """The buyer did something on the checkout page."""
        entry = self._held.get(seat)
        if entry and entry[0] == buyer:
            self._held[seat] = (buyer, entry[1])
