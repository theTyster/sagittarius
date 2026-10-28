# Sessions

A user who signs in stays signed in for up to 12 hours, unless they sign out. The access token
lasts 20 minutes; the client renews it with the renewal token, which lasts 12 hours. The renewal token is in an HttpOnly cookie, so page scripts cannot read it. The client posts an empty body to /renew.
