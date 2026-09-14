#!/usr/bin/env bash
# Render every page of an agent_ops deck to PNG with headless Chrome.
#
#   render.sh <deck.html> <out_dir> [height] [pages]
#
#   height  viewport height, default 900 (what the room sees). Use 2000 to see a
#           tall page in full instead of just its top.
#   pages   optional space-separated list, e.g. "3 7 12". Default: all.
#
# Output: <out_dir>/sNN.png plus <out_dir>/sNN-notes.png (notes panel open).
set -euo pipefail
DECK="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
OUT="$2"; H="${3:-900}"; PAGES="${4:-}"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
mkdir -p "$OUT"
N=$(grep -c '<section class="page' "$DECK")
[ -z "$PAGES" ] && PAGES=$(seq 1 "$N")
for p in $PAGES; do
  s=$(printf 's%02d' "$p")
  "$CH" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=1500 --window-size=1280,"$H" \
    --screenshot="$OUT/$s.png" "file://$DECK#$s" >/dev/null 2>&1
  "$CH" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=1500 --window-size=1280,"$H" \
    --screenshot="$OUT/$s-notes.png" "file://$DECK#$s-notes" >/dev/null 2>&1
done
echo "$N pages; rendered $(ls "$OUT" | grep -c 'png$') PNGs to $OUT"
