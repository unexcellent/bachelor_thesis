"""Generate figures/horizontal-synchronization.svg: line timing of Robot 36C scan lines."""

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

BLUE = "#3070b3"
INK = "#000000"
MUTED = "#000000"
BASELINE = "#000000"

plt.rcParams["font.family"] = "Helvetica Neue"
plt.rcParams["svg.fonttype"] = "none"

LINE_DURATION = 150.0
DATA_BAND = (1500, 2300)

LABEL_ROWS = {"upper": 2690, "lower": 2545}
# Just below the label text in each row, where the leader lines end
LABEL_BOTTOMS = {"upper": 2565, "lower": 2420}


# (duration [ms], frequency [Hz] or band label, top label or None, label row)
def line_segments(sep_freq, chroma_label):
    return [
        (9.0, 1200, "Sync (9ms)", "upper"),
        (3.0, 1500, "Porch (3ms)", "lower"),
        (88.0, chroma_label and "Y scan (88ms)", None, None),
        (4.5, sep_freq, "Separator (4.5ms)", "upper"),
        (1.5, 1900, "Porch (1.5ms)", "lower"),
        (44.0, chroma_label and f"{chroma_label} (44ms)", None, None),
    ]


fig, axes = plt.subplots(2, 1, figsize=(7, 5.5))

lines = [
    ("Even line", 0.0, 1500, "R−Y scan"),
    ("Odd line", LINE_DURATION, 2300, "B−Y scan"),
]

for ax, (title, start, sep_freq, chroma_label) in zip(axes, lines):
    t = start
    prev_freq = None
    for duration, value, label, row in line_segments(sep_freq, chroma_label):
        if isinstance(value, str):
            ax.add_patch(Rectangle(
                (t, DATA_BAND[0]), duration, DATA_BAND[1] - DATA_BAND[0],
                facecolor=BLUE, alpha=0.12, edgecolor="none",
            ))
            ax.text(t + duration / 2, 2080, value,
                    ha="center", va="center", fontsize=11, color=BLUE)
            prev_freq = None
        else:
            if prev_freq is not None:
                ax.vlines(t, prev_freq, value, color=BLUE, linewidth=1.0)
            ax.hlines(value, t, t + duration, color=BLUE, linewidth=1.8)
            prev_freq = value
        if label is not None:
            ax.text(t + duration / 2, LABEL_ROWS[row], label, ha="left", va="top",
                    fontsize=9, color=MUTED)
            ax.vlines(t + duration / 2, value + 40, LABEL_BOTTOMS[row],
                      color=MUTED, linewidth=0.6)
        if t > start:
            ax.vlines(t, 1050, 2350, color=BASELINE, linewidth=0.6,
                      linestyle=(0, (2, 3)), zorder=0)
        t += duration

    ax.set_title(title, loc="center", fontsize=14, color=INK)
    ax.set_xlim(start, start + LINE_DURATION)
    ax.set_xticks([start + i * 30 for i in range(6)])
    ax.set_ylim(1050, 2700)
    ax.set_yticks([1200, 1500, 1900, 2300])
    ax.spines[["top", "right"]].set_visible(False)
    ax.spines[["left", "bottom"]].set_color(BASELINE)
    ax.tick_params(colors=MUTED, labelsize=11)
    ax.set_ylabel("Frequency [Hz]", fontsize=11, color=MUTED)
    ax.set_xlabel("Time [ms]", fontsize=11, color=MUTED)

fig.tight_layout()

out = Path(__file__).parent.parent / "figures" / "horizontal-synchronization.svg"
fig.savefig(out, format="svg", bbox_inches="tight")
print(f"wrote {out}")
