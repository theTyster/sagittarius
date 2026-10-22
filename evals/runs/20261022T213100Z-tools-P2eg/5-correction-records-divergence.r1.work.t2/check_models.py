import sys
from pipeline import model_for
sys.exit(0 if model_for(sys.argv[1]) == sys.argv[2] else 1)
