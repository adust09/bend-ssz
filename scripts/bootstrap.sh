#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MT="$ROOT/deps/bend-merkle-tree"
MT_PIN="53d47b46c28803e8e6ccc67e5faabb0254534dbc"
MT_URL="https://github.com/adust09/bend-merkle-tree.git"

command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 127; }

if [ ! -d "$MT/.git" ]; then
  mkdir -p "$ROOT/deps"
  git clone --filter=blob:none "$MT_URL" "$MT"
fi

if [ -n "$(git -C "$MT" status --short)" ]; then
  echo "refusing to use a modified merkle-tree checkout at $MT" >&2
  exit 1
fi

current=$(git -C "$MT" rev-parse HEAD)
if [ "$current" != "$MT_PIN" ]; then
  git -C "$MT" fetch origin "$MT_PIN"
  git -C "$MT" checkout --detach "$MT_PIN"
fi

printf 'bend-merkle-tree=%s\n' "$MT_PIN"
