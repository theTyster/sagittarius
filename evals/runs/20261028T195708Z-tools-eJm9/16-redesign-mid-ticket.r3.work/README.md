# Sessions

A user who signs in stays signed in for up to 12 hours, unless they sign out. The access token
lasts 20 minutes; the client renews it by posting an empty body to /renew. The renewal token lasts
12 hours. It lives only in an HttpOnly cookie (path /renew, SameSite=Strict), so page scripts
cannot read it. No response body contains it.
