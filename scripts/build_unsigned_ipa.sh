#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script requires macOS with Xcode (run the ios-unsigned workflow in Codemagic)." >&2
  exit 1
fi

# Fail early if Git LFS pointers were checked out instead of the Unity libraries.
for library in Libraries/baselib.a Libraries/libil2cpp.a Libraries/libiPhone-lib.a; do
  if [[ ! -s "$library" ]]; then
    echo "Missing library: $library" >&2
    exit 1
  fi
  if head -c 128 "$library" | grep -q 'version https://git-lfs.github.com/spec/v1'; then
    echo "Git LFS library was not downloaded: $library. Run git lfs pull." >&2
    exit 1
  fi
done

OUTPUT_DIR="$PROJECT_ROOT/build/ios"
ARCHIVE_PATH="$OUTPUT_DIR/unsigned.xcarchive"
IPA_PATH="$OUTPUT_DIR/ipa/NroHan-unsigned.ipa"
mkdir -p "$OUTPUT_DIR/ipa" "$OUTPUT_DIR/logs"

xcodebuild -version
xcodebuild archive \
  -project Unity-iPhone.xcodeproj \
  -scheme Unity-iPhone \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$OUTPUT_DIR/DerivedData" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  ENABLE_BITCODE=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  2>&1 | tee "$OUTPUT_DIR/logs/xcodebuild.log"

shopt -s nullglob
apps=("$ARCHIVE_PATH/Products/Applications/"*.app)
if [[ ${#apps[@]} -ne 1 ]]; then
  echo "Expected exactly one archived app, found ${#apps[@]}." >&2
  exit 1
fi
APP_PATH="${apps[0]}"
APP_EXECUTABLE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_PATH/Info.plist")
if [[ ! -f "$APP_PATH/$APP_EXECUTABLE" || ! -d "$APP_PATH/Frameworks/UnityFramework.framework" ]]; then
  echo "Archive is missing the app executable or embedded UnityFramework." >&2
  exit 1
fi

# Package the device .app directly; exportArchive requires signing assets.
STAGING_DIR=$(mktemp -d "$OUTPUT_DIR/ipa-staging.XXXXXX")
trap 'rm -rf "$STAGING_DIR"' EXIT
mkdir -p "$STAGING_DIR/Payload"
ditto "$APP_PATH" "$STAGING_DIR/Payload/$(basename "$APP_PATH")"
ditto -c -k --sequesterRsrc --keepParent "$STAGING_DIR/Payload" "$IPA_PATH"
unzip -tq "$IPA_PATH"
echo "Unsigned IPA: $IPA_PATH"
