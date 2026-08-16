#!/usr/bin/env bash
# Generate an SVG in generated/ for every .puml file in figures/.
set -euo pipefail

cd "$(dirname "$0")"

src_dir="figures"
out_dir="generated"

mkdir -p "$out_dir"

shopt -s nullglob
puml_files=("$src_dir"/*.puml)

if [ ${#puml_files[@]} -eq 0 ]; then
  echo "No .puml files found in $src_dir/"
  exit 0
fi

for f in "${puml_files[@]}"; do
  echo "Generating SVG for $f"
  plantuml -tsvg -o "$(pwd)/$out_dir" "$f"
done

# PlantUML draws ports of nested blocks inside the border instead of on it;
# snap the borders onto the port squares (SysML notation).
python3 scripts/fix_svg_ports.py "$out_dir"/*.svg

echo "Done. SVGs written to $out_dir/"
