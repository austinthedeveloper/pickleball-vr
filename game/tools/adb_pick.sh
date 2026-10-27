# Sourced by the Quest scripts: sets ADB to the adb that won't fight.
# Meta Quest Developer Hub runs its own adb server (a different version);
# two versions kill each other's server, so while it's running, use its.
MQDH_ADB="/Applications/Meta Quest Developer Hub.app/Contents/Resources/bin/adb"
ADB=adb
if pgrep -f "Meta Quest Developer Hub" >/dev/null 2>&1 && [ -x "$MQDH_ADB" ]; then
  ADB="$MQDH_ADB"
fi
