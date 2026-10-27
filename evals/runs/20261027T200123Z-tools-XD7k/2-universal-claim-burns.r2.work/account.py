class Refused(Exception):
    pass


def withdraw(balance, amount, overdraft_limit):
    """Return the balance after the withdrawal. Refuse it if it goes past the overdraft limit."""
    if amount <= 0:
        raise Refused("amount must be positive")
    new_balance = balance - amount
    if new_balance < -overdraft_limit:
        raise Refused("over the overdraft limit")
    return new_balance
