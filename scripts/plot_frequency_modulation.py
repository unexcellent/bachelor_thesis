"""Generate figures/frequency-modulation.svg: carrier, signal, and FM result."""

import re
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

# Colors from lib/template.typ (TUM blue and the template grays)
CARRIER_COLOR = "#3070b3"
SIGNAL_COLOR = "#3070b3"
INK = "#000000"
MUTED = "#000000"
BASELINE = "#000000"

CARRIER_FREQ = 8.0
SIGNAL_FREQ = 1.0
# Exaggerated frequency deviation so the compression/stretching is obvious
FREQ_DEVIATION = 5.0

plt.rcParams["font.family"] = "Helvetica Neue"
plt.rcParams["svg.fonttype"] = "none"

t = np.linspace(0.0, 1.0 / SIGNAL_FREQ, 4000)

carrier = np.sin(2 * np.pi * CARRIER_FREQ * t)
signal = np.sin(2 * np.pi * SIGNAL_FREQ * t)
# Instantaneous frequency f_c + Δf·signal(t), integrated to obtain the phase
phase = (
    2
    * np.pi
    * (
        CARRIER_FREQ * t
        - FREQ_DEVIATION
        / (2 * np.pi * SIGNAL_FREQ)
        * (np.cos(2 * np.pi * SIGNAL_FREQ * t) - 1)
    )
)
modulated = np.sin(phase)

# Drawn at 80% of the usual 7 in width and then padded back to 7 in, so the
# figure can be included at 100% width with the same font scale as the others.
FULL_WIDTH_PT = 7 * 72
CONTENT_RATIO = 0.8

fig, axes = plt.subplots(3, 1, figsize=(7 * CONTENT_RATIO, 4), sharex=True)

plots = [
    ("Carrier", carrier, CARRIER_COLOR),
    ("Signal", signal, SIGNAL_COLOR),
    ("Modulated carrier", modulated, CARRIER_COLOR),
]

for ax, (title, y, color) in zip(axes, plots):
    ax.plot(t, y, color=color, linewidth=1.6)
    ax.set_title(title, loc="center", fontsize=14, color=INK)
    ax.set_ylim(-1.35, 1.35)
    ax.set_yticks([])
    ax.axhline(0, color=BASELINE, linewidth=0.8, zorder=0)
    ax.spines[["top", "right"]].set_visible(False)
    ax.spines[["left", "bottom"]].set_color(BASELINE)
    ax.tick_params(colors=MUTED, labelsize=11)
    ax.set_ylabel("Amplitude", fontsize=11, color=MUTED)

axes[-1].set_xlabel("Time", fontsize=11, color=MUTED)
axes[-1].set_xlim(t[0], t[-1])
axes[-1].set_xticks([])

fig.tight_layout()

out = Path(__file__).parent.parent / "figures" / "frequency-modulation.svg"
out.parent.mkdir(exist_ok=True)
fig.savefig(out, format="svg", bbox_inches="tight")

svg = out.read_text()
width = float(re.search(r'<svg[^>]* width="([\d.]+)pt"', svg).group(1))
height = float(re.search(r'<svg[^>]* height="([\d.]+)pt"', svg).group(1))
offset = (FULL_WIDTH_PT - width) / 2
svg = re.sub(r'(<svg[^>]* )width="[\d.]+pt"', rf'\g<1>width="{FULL_WIDTH_PT}pt"', svg, count=1)
svg = re.sub(
    r'viewBox="[^"]*"',
    f'viewBox="{-offset:.6f} 0 {FULL_WIDTH_PT} {height}"',
    svg,
    count=1,
)
out.write_text(svg)
print(f"wrote {out}")
