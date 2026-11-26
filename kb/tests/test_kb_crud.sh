#!/usr/bin/env bash
# Tests of strike, replace and erase (spec KB kb-crud c1 to c4, c6). Usage: kb/tests/test_kb_crud.sh [path-to-orbit-kb]
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
exec python3 -I "$here/kb_crud.py" "${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}"
