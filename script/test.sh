#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/build"

clang \
  -fobjc-arc \
  -Wall -Wextra -Werror=return-type \
  -framework Foundation \
  -I "$ROOT/src" \
  -o "$ROOT/build/TestTransliterator" \
  "$ROOT/tests/TestTransliterator.m" \
  "$ROOT/src/SinhalaTransliterator.m" \
  "$ROOT/src/SmartPhoneticMaps.m"

(cd "$ROOT" && "$ROOT/build/TestTransliterator")
echo "Transliterator tests passed"

# Smart Phonetic v2: the Swift port against the research repo's golden file.
swiftc \
  -O \
  -parse-as-library \
  -module-cache-path "$ROOT/build/ModuleCache" \
  -o "$ROOT/build/SmartPhoneticV2Tests" \
  "$ROOT/src/SmartPhoneticV2.swift" \
  "$ROOT/src/SoundLexicon.swift" \
  "$ROOT/src/SmartPhoneticService.swift" \
  "$ROOT/tests/SmartPhoneticV2Tests.swift"

"$ROOT/build/SmartPhoneticV2Tests" "$ROOT"
