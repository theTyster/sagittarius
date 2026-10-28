import sys
from pipeline import model_for
step, want = sys.argv[1:]
assert model_for(step) == want, (step, model_for(step), want)
