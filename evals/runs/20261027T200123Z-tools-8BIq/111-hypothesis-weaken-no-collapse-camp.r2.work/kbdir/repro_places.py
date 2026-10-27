import sys; sys.path.insert(0, "/tmp/tmp.LElOXMaMjZ")
import os; os.chdir("/tmp/tmp.LElOXMaMjZ")
import camp
# office count: 11 booked, capacity 12 -> 1 place should be shown for S-207
sys.exit(0 if camp.places_left("S-207") == 1 else 1)
