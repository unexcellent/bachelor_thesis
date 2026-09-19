"""Generate figures/frequency-modulation.svg: carrier, signal, and FM result."""

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

fig, axes = plt.subplots(3, 1, figsize=(7, 5), sharex=True)

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
    ax.set_ylabel("Amplitude", fontsize=14, color=MUTED)

axes[-1].set_xlabel("Time", fontsize=14, color=MUTED)
axes[-1].set_xlim(t[0], t[-1])
axes[-1].set_xticks([])

fig.tight_layout()

out = Path(__file__).parent.parent / "figures" / "frequency-modulation.svg"
out.parent.mkdir(exist_ok=True)
fig.savefig(out, format="svg", bbox_inches="tight")
print(f"wrote {out}")
