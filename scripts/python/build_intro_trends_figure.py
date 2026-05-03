"""
Build Figure 1 for the Introduction: ChatGPT search interest in Latin America.

Produces a publication-ready PDF figure showing weekly Google Trends
search interest for "ChatGPT" averaged across six LAC countries
(Costa Rica, Colombia, Ecuador, Mexico, Peru, Uruguay) with a shaded
±1 standard deviation band across countries. Vertical line at the
ChatGPT public launch (30 November 2022).

Design rationale:
- Sober, monochromatic palette suitable for JLE/JHR/AEJ:Applied
- Serif font matching LaTeX body
- Single accent line (average) on faint individual-country traces
- Single event marker (ChatGPT launch) — the figure is intro motivation
- Vector PDF output for clean LaTeX integration
- No title (the LaTeX caption is the title)

Inputs:
    data/raw/trends/trends_chatgpt_imputed.csv  (semicolon-separated,
        weekly observations 2022-09-25 to 2026-04-26, columns: date, MX,
        CR, CO, EC, UY, PE)

Outputs:
    paper/figures/descriptive/fig1_chatgpt_intro.pdf
"""

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parents[2]
INPUT_CSV = Path("/Users/etorresram/Desktop/Thesis files/trends_chatgpt_imputed.csv")
OUTPUT_PDF = PROJECT_ROOT / "paper" / "figures" / "descriptive" / "fig1_chatgpt_intro.pdf"

OUTPUT_PDF.parent.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# Publication-quality matplotlib defaults (sober, journal-ready)
# ---------------------------------------------------------------------------
plt.rcParams.update({
    "font.family": "serif",
    "font.serif": ["Times New Roman", "Times", "DejaVu Serif"],
    "font.size": 10,
    "axes.labelsize": 11,
    "axes.titlesize": 11,
    "axes.linewidth": 0.6,
    "axes.edgecolor": "black",
    "axes.spines.top": False,
    "axes.spines.right": False,
    "xtick.labelsize": 9,
    "ytick.labelsize": 9,
    "xtick.direction": "out",
    "ytick.direction": "out",
    "xtick.major.size": 3,
    "ytick.major.size": 3,
    "xtick.major.width": 0.6,
    "ytick.major.width": 0.6,
    "legend.fontsize": 9,
    "legend.frameon": False,
    "figure.dpi": 300,
    "savefig.dpi": 300,
    "savefig.bbox": "tight",
    "savefig.pad_inches": 0.05,
    "pdf.fonttype": 42,
    "ps.fonttype": 42,
})


# ---------------------------------------------------------------------------
# Load and prepare data
# ---------------------------------------------------------------------------
def load_trends(path: Path) -> pd.DataFrame:
    """Load semicolon-separated Google Trends CSV and return wide DataFrame."""
    df = pd.read_csv(path, sep=";", encoding="utf-8-sig")
    df.columns = df.columns.str.strip()
    df["date"] = pd.to_datetime(df["date"], format="%d/%m/%y", dayfirst=True)
    df = df.set_index("date")

    rename_map = {
        "MX": "Mexico",
        "CR": "Costa Rica",
        "CO": "Colombia",
        "EC": "Ecuador",
        "UY": "Uruguay",
        "PE": "Peru",
    }
    df = df.rename(columns=rename_map)

    for col in df.columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    return df


df = load_trends(INPUT_CSV)
country_cols = [c for c in df.columns if c != "promedio"]
mean_series = df[country_cols].mean(axis=1)
std_series = df[country_cols].std(axis=1)


# ---------------------------------------------------------------------------
# Build figure
# ---------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(7.0, 3.6))

# Faint individual-country lines (context, not focus)
for col in country_cols:
    ax.plot(
        df.index,
        df[col],
        color="0.65",
        linewidth=0.5,
        alpha=0.5,
        zorder=1,
    )

# ±1 SD band across countries (visual envelope of dispersion)
ax.fill_between(
    df.index,
    mean_series - std_series,
    mean_series + std_series,
    color="0.85",
    alpha=0.6,
    linewidth=0,
    zorder=2,
    label=r"$\pm$1 SD across countries",
)

# Average line (the headline)
ax.plot(
    df.index,
    mean_series,
    color="black",
    linewidth=1.4,
    zorder=4,
    label="Six-country average",
)

# ChatGPT launch event
launch_date = pd.to_datetime("2022-11-30")
ax.axvline(
    x=launch_date,
    color="black",
    linestyle=(0, (4, 3)),
    linewidth=0.8,
    alpha=0.85,
    zorder=3,
)
y_top = 100
ax.annotate(
    "ChatGPT launch\n(30 Nov 2022)",
    xy=(launch_date, y_top * 0.92),
    xytext=(8, 0),
    textcoords="offset points",
    fontsize=8.5,
    color="black",
    ha="left",
    va="top",
)

# Axis cosmetics
ax.set_xlabel("")
ax.set_ylabel("Search interest (0--100)")
ax.set_ylim(0, 100)
ax.margins(x=0.01)

# Yearly major ticks
years = pd.date_range(start="2023-01-01", end=df.index.max(), freq="YS")
ax.set_xticks(years)
ax.set_xticklabels([d.strftime("%Y") for d in years])

# Light horizontal grid lines (sparse)
ax.yaxis.set_major_locator(plt.MultipleLocator(25))
ax.grid(axis="y", linestyle=":", linewidth=0.4, color="0.7", alpha=0.7)
ax.set_axisbelow(True)

# Legend (top-left, since data is rising)
ax.legend(loc="upper left", bbox_to_anchor=(0.01, 0.85))

# Save
fig.savefig(OUTPUT_PDF)
print(f"Saved: {OUTPUT_PDF}")
print(f"   Mean post-launch (2023-): {mean_series['2023':].mean():.1f}")
print(f"   Mean pre-launch (-2022-11): {mean_series[:'2022-11-29'].mean():.1f}")
print(f"   Peak: {mean_series.max():.1f} on {mean_series.idxmax().date()}")
