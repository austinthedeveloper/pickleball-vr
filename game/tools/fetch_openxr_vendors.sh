#!/bin/sh
# Fetches the Godot OpenXR Vendors plugin (Meta's OpenXR loader for the
# Quest) into game/addons/, pinned to one release and its SHA-256
# (ADR-001, design/QUEST_SETUP.md). The addon is ~80 MB of binaries, so
# git ignores it; run this once per checkout.
#   game/tools/fetch_openxr_vendors.sh            # download, verify, install
#   ZIP=path/to/addon.zip game/tools/fetch_openxr_vendors.sh   # a zip you already have
VERSION="5.1.0-stable"
SHA256="6a838dbdf4115549e4511ebee0da9a5dcc8f9f6258d4cc2f2ee57a907a3e2911"
URL="https://github.com/GodotVR/godot_openxr_vendors/releases/download/$VERSION/godotopenxrvendorsaddon.zip"
cd "$(dirname "$0")/.." || exit 2
work=$(mktemp -d)
zip="${ZIP:-$work/addon.zip}"
if [ -z "$ZIP" ]; then
  echo "downloading OpenXR Vendors $VERSION..."
  curl -fsSL -o "$zip" "$URL" || { echo "download failed"; exit 1; }
fi
got=$(shasum -a 256 "$zip" | cut -d' ' -f1)
if [ "$got" != "$SHA256" ]; then
  echo "SHA-256 mismatch: got $got, want $SHA256"; rm -rf "$work"; exit 1
fi
unzip -q "$zip" -d "$work/unz" || exit 1
rm -rf addons/godotopenxrvendors
mkdir -p addons
cp -R "$work/unz/asset/addons/godotopenxrvendors" addons/
echo "$VERSION" > addons/godotopenxrvendors/VERSION
rm -rf "$work"
echo "installed addons/godotopenxrvendors ($VERSION)"
