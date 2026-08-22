#!/usr/bin/env bash
# Fetch the diagrams from Miro, then compile the thesis.
# Usage: ./compile.sh [output.pdf]   (default: generated/thesis.pdf)
# Set SKIP_MIRO=1 to skip downloading the diagrams from Miro.
set -euo pipefail

cd "$(dirname "$0")"

out="${1:-generated/thesis.pdf}"

if [ "${SKIP_MIRO:-0}" != "1" ]; then
  if ! ./fetch_miro.sh; then
    echo "WARNING: Miro download failed; keeping existing figures/imported/" >&2
  fi
fi
echo "Compiling thesis.typ -> $out"
typst compile thesis.typ "$out"
echo "Done."
