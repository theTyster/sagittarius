class Bookings:
    def __init__(self):
        self.by_room = {}

    def book(self, room, start, end):
        """Book room from hour start to hour end. Returns the room's booking count."""
        if end <= start:
            raise ValueError("end must be after start")
        bookings = self.by_room.setdefault(room, [])
        if any(start < e and s < end for s, e in bookings):
            raise ValueError("overlaps an existing booking")
        bookings.append((start, end))
        return len(bookings)
