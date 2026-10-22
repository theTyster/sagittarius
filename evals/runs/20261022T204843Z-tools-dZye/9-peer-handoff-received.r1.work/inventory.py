class Inventory:
    def __init__(self, stock):
        self.stock = dict(stock)
        self.reserved = {}

    def reserve(self, sku, qty):
        total = self.reserved.get(sku, 0) + qty
        if total > self.stock.get(sku, 0):
            raise ValueError(f"cannot reserve {qty} {sku}: only {self.stock.get(sku, 0)} in stock")
        self.reserved[sku] = total
        return self.reserved[sku]
