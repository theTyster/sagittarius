class Inventory:
    def __init__(self, stock):
        self.stock = dict(stock)
        self.reserved = {}

    def reserve(self, sku, qty):
        on_hand = self.stock.get(sku, 0) - self.reserved.get(sku, 0)
        if qty > on_hand:
            raise ValueError(f"cannot reserve {qty} of {sku}: only {on_hand} on hand")
        self.reserved[sku] = self.reserved.get(sku, 0) + qty
        return self.reserved[sku]
