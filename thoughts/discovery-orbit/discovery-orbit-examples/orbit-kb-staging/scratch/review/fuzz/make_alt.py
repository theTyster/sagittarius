"""Write a copy of an assembled program with model_trusted/1 as one clause.

Usage: python3 -I fuzz/make_alt.py IN OUT
model_trusted(M) :- model_sane(M), trust_root(M).
trust_root(M) :- model_calibrated(M).
trust_root(M) :- derived_from(M, M0), model_sane(M0), model_calibrated(M0).
"""
import sys

src, dst = sys.argv[1], sys.argv[2]
text = open(src).read()
old1 = "model_trusted(M) :- model_sane(M), model_calibrated(M).\n"
old2 = "model_trusted(M) :- model_sane(M), derived_from(M, M0), model_sane(M0), model_calibrated(M0).\n"
assert text.count(old1) == 1 and text.count(old2) == 1
new = ("model_trusted(M) :- model_sane(M), trust_root(M).\n"
       "trust_root(M) :- model_calibrated(M).\n"
       "trust_root(M) :- derived_from(M, M0), model_sane(M0), model_calibrated(M0).\n")
text = text.replace(old1, new).replace(old2, "")
open(dst, "w").write(text)
print("written", dst)
