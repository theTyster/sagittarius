"""Sign-in, page loads, and session renewal for the web app.

The web client keeps the access token in memory. The renewal token lives only in an HttpOnly
cookie. The client posts an empty body to /renew (the browser sends the cookie) when the access
token is about to expire, or when it wakes up after a pause. The auth cookie lets a full page
load (server-rendered pages) see who is signed in.
"""
from tokens import InvalidToken, mint, validate

AUTH_COOKIE = "auth"
RENEWAL_COOKIE = "renewal"
COOKIE_MAX_AGE = 12 * 60 * 60


class Response:
    def __init__(self, status: int, body: dict | None = None):
        self.status = status
        self.body = body or {}
        self.cookies: dict[str, str] = {}
        self.cookie_attrs: dict[str, dict] = {}

    def set_cookie(self, name: str, value: str, max_age: int, http_only: bool = True):
        self.cookies[name] = value
        self.cookie_attrs[name] = {"max_age": max_age, "http_only": http_only}


def _issue(user: str, now: int) -> Response:
    access = mint(user, "access", now)
    renewal = mint(user, "renewal", now)
    resp = Response(200, {"access": access})
    resp.set_cookie(AUTH_COOKIE, access, COOKIE_MAX_AGE, http_only=True)
    resp.set_cookie(RENEWAL_COOKIE, renewal, COOKIE_MAX_AGE, http_only=True)
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
    token = cookies.get(RENEWAL_COOKIE)  # body is empty: page scripts never see this token
    if not token:
        return Response(401)
    claims = validate(token, now)  # InvalidToken propagates: the framework turns it into a 500
    return _issue(claims["sub"], now)
