#!/usr/bin/env bash

set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SETUP="$ROOT/setup.sh"
README="$ROOT/README.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

bash -n "$SETUP"

if grep -F 'Reset it?' "$SETUP" >/dev/null; then
  fail 'installer must not offer to reset shell configuration files'
fi

if grep -F 'rm "$rc_file"' "$SETUP" >/dev/null || grep -F 'rm "$FISH_CONFIG"' "$SETUP" >/dev/null; then
  fail 'installer must not delete shell configuration files'
fi

grep -F 'Starship already configured; preserving existing shell settings' "$SETUP" >/dev/null || \
  fail 'installer must preserve an existing Starship initialization'

grep -F 'git clone https://git.intp.me/rudgh/starship.git' "$README" >/dev/null || \
  fail 'README must provide a one-command install from git.intp.me'

printf 'PASS: shell configuration is non-destructive\n'
