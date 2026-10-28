"""Sign-in, page loads, and session renewal for the web app.

The renewal token lives only in the HttpOnly refresh cookie (12 hours), so page scripts cannot
read it. The web client posts an empty body to /renew when the access token is about to expire,
or when it wakes up after a pause; /renew reads the renewal token from the refresh cookie. The
auth cookie (access token, 20 minutes) lets a full page load see who is signed in, and the
refresh cookie renews it after the access token has expired.
"""
from tokens import ACCESS_TTL, RENEWAL_TTL, InvalidToken, mint, validate

AUTH_COOKIE = "auth"
REFRESH_COOKIE = "refresh"


class Response:
    def __init__(self, status: int, body: dict | None = None):
        self.status = status
        self.body = body or {}
        self.cookies: dict[str, str] = {}
        self.cookie_flags: dict[str, dict] = {}

    def set_cookie(self, name: str, value: str, max_age: int, http_only: bool = True):
        self.cookies[name] = value
        self.cookie_flags[name] = {"max_age": max_age, "http_only": http_only}


def _issue(user: str, now: int) -> Response:
    access = mint(user, "access", now)
    renewal = mint(user, "renewal", now)
    resp = Response(200, {"access": access, "user": user})
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


def renew(cookies: dict, now: int) -> Response:
    token = cookies.get(REFRESH_COOKIE)
    if not token:
        return Response(401)
    try:
        claims = validate(token, now)
    except InvalidToken:
        return Response(401)
    if claims["kind"] != "renewal":
        return Response(401)
    return _issue(claims["sub"], now)
