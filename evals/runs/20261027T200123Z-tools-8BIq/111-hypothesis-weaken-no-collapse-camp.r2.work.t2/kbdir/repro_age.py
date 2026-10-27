import sys; sys.path.insert(0, "/tmp/tmp.LElOXMaMjZ")
import os; os.chdir("/tmp/tmp.LElOXMaMjZ")
import camp
# child aged 10 on first day of an "ages 7 to 10" session must not be told "outside the age range"
sys.exit(0 if "outside the age range" not in camp.signup_check("S-212", "2017-04-21") else 1)
