#!/usr/bin/env bash
# Generate UML diagrams, then compile the thesis.
# Usage: ./compile.sh [output.pdf]   (default: generated/thesis.pdf)
set -euo pipefail

cd "$(dirname "$0")"

out="${1:-generated/thesis.pdf}"

./generate_uml.sh
echo "Compiling thesis.typ -> $out"
typst compile thesis.typ "$out"
echo "Done."
