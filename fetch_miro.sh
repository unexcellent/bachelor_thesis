#!/usr/bin/env bash
# Download the SysML diagrams from the Miro board into figures/imported/.
# Requires node + npm; dependencies are installed on first run.
set -euo pipefail

cd "$(dirname "$0")"

out_dir="figures/imported"

if [ ! -d scripts/miro/node_modules ]; then
  echo "Installing Miro fetch dependencies (first run only)..."
  npm --prefix scripts/miro install
fi

node scripts/miro/fetch_diagrams.mjs "$out_dir"
