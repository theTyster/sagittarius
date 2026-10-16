#!/usr/bin/env bash
# run-matrix.sh CORE DISC
#
# Runs the 7 queries on each of the 7 knowledge bases (kb.pl and kb-cf1.pl ..
# kb-cf5b.pl) under --forall=all, prev and sasp, with the module files CORE and
# DISC. Each run is `bash run-one.sh ALGO QUERY CORE DISC KB`, so each run is
#   timeout 30 scasp --unknown=error --forall=ALGO -s 0 --query=QUERY CORE DISC KB
# Prints one summary line per run (the format of run-one.sh).
#
# Example: bash run-matrix.sh core-min.pl discovery.pl > matrix-base.txt

core=$1
disc=$2

for kb in kb.pl kb-cf1.pl kb-cf2.pl kb-cf3.pl kb-cf4.pl kb-cf5.pl kb-cf5b.pl; do
  for q in 'discovery_ready' 'question_waits(Q)' 'no_falsifier(C)' 'finding_lead(F)' 'unasked_finding(F)' 'weak_rule(R)' 'some_current_refuted'; do
    for algo in all prev sasp; do
      bash run-one.sh "$algo" "$q" "$core" "$disc" "$kb"
    done
  done
done
