NUMERALS = [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]


def to_roman(n):
    """Roman numeral for n, from 1 to 39."""
    if not 1 <= n <= 39:
        raise ValueError(f"out of range: {n}")
    out = []
    for value, letters in NUMERALS:
        while n >= value:
            out.append(letters)
            n -= value
    return "".join(out)
