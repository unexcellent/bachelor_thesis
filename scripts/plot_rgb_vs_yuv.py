"""Generate figures/rgb-vs-yuv.svg: color-bar test pattern encoded as RGB vs YUV frequencies."""

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

INK = "#000000"
MUTED = "#000000"
BASELINE = "#000000"

plt.rcParams["font.family"] = "Helvetica Neue"
plt.rcParams["svg.fonttype"] = "none"

# Standard color-bar test pattern, (name, R, G, B) with components 0..255
BARS = [
    ("white", 255, 255, 255),
    ("yellow", 255, 255, 0),
    ("cyan", 0, 255, 255),
    ("green", 0, 255, 0),
    ("magenta", 255, 0, 255),
    ("red", 255, 0, 0),
    ("blue", 0, 0, 255),
    ("black", 0, 0, 0),
]

F_MIN, F_MAX = 1500.0, 2300.0


def to_freq(value):
    """Frequency = 1500 + v * 3.1372549 per the Dayton paper; Y/R-Y/B-Y keep their
    studio-swing offsets (16/128), so their extremes never reach the 1500/2300 rails."""
    return F_MIN + (F_MAX - F_MIN) * value / 255.0


def luminance(r, g, b):
    return 0.257 * r + 0.504 * g + 0.098 * b + 16


def chroma_blue(r, g, b):
    return -0.148 * r - 0.291 * g + 0.439 * b + 128


def chroma_red(r, g, b):
    return 0.439 * r - 0.368 * g - 0.071 * b + 128


def style(ax):
    ax.set_xlim(0, len(BARS))
    ax.set_ylim(F_MIN, 2450)
    ax.set_xticks([])
    ax.set_yticks([F_MIN, 1900, F_MAX])
    ax.set_yticklabels(["1.5", "1.9", "2.3"])
    ax.spines[["top", "right"]].set_visible(False)
    ax.spines[["left", "bottom"]].set_color(BASELINE)
    ax.tick_params(colors=MUTED, labelsize=11)
    for x in range(1, len(BARS)):
        ax.axvline(x, color=BASELINE, linewidth=0.6, linestyle=(0, (2, 3)), zorder=3)


def draw_bars(ax, freqs, colors, label, baseline=F_MIN):
    x = [i + 0.5 for i in range(len(BARS))]
    heights = [f - baseline for f in freqs]
    ax.bar(x, heights, width=1.0, bottom=baseline, color=colors,
           edgecolor=BASELINE, linewidth=0.6)
    if baseline != F_MIN:
        ax.axhline(baseline, color=MUTED, linewidth=0.8)
    ax.text(0.98, 0.94, label, transform=ax.transAxes,
            ha="right", va="top", fontsize=13, color=INK)


fig, axes = plt.subplots(
    4, 2, figsize=(7, 5.5),
    gridspec_kw={"height_ratios": [0.3, 1, 1, 1], "hspace": 0.35, "wspace": 0.25},
)

# Color-bar strips on top of both columns
for ax in axes[0]:
    ax.set_xlim(0, len(BARS))
    ax.set_ylim(0, 1)
    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)
    for i, (_, r, g, b) in enumerate(BARS):
        ax.add_patch(Rectangle(
            (i, 0), 1, 1, facecolor=(r / 255, g / 255, b / 255),
            edgecolor=BASELINE, linewidth=0.6,
        ))

# Left column: R, G, B channels
channels = [("R", "#ff0000", 1), ("G", "#00cc00", 2), ("B", "#0000ff", 3)]
for label, color, idx in channels:
    ax = axes[{"R": 1, "G": 2, "B": 3}[label]][0]
    freqs = [to_freq(bar[idx]) for bar in BARS]
    style(ax)
    draw_bars(ax, freqs, color, label)

# Right column: Y (bars shaded with their own gray value), R-Y and B-Y around 1.9 kHz
ax = axes[1][1]
y_values = [luminance(r, g, b) for _, r, g, b in BARS]
style(ax)
gray_levels = [min(max((v - 16) / 219, 0.0), 1.0) for v in y_values]
draw_bars(ax, [to_freq(v) for v in y_values], [(g,) * 3 for g in gray_levels], "Y")

ax = axes[2][1]
style(ax)
draw_bars(ax, [to_freq(chroma_red(r, g, b)) for _, r, g, b in BARS], "#ff0000", "R−Y", baseline=to_freq(128))

ax = axes[3][1]
style(ax)
draw_bars(ax, [to_freq(chroma_blue(r, g, b)) for _, r, g, b in BARS], "#0000ff", "B−Y", baseline=to_freq(128))

for col in (0, 1):
    axes[2][col].set_ylabel("Frequency [kHz]", fontsize=11, color=MUTED)

out = Path(__file__).parent.parent / "figures" / "rgb-vs-yuv.svg"
fig.savefig(out, format="svg", bbox_inches="tight")
print(f"wrote {out}")
