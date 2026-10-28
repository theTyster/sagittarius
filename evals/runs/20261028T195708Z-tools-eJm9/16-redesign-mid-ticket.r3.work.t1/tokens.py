"""Signed session tokens. Tokens are stateless: the server keeps no record of them."""
import hashlib
import hmac
import json
from base64 import urlsafe_b64decode, urlsafe_b64encode

SECRET = b"dev-only-secret"
ACCESS_TTL = 20 * 60          # seconds
RENEWAL_TTL = 12 * 60 * 60        # seconds
CLOCK_SKEW = 3 * 60           # seconds of grace after expiry


class InvalidToken(Exception):
    pass


def _sign(body: bytes) -> str:
    return hmac.new(SECRET, body, hashlib.sha256).hexdigest()


def mint(user: str, kind: str, now: int) -> str:
    ttl = ACCESS_TTL if kind == "access" else RENEWAL_TTL
    body = json.dumps({"sub": user, "kind": kind, "exp": now + ttl}).encode()
    return urlsafe_b64encode(body).decode() + "." + _sign(body)


def validate(token: str, now: int) -> dict:
    """Check the signature and the expiry (with CLOCK_SKEW of grace). Returns the claims."""
    try:
        enc, sig = token.split(".")
        body = urlsafe_b64decode(enc.encode())
    except Exception as e:
        raise InvalidToken("malformed") from e
    if not hmac.compare_digest(sig, _sign(body)):
        raise InvalidToken("bad signature")
    claims = json.loads(body)
    if now > claims["exp"] + CLOCK_SKEW:
        raise InvalidToken("expired")
    return claims
