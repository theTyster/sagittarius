#!/bin/sh
# T16 c4: the decks hold no client names. Prints matches and exits 1 if any.
# The names are split so this file does not hold them itself.
cd "$(dirname "$0")" || exit 2
pat="delta""dental|CO""BRA|mind""hub|Hogg""Wood"
if grep -inE "$pat" index.html essentials.html; then
  echo "client name found in a deck" >&2; exit 1
fi
echo "ok: no client names in the decks"
