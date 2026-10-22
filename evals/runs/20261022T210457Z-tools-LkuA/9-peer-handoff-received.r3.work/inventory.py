class Inventory:
    def __init__(self, stock):
        self.stock = dict(stock)
        self.reserved = {}

    def reserve(self, sku, qty):
        reserved = self.reserved.get(sku, 0)
        if reserved + qty > self.stock.get(sku, 0):
            raise ValueError(f"cannot reserve {qty} of {sku}: only {self.stock.get(sku, 0) - reserved} on hand")
        self.reserved[sku] = reserved + qty
        return self.reserved[sku]
