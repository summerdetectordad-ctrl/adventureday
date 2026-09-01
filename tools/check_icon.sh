#!/usr/bin/env bash
# Read an .ico back and confirm every entry points at a real PNG inside it.
ICO="$1"
total=$(stat -c%s "$ICO")
rd() { od -A n -t u1 -j "$1" -N "$2" "$ICO" | tr -s ' ' | sed 's/^ //'; }
set -- $(rd 0 6)
type=$(( $3 + $4 * 256 )); count=$(( $5 + $6 * 256 ))
echo "  type=$type (1=icon)  images=$count  file=$total bytes"
ok=1
for i in $(seq 0 $((count - 1))); do
	e=$((6 + i * 16))
	set -- $(rd $e 16)
	w=$1; h=$2
	size=$(( $9 + ${10} * 256 + ${11} * 65536 + ${12} * 16777216 ))
	off=$(( ${13} + ${14} * 256 + ${15} * 65536 + ${16} * 16777216 ))
	[ "$w" -eq 0 ] && w=256
	[ "$h" -eq 0 ] && h=256
	magic=$(od -A n -t x1 -j "$off" -N 4 "$ICO" | tr -d ' ')
	inside="no"
	[ $((off + size)) -le "$total" ] && inside="yes"
	png="no"
	[ "$magic" = "89504e47" ] && png="yes"
	printf "  %3dx%-3d  offset=%-7d size=%-7d inside=%s png=%s\n" "$w" "$h" "$off" "$size" "$inside" "$png"
	[ "$inside" = "yes" ] && [ "$png" = "yes" ] || ok=0
done
[ "$ok" -eq 1 ] && echo "  VALID" || echo "  BROKEN"
