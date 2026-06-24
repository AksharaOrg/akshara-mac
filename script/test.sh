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
  "$ROOT/src/SinhalaTransliterator.m"

"$ROOT/build/TestTransliterator"
echo "Transliterator tests passed"

