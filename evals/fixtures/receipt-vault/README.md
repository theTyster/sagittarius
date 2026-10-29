# Expense claims

Employees submit expense claims with a scanned receipt. An approver opens the
receipt to check the claim before it is paid.

Rules:

- A claim can be submitted up to 90 days after the purchase date.
- An approver can open a claim's receipt for 60 days after the claim is submitted.

claims.py holds the claims. vault.py is the company document vault.

Run the tests with `python3 -m unittest`.
