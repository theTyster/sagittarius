"""Sign-in, page loads, and session renewal for the web app.

The web client keeps the access and renewal tokens in memory. It posts the renewal token to
/renew when the access token is about to expire, or when it wakes up after a pause. The auth
cookie lets a full page load (server-rendered pages) see who is signed in.
"""
from tokens import InvalidToken, mint, validate

AUTH_COOKIE = "auth"
COOKIE_MAX_AGE = 12 * 60 * 60


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
    resp = Response(200, {"access": access, "renewal": renewal})
    # The cookie outlives the 20-minute access token, so it carries the renewal token.
    resp.set_cookie(AUTH_COOKIE, renewal, COOKIE_MAX_AGE, http_only=True)
    return resp


def sign_in(user: str, password: str, now: int) -> Response:
    if not password:
        return Response(401)
    return _issue(user, now)


def page_load(cookies: dict, now: int) -> Response:
    token = cookies.get(AUTH_COOKIE)
    if not token:
        return Response(401)
    try:
        return Response(200, {"user": validate(token, now)["sub"]})
    except InvalidToken:
        return Response(401)


def renew(body: dict, cookies: dict, now: int) -> Response:
    token = body.get("renewal") or cookies.get(AUTH_COOKIE)
    if not token:
        return Response(401)
    claims = validate(token, now)  # InvalidToken propagates: the framework turns it into a 500
    return _issue(claims["sub"], now)
