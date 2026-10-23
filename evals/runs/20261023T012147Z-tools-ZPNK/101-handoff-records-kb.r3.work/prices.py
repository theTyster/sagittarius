def format_price(cents):
    """Show an amount in cents as dollars, for example 1999 -> '$19.99'."""
    return f"${cents / 100:.2f}"
