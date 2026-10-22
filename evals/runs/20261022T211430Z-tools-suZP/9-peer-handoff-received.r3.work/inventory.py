class Inventory:
    def __init__(self, stock):
        self.stock = dict(stock)
        self.reserved = {}

    def reserve(self, sku, qty):
        available = self.stock.get(sku, 0) - self.reserved.get(sku, 0)
        if qty > available:
            raise ValueError(f"cannot reserve {qty} of {sku}: only {available} available")
        self.reserved[sku] = self.reserved.get(sku, 0) + qty
        return self.reserved[sku]
