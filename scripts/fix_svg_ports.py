#!/usr/bin/env python3
"""Snap PlantUML block borders onto their port squares.

PlantUML draws the ports of a nested component ~12px inside the
component's border instead of straddling it (SysML notation requires
ports to sit ON the block boundary). Graphviz/PlantUML offer no knob
for this, so this script moves each affected border line so it passes
through the centers of the port squares hugging it.

Usage: fix_svg_ports.py FILE.svg [FILE.svg ...]
"""
import re
import sys

PORT_SIZE = 12       # side length of PlantUML port squares
SNAP_RANGE = 25      # max distance border <-> square center to snap


def rect_attrs(rect):
    return {k: float(v) for k, v in re.findall(r'(?<=\s)(x|y|width|height)="([\d.]+)"', rect)}


def fix(path):
    svg = open(path).read()
    rects = re.findall(r'<rect[^>]*/>', svg)

    ports = []      # (cx, cy) of port squares
    for r in rects:
        a = rect_attrs(r)
        if a.get("width") == PORT_SIZE and a.get("height") == PORT_SIZE:
            ports.append((a["x"] + PORT_SIZE / 2, a["y"] + PORT_SIZE / 2))

    changed = 0
    for r in rects:
        a = rect_attrs(r)
        if 'fill="none"' not in r or a.get("width", 0) < 50:
            continue  # not a block border
        x0, y0 = a["x"], a["y"]
        x1, y1 = x0 + a["width"], y0 + a["height"]
        inside = [p for p in ports if x0 - 1 < p[0] < x1 + 1 and y0 - 1 < p[1] < y1 + 1]

        # snap each side to the outermost port-square center hugging it
        left = [p[0] for p in inside if p[0] - x0 < SNAP_RANGE]
        right = [p[0] for p in inside if x1 - p[0] < SNAP_RANGE]
        top = [p[1] for p in inside if p[1] - y0 < SNAP_RANGE]
        bottom = [p[1] for p in inside if y1 - p[1] < SNAP_RANGE]
        nx0 = min(left) if left else x0
        nx1 = max(right) if right else x1
        ny0 = min(top) if top else y0
        ny1 = max(bottom) if bottom else y1

        if (nx0, nx1, ny0, ny1) != (x0, x1, y0, y1):
            new = r
            new = re.sub(r'(?<=\s)x="[\d.]+"', f'x="{nx0}"', new, count=1)
            new = re.sub(r'(?<=\s)y="[\d.]+"', f'y="{ny0}"', new, count=1)
            new = re.sub(r'(?<=\s)width="[\d.]+"', f'width="{nx1 - nx0}"', new, count=1)
            new = re.sub(r'(?<=\s)height="[\d.]+"', f'height="{ny1 - ny0}"', new, count=1)
            svg = svg.replace(r, new, 1)
            changed += 1

    open(path, "w").write(svg)
    print(f"{path}: adjusted {changed} block border(s)")


if __name__ == "__main__":
    for f in sys.argv[1:]:
        fix(f)
