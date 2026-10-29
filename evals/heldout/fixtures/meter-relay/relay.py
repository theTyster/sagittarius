"""Field units send meter readings to the base station over a radio link.

The radio can lose a reading, lose the station's ack, or hold a reading back and
deliver it late. A unit numbers its readings 1, 2, 3, ... and sends one at a time.
It waits for the ack; on a timeout it sends the same reading again, up to
MAX_TRIES sends in all. Then it gives up on that reading and goes on to the next.
"""

MAX_TRIES = 3


class Station:
    def __init__(self):
        self.stored = []  # (seq, value), in the order the station stored them
        self._seen = set()

    def receive(self, seq, value):
        """Store a reading the first time it arrives. Return the ack: the reading's seq."""
        if seq not in self._seen:
            self._seen.add(seq)
            self.stored.append((seq, value))
        return seq


class Link:
    """A scripted radio link for tests and trials.

    plan holds one event for each send, in order:
      "ok"        the reading arrives and the ack comes back
      "lose"      the reading is lost
      "lose_ack"  the reading arrives, the ack is lost
      N (an int)  the reading is held back and arrives after N more sends; its ack is lost
    When the plan runs out, every send is "ok".
    """

    def __init__(self, station, plan=()):
        self.station = station
        self.plan = list(plan)
        self.held = []

    def send(self, seq, value):
        """Return the ack, or None when the unit times out."""
        event = self.plan.pop(0) if self.plan else "ok"
        ack = None
        if event in ("ok", "lose_ack"):
            ack = self.station.receive(seq, value)
            if event == "lose_ack":
                ack = None
        later = []
        for n, s, v in self.held:
            if n <= 1:
                self.station.receive(s, v)
            else:
                later.append((n - 1, s, v))
        self.held = later
        if isinstance(event, int):
            self.held.append((event, seq, value))
        return ack


class Unit:
    def __init__(self, link, max_tries=MAX_TRIES):
        self.link = link
        self.max_tries = max_tries
        self.next_seq = 1

    def take(self, value):
        """Send one reading. Return True when the station acked it."""
        seq = self.next_seq
        self.next_seq += 1
        for _ in range(self.max_tries):
            if self.link.send(seq, value) == seq:
                return True
        return False
