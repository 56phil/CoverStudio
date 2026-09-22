#!/bin/bash
# Print the release version.
#
# The version is declared once, in `Sources/CoverStudio/CLI.swift`, and this script
# is the only thing that reads it. Everything else calls this script, so no build
# step carries its own copy of the number.
#
# That matters because the number has already drifted once: the app bundle reached
# 0.1.13 while `CoverStudio --version` still printed a hardcoded 0.1.0, because a
# second copy lived in a plist nothing read and a third defaulted inside
# package-release.sh.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$PROJECT_DIR/Sources/CoverStudio/CLI.swift"

VERSION="$(sed -n 's/^let coverStudioVersion = "\(.*\)"$/\1/p' "$SOURCE")"

if [[ -z "$VERSION" ]]; then
  echo "error: no 'let coverStudioVersion = \"...\"' line found in $SOURCE" >&2
  exit 1
fi

printf '%s\n' "$VERSION"
