# Chart Types by Role

## Comparing values between groups
- **Bar chart** — default for categorical comparisons. Horizontal when labels are long.
- **Grouped bar chart** — two categorical variables. Clusters for one, colour for the other.
- **Lollipop chart** — bar chart with lines + dots. Cleaner with many groups.
- **Dot plot** — bars replaced with dots. Good when zero baseline is not meaningful.
- **Box plot** — compare distribution summaries across groups.
- **Violin plot** — density + box plot. Shows distribution shape.
- **Ridgeline** — overlapping density curves for many groups with distinct patterns.
- **Slope chart** — two time points, one line per data point. Quick indicator of direction.
- **Dumbbell plot** — compare two values per group (e.g. pre/post). Segments emphasise gap.
- **Bump chart** — rank over time rather than value. Supports many categories.

## Showing change over time
- **Line chart** — default. One line per group, max 5.
- **Bar chart** — few time periods only.
- **Sparkline** — miniature, inline. Good for many groups or embedding in tables.
- **Box plot** — distribution per time period when multiple recordings exist.
- **Connected scatter plot** — change over time across two numeric variables.

## Showing part-to-whole composition
- **Stacked bar chart** — default. Length judgement is more precise than angle.
- **Pie chart** — max 5 slices with distinct proportions.
- **Doughnut chart** — pie with central number. Also works as progress indicator.
- **Waffle chart** — 10x10 grid, each square = 1%. Visceral for extreme proportions.
- **Stacked area chart** — part-to-whole over time.
- **Treemap** — hierarchical part-to-whole with nested rectangles.

## Looking at distributions
- **Bar chart** — discrete/categorical variables.
- **Histogram** — continuous numeric. Bars flush together.
- **Density curve** — smoother alternative to histogram.
- **Box plot** — statistical summary (quartiles, whiskers).
- **Violin plot** — density curve + box plot combined.
- **Strip/swarm plot** — individual data points along a line. Best with few/moderate points.

## Observing relationships between variables
- **Scatter plot** — default for two numeric variables.
- **Bubble chart** — scatter + point size as third variable. Max 3 variables total.
- **Heatmap** — two categorical or binned numeric variables. Colour = value.
- **Grouped bar chart** — relationship between two categorical variables.
- **2-d density curve** — smoothed heatmap for two numeric variables.

## Depicting flows and processes
- **Funnel chart** — stages of a process with progressive filtering.
- **Sankey diagram** — width shows volume flowing through a multi-stage process.
- **Gantt chart** — project timeline with task bars.

## Geographical data
- **Choropleth** — regions coloured by value. Use rates to avoid population distortion.
- **Bubble map** — scatter on a map, point size = value.
- **Connection map** — network flows on a geographic map.
