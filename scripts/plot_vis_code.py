"""Generate figures/vis-code.svg: the Robot 36C VIS code as a frequency staircase."""

from pathlib import Path

import matplotlib.pyplot as plt

BLUE = "#3070b3"
INK = "#000000"
MUTED = "#000000"
BASELINE = "#000000"

plt.rcParams["font.family"] = "Helvetica Neue"
plt.rcParams["svg.fonttype"] = "none"

# (duration [ms], frequency [Hz], label, bit value or None)
VIS_CODE = [
    (300, 1900, "Leader (300ms)", None),
    (10, 1200, "Break (10ms)", None),
    (300, 1900, "Leader (300ms)", None),
    (30, 1200, "Start (30ms)", None),
    (30, 1100, None, "0"),
    (30, 1100, None, "0"),
    (30, 1100, None, "0"),
    (30, 1300, None, "1"),
    (30, 1100, None, "0"),
    (30, 1100, None, "0"),
    (30, 1100, None, "0"),
    (30, 1300, None, "1"),
    (30, 1200, "Stop (30ms)", None),
]

fig, ax = plt.subplots(figsize=(7, 3.2))

t = 0.0
for i, (duration, freq, label, bit) in enumerate(VIS_CODE):
    ax.hlines(freq, t, t + duration, color=BLUE, linewidth=1.8)
    if i > 0:
        ax.vlines(t, VIS_CODE[i - 1][1], freq, color=BLUE, linewidth=1.0)
        ax.axvline(t, color=BASELINE, linewidth=0.6, linestyle=(0, (2, 3)), zorder=0)
    center = t + duration / 2
    if label is not None:
        ax.text(
            center, 2560, label, ha="center", va="top",
            fontsize=9, color=MUTED, rotation=90 if duration < 100 else 0,
            bbox=dict(facecolor="white", edgecolor="none", pad=1.5),
        )
    if bit is not None:
        ax.text(center, freq + 60, bit, ha="center", va="bottom", fontsize=9, color=INK)
    t += duration

ax.set_xlim(0, t)
ax.set_ylim(1000, 2600)
ax.set_yticks([1100, 1200, 1300, 1900])
ax.spines[["top", "right"]].set_visible(False)
ax.spines[["left", "bottom"]].set_color(BASELINE)
ax.tick_params(colors=MUTED, labelsize=11)
ax.set_ylabel("Frequency [Hz]", fontsize=11, color=MUTED)
ax.set_xlabel("Time [ms]", fontsize=11, color=MUTED)

fig.tight_layout()

out = Path(__file__).parent.parent / "figures" / "vis-code.svg"
fig.savefig(out, format="svg", bbox_inches="tight")
print(f"wrote {out}")
