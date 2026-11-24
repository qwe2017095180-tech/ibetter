#!/usr/bin/env bash
# One-command release script: bumps version, builds Release APK, tags & uploads to GitHub Releases.
#
# Usage:
#   ./scripts/release.sh <version> [release-notes]
# Example:
#   ./scripts/release.sh 1.0.1 "新增项目统计页与成就系统"
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <semver e.g. 1.0.1> [changelog]"
  exit 1
fi

NEW_VER="${1#v}"
NOTES="${2:-版本 v${NEW_VER} 更新}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export JAVA_HOME="${JAVA_HOME:-$HOME/development/jdk-21/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$HOME/development/flutter/bin:$HOME/.local/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Infer GitHub owner/repo from git origin (or UPDATE_REPO env var).
REPO="${UPDATE_REPO:-}"
if [ -z "$REPO" ]; then
  ORIGIN_URL="$(git remote get-url origin 2>/dev/null || true)"
  REPO="$(echo "$ORIGIN_URL" | sed -E 's#^(https?://github\.com/|git@github\.com:)##; s#\.git$##')"
fi

if [ -z "$REPO" ]; then
  echo "Error: git origin not set and UPDATE_REPO is empty."
  echo "Run: gh auth login && gh repo create ibetter --public --source=. --push"
  exit 1
fi

# Increment build number in pubspec.yaml.
CURRENT_LINE="$(grep -E '^version:' pubspec.yaml)"
CURRENT_BUILD="$(echo "$CURRENT_LINE" | sed -E 's/.*\+([0-9]+).*/\1/')"
NEXT_BUILD=$((CURRENT_BUILD + 1))
sed -i '' -E "s/^version:.*/version: ${NEW_VER}+${NEXT_BUILD}/" pubspec.yaml
echo "Bumped pubspec.yaml -> ${NEW_VER}+${NEXT_BUILD} (repo: ${REPO})"

# Build Release APK with baked-in UPDATE_REPO (optional UPDATE_MIRROR).
DART_DEFINES=(--dart-define="UPDATE_REPO=${REPO}")
if [ -n "${UPDATE_MIRROR:-}" ]; then
  DART_DEFINES+=(--dart-define="UPDATE_MIRROR=${UPDATE_MIRROR}")
fi

flutter build apk --release "${DART_DEFINES[@]}"
APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
APK_OUT="build/app/outputs/flutter-apk/ibetter-v${NEW_VER}.apk"
cp "$APK_SRC" "$APK_OUT"

git add pubspec.yaml
git commit -m "chore(release): v${NEW_VER}+${NEXT_BUILD}" || true
git tag -f "v${NEW_VER}"
git push origin HEAD --tags

gh release create "v${NEW_VER}" "$APK_OUT" \
  --repo "$REPO" \
  --title "iBetter v${NEW_VER}" \
  --notes "$NOTES"

echo "Released v${NEW_VER} to https://github.com/${REPO}/releases/tag/v${NEW_VER}"
