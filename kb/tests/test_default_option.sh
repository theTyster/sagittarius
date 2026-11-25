#!/usr/bin/env bash
# Tests of the default of a question (spec KB question-default-option c1 to c3). Usage: kb/tests/test_default_option.sh [path-to-orbit-kb]
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
exec python3 -I "$here/kb_default_option.py" "${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}"
