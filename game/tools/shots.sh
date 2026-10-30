#!/bin/sh
# Renders the standard screenshots into shots/ at the repo root (ignored
# by git: for looking at locally). Takes a minute; opens a window per shot.
#   game/tools/shots.sh            # all of them
#   game/tools/shots.sh partner    # just the ones whose name has "partner"
cd "$(dirname "$0")/.." || exit 2
out="$(cd .. && pwd)/shots"
mkdir -p "$out"
shot() {  # name mode frames [extra...]
  name=$1; shift
  case "$name" in *"$FILTER"*) ;; *) return ;; esac
  godot --path . --resolution 1280x720 -s res://tools/screenshot.gd -- "$1" "$2" "$out/$name.png" "$3" "$4" \
    >/dev/null 2>&1 && echo "  shots/$name.png"
}
FILTER="${1:-}"
echo "screenshots:"
shot lobby lobby 300
shot singles-demo demo 900
shot doubles-demo demo 600 doubles
shot ball-machine machine 400
shot dink-partner partner 420
shot dink-partner-cross partner 420 cross
shot lesson-dink lesson 200 x 3
shot online-host online 900
shot online-guest online_guest 900
for v in 0 1 2 3; do
  shot "watch-$v" watch 99999 "view=$v" tick=900
done
shot watch-replay watch 99999 view=1 replay=1500
for v in PARK LAKESIDE SUNSET GYM SPACE; do
  shot "venue-$(echo $v | tr A-Z a-z)" demo 500 x "venue=$v"
done
