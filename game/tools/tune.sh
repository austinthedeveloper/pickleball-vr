#!/bin/sh
# Developer tuning (ADR-020): the overrides set on the TUNING pages of a
# debug build on the Quest.
#   game/tools/tune.sh show     what's changed on the headset, against the source
#   game/tools/tune.sh sync     write those values into the source as the defaults
#   game/tools/tune.sh clear    forget the headset's overrides (after a sync and a fresh install)
# Off the headset: `tune.sh sync FILE` syncs a tuning.cfg you already have.
cd "$(dirname "$0")/.." || exit 2
PKG=com.tinychair.pickleball94vr
CFG=${TMPDIR:-/tmp}/pickleball_tuning.cfg
pull() {
	. tools/adb_pick.sh
	# exec-out passes the headset's own errors through as output: a real
	# file starts with a [section].
	"$ADB" exec-out run-as $PKG cat files/tuning.cfg > "$CFG" 2>/dev/null
	grep -q '^\[' "$CFG" 2>/dev/null || { echo "no tuning saved on the headset (or no headset)"; exit 1; }
}
case "$1" in
	show) pull; python3 tools/tune_sync.py "$CFG" --dry-run ;;
	sync)
		if [ -n "$2" ]; then CFG=$2; else pull; fi
		python3 tools/tune_sync.py "$CFG" ;;
	clear) . tools/adb_pick.sh; "$ADB" exec-out run-as $PKG rm -f files/tuning.cfg && echo "(cleared)" ;;
	*) sed -n 2,8p "$0"; exit 2 ;;
esac
