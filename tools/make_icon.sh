#!/usr/bin/env bash
# Pack the rendered icon PNGs into a multi-size Windows .ico.
#
#   ./tools/make_icon.sh <folder with ico_16.png..ico_256.png> <out.ico>
#
# Windows wants 16/32/48/64/128/256. With only one size in the file the export
# warns and Windows picks a badly scaled icon for the taskbar and small views.
#
# A modern .ico can hold PNGs directly, so this is a header, one directory
# entry per size, then the PNG bytes.
#
# Octal escapes (\NNN) are used rather than hex: bash's printf reads \x greedily
# and trips over some byte values, which produced a subtly wrong file.
set -e
SRC="$1"
OUT="$2"
SIZES="16 32 48 64 128 256"

byte()  { printf "$(printf '\\%03o' "$(( $1 & 255 ))")"; }
le16()  { byte "$1"; byte "$(( $1 >> 8 ))"; }
le32()  { byte "$1"; byte "$(( $1 >> 8 ))"; byte "$(( $1 >> 16 ))"; byte "$(( $1 >> 24 ))"; }

n=0
for s in $SIZES; do n=$((n + 1)); done

{
	le16 0        # reserved
	le16 1        # type: icon
	le16 "$n"     # how many images
} > "$OUT"

# Directory entries. The images start after the header and all the entries.
offset=$((6 + 16 * n))
for s in $SIZES; do
	bytes=$(stat -c%s "$SRC/ico_$s.png")
	dim=$s
	[ "$s" -ge 256 ] && dim=0      # 0 means 256 in the ICO format
	{
		byte "$dim"; byte "$dim"
		byte 0; byte 0             # no palette, reserved
		le16 1                     # one colour plane
		le16 32                    # 32 bits per pixel
		le32 "$bytes"
		le32 "$offset"
	} >> "$OUT"
	offset=$((offset + bytes))
done

for s in $SIZES; do
	cat "$SRC/ico_$s.png" >> "$OUT"
done

echo "wrote $OUT ($(stat -c%s "$OUT") bytes, $n sizes)"
