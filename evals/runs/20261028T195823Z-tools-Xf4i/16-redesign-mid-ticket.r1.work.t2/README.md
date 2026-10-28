# Sessions

A user who signs in stays signed in for up to 12 hours, unless they sign out. The access token
lasts 20 minutes. The renewal token lasts 12 hours and lives in an HttpOnly cookie, so page scripts
cannot read it. The client renews by posting an empty body to /renew.
