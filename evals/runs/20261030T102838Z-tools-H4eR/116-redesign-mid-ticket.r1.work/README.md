# Newsletter send list

Every Friday the send job calls `recipients()` and mails the newsletter to each address it
returns. The unsubscribe link in each newsletter opens a form, and the form calls
`opt_out(email)` with the address that the reader types.

The rule for readers: after a reader opts out, they never get the newsletter again. Readers
type their address however they like, so two addresses are the same address when they differ
only in capital letters or in spaces before or after them, in `subscribers.csv` or in
`optouts.csv`. Each reader gets one copy.

`subscribers.csv` is an export of the sign-up form. `optouts.csv` has one row for each opt-out. It stores the SHA-256 hash (hex) of the normal form of the address (stripped, lower case), never the address.
