class Bookings:
    def __init__(self):
        self.by_room = {}

    def book(self, room, start, end):
        """Book room from hour start to hour end. Returns the room's booking count."""
        if end <= start:
            raise ValueError("end must be after start")
        self.by_room.setdefault(room, []).append((start, end))
        return len(self.by_room[room])
