"""Generate figures/vox-tones.svg: the VOX tone sequence as a frequency staircase."""

from pathlib import Path

import matplotlib.pyplot as plt

BLUE = "#3070b3"
MUTED = "#000000"
BASELINE = "#000000"

plt.rcParams["font.family"] = "Helvetica Neue"
plt.rcParams["svg.fonttype"] = "none"

# (duration [ms], frequency [Hz])
VOX_TONES = [(100, f) for f in (1900, 1500, 1900, 1500, 2300, 1500, 2300, 1500)]

fig, ax = plt.subplots(figsize=(7, 2.8))

t = 0.0
for i, (duration, freq) in enumerate(VOX_TONES):
    ax.hlines(freq, t, t + duration, color=BLUE, linewidth=1.8)
    if i > 0:
        ax.vlines(t, VOX_TONES[i - 1][1], freq, color=BLUE, linewidth=1.0)
        ax.axvline(t, color=BASELINE, linewidth=0.6, linestyle=(0, (2, 3)), zorder=0)
    t += duration

ax.set_xlim(0, t)
ax.set_ylim(1300, 2500)
ax.set_yticks([1500, 1900, 2300])
ax.spines[["top", "right"]].set_visible(False)
ax.spines[["left", "bottom"]].set_color(BASELINE)
ax.tick_params(colors=MUTED, labelsize=11)
ax.set_ylabel("Frequency [Hz]", fontsize=11, color=MUTED)
ax.set_xlabel("Time [ms]", fontsize=11, color=MUTED)

fig.tight_layout()

out = Path(__file__).parent.parent / "figures" / "vox-tones.svg"
fig.savefig(out, format="svg", bbox_inches="tight")
print(f"wrote {out}")
