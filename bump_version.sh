#!/usr/bin/env bash
# bump_version.sh
# ─────────────────────────────────────────────────────────────────────────────
# Run this script before every release build.
# It reads the version from pubspec.yaml and updates CACHE_NAME in sw.js
# so returning users always get fresh files after an update.
#
# Usage:
#   chmod +x bump_version.sh   (first time only)
#   ./bump_version.sh
#
# Then build:
#   flutter build web --release
#   flutter build appbundle --release
# ─────────────────────────────────────────────────────────────────────────────

set -e

PUBSPEC="pubspec.yaml"
SW="web/sw.js"

# Extract version string from pubspec.yaml (e.g. "1.0.0+1" → "1.0.0-build1")
VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: //' | tr '+' '-build' | tr -d ' \r')

if [ -z "$VERSION" ]; then
  echo "❌ Could not read version from $PUBSPEC"
  exit 1
fi

NEW_CACHE="searchwars-$VERSION"

# Update CACHE_NAME in sw.js
sed -i.bak "s/const CACHE_NAME = '[^']*'/const CACHE_NAME = '$NEW_CACHE'/" "$SW"
rm -f "$SW.bak"

echo "✅ CACHE_NAME updated to: $NEW_CACHE"
echo "   in: $SW"
echo ""
echo "Next steps:"
echo "  flutter build web --release"
echo "  flutter build appbundle --release"
