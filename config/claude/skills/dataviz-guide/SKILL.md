---
name: dataviz-guide
description: Choose the right data visualisation for any data story. Use when creating charts, plots, graphs, or dashboards — especially when deciding which chart type to use, making visualisations accessible to non-technical audiences, or translating statistical results into intuitive graphics. Covers chart selection by role (comparison, distribution, composition, relationship, trend), audience adaptation (technical vs layperson), and common pitfalls. Works with any plotting framework (ggplot2, matplotlib, d3, Plotly, etc.). Trigger when the user asks to "visualise", "plot", "chart", "graph", or "make a figure" for data, or when choosing between chart types.
---

# Data Visualisation Guide

## Chart Selection

Ask two questions before choosing a chart:
1. **What role** does the visualisation serve?
2. **What data types** are involved (categorical, numeric, or both)?

### Quick Reference

| Data story | Data types | First choice | Alternative |
|---|---|---|---|
| Compare groups | 1 categorical + 1 numeric | Bar chart | Lollipop, dot plot |
| Compare groups | 2 categorical + 1 numeric | Grouped bar | Heatmap |
| Compare distributions | 1 categorical + 1 numeric | Box plot | Violin, ridgeline |
| Show trend | Time + 1 numeric | Line chart | Bar chart (few periods) |
| Show trend | Time + multiple groups | Multi-line (max 5) | Sparklines (many groups) |
| Part of whole | 1 categorical | Stacked bar | Pie (max 5 slices), waffle |
| Part of whole over time | Time + 1 categorical | Stacked area | Stream graph |
| Relationship | 2 numeric | Scatter plot | Bubble chart (3rd var) |
| Relationship | 2 categorical | Heatmap | Grouped bar |
| Single number | 1 value | Show the number | Bullet chart (vs benchmark) |
| Proportion shock | 1 percentage | Waffle chart | Stacked bar |

For detailed chart descriptions by role, see [references/chart-types.md](references/chart-types.md).

## Audience Adaptation

### For technical audiences
Use standard statistical visualisations: forest plots, funnel plots, ROB traffic lights, GRADE heatmaps. Include CIs, heterogeneity stats, p-values. Precise axis labels.

### For layperson audiences

**Replace jargon with plain language:**
- "SMD = -0.58" -> "moderate benefit"
- "I-squared = 78%" -> "studies disagree considerably"
- "p < 0.001" -> "unlikely to be due to chance"

**Translate effect sizes to words:**
- |d| < 0.2: "negligible"
- |d| 0.2-0.5: "small benefit" or "small harm" (direction matters)
- |d| 0.5-0.8: "moderate benefit" or "moderate harm"
- |d| > 0.8: "large benefit" or "large harm"

**Add treatment verdict labels (traffic-light colours):**
- CI entirely favours treatment: "Likely helpful" (green)
- Estimate favours treatment, CI crosses zero, |effect| >= 0.3: "Possibly helpful" (light green)
- Estimate favours control, |effect| >= 0.2: "Possibly harmful" (orange)
- CI entirely favours control, |effect| >= 0.3: "Unlikely to help" (red)
- Near zero, CI crosses zero: "Uncertain" (grey)

**Replace technical charts with intuitive equivalents:**
- Forest plot -> lollipop chart with "Favours treatment" / "Favours control" background shading + verdict labels
- Funnel plot -> omit (no lay equivalent)
- GRADE heatmap -> stacked bar showing proportion at each certainty level
- ROB traffic light -> keep (traffic light metaphor is already accessible)

**Use waffle charts for shocking proportions:**
When a percentage is very small or large and the number itself tells a story (e.g. "only 2% of studies measured PEM"), a 10x10 waffle grid where each square = 1% makes the gap visceral.

**Structure for dual audiences:**
Put "At a Glance" section first, before technical details. Readers who want statistics scroll down; those who want the answer get it immediately.

## Charts to Avoid

- **Radar/spider plot** — area perception depends on spoke order. Use parallel coordinates or grouped bar.
- **Circular/radial bar chart** — distorts values. Use standard bar chart.
- **3D charts** — always. Perspective distortion makes values unreadable.
- **Dual y-axis** — misleading; relationship depends on axis scaling. Use two separate charts.
- **Pictogram** — loses precision unless the icon metaphor adds genuine meaning.

## Design Principles

- **Colourblind-safe palettes**: Okabe-Ito, viridis, or ColorBrewer. Never encode meaning in red vs green alone.
- **Horizontal bars**: When group labels are long. Easier to read than angled text.
- **Small multiples / faceting**: One panel per group, better than cramming many groups into one chart.
- **Direct labelling**: Label data directly rather than relying on legends.
- **Sort by value**: Order bars/dots by value, not alphabetically, unless alpha has meaning.
- **Minimal ink**: Remove gridlines, borders, backgrounds that carry no information.
