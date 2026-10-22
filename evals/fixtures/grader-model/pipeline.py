"""Nightly summary pipeline: one model writes the summaries, another grades them."""

MODELS = {
    "summarize": "large",
    "grade": "large",
}


def model_for(step):
    return MODELS[step]
