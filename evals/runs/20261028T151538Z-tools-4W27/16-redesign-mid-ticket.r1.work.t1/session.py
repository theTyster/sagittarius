"""Sign-in, page loads, and session renewal for the web app.

The web client keeps the access and renewal tokens in memory. It posts the renewal token to
/renew when the access token is about to expire, or when it wakes up after a pause. The auth
cookie (access token, 20 minutes) and the refresh cookie (renewal token, 12 hours) let a full
page load see who is signed in, even after the access token has expired.
"""
from tokens import ACCESS_TTL, RENEWAL_TTL, InvalidToken, mint, validate

AUTH_COOKIE = "auth"
REFRESH_COOKIE = "refresh"


class Response:
    def __init__(self, status: int, body: dict | None = None):
        self.status = status
        self.body = body or {}
        self.cookies: dict[str, str] = {}

    def set_cookie(self, name: str, value: str, max_age: int, http_only: bool = True):
        self.cookies[name] = value


def _issue(user: str, now: int) -> Response:
    access = mint(user, "access", now)
    renewal = mint(user, "renewal", now)
    resp = Response(200, {"access": access, "renewal": renewal, "user": user})
    resp.set_cookie(AUTH_COOKIE, access, ACCESS_TTL, http_only=True)
    resp.set_cookie(REFRESH_COOKIE, renewal, RENEWAL_TTL, http_only=True)
    return resp


def sign_in(user: str, password: str, now: int) -> Response:
    if not password:
        return Response(401)
    return _issue(user, now)


def page_load(cookies: dict, now: int) -> Response:
    try:
        claims = validate(cookies[AUTH_COOKIE], now)
        if claims["kind"] == "access":
            return Response(200, {"user": claims["sub"]})
    except (KeyError, InvalidToken):
        pass
    # The access token has expired, but the refresh cookie may still be valid: sign in again silently.
    try:
        claims = validate(cookies[REFRESH_COOKIE], now)
        if claims["kind"] == "renewal":
            return _issue(claims["sub"], now)
    except (KeyError, InvalidToken):
        pass
    return Response(401)


def renew(body: dict, cookies: dict, now: int) -> Response:
    token = body.get("renewal")
    if not token:
        return Response(401)
    try:
        claims = validate(token, now)
    except InvalidToken:
        return Response(401)
    if claims["kind"] != "renewal":
        return Response(401)
    return _issue(claims["sub"], now)
