#!/bin/sh
# Reads the swing log a debug build keeps on the Quest (one line per hit
# you make: the paddle, the face, the contact, where it went raw and with
# the assist), for tuning the paddle. --clear empties it after reading.
#   game/tools/swings.sh [--clear]
cd "$(dirname "$0")/.." || exit 2
. tools/adb_pick.sh
PKG=com.tinychair.pickleball94vr
"$ADB" exec-out run-as $PKG cat files/swings.log 2>/dev/null || { echo "no swings logged yet (or no headset)"; exit 1; }
[ "$1" = "--clear" ] && "$ADB" exec-out run-as $PKG rm -f files/swings.log && echo "(cleared)"
