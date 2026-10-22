class Inventory:
    def __init__(self, stock):
        self.stock = dict(stock)
        self.reserved = {}

    def reserve(self, sku, qty):
        self.reserved[sku] = self.reserved.get(sku, 0) + qty
        return self.reserved[sku]
