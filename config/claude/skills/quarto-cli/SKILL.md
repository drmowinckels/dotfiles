---
name: quarto-cli
description: "Mastering the Quarto CLI for authoring, rendering, project management, computation engines, and publishing. Covers CLI commands, project types, YAML configuration hierarchy, markdown extensions (shortcodes, cross-references, citations, callouts, conditional content), code cell options, cache/freeze strategies, parameterised reports, profiles, environment variables, pre/post render scripts, Bootstrap/SCSS theming, brand.yml, and publishing workflows (Quarto Pub, GitHub Pages, Netlify, GitHub Actions). Use when working with Quarto projects, configuring rendering, setting up publishing, or authoring .qmd documents. Companion to quarto-extensions, quarto-revealjs, and quarto-typst skills."
---

# Quarto CLI

Based on Mickael Canouil's "Mastering Quarto CLI" workshop. Requires Quarto CLI 1.8+.

## Core Commands

```bash
quarto render [file|project]       # Render files or projects
quarto preview [file]              # Live preview with hot reload
quarto create project [type]       # Scaffold project (default|website|blog|book|manuscript)
quarto check [target]              # Verify installation and dependencies
quarto publish [provider] [path]   # Publish to hosting platform
quarto add user/extension[@tag]    # Install extension from GitHub
```

## Processing Pipeline

`.qmd`/`.ipynb` → computation engine (knitr/Jupyter) → `.md` → Pandoc → output format (HTML, Typst, PDF, Reveal.js, DOCX)

## Project Types

| Type | Description | Key config |
|------|-------------|------------|
| `default` | Single document + `_quarto.yml` | — |
| `website` | Multi-page with navigation | `website: navbar:` |
| `blog` | Website with posts directory and listings | `website: navbar:` + posts/ |
| `book` | Chapters, cover, bibliography | `book: chapters:` |
| `manuscript` | Academic paper with notebooks | `manuscript: article:` |

## YAML Configuration Hierarchy

Priority (lowest → highest):
1. `_quarto.yml` — project level
2. `_metadata.yml` — directory level
3. YAML header — document level

Multi-format output:
```yaml
title: "Document"
toc: true
format:
  html:
    theme: flatly
    code-fold: true
  pdf:
    documentclass: article
    geometry: margin=1in
  typst:
    fig-format: png
    fig-dpi: 150
  docx:
    reference-doc: template.docx
```

## Authoring Essentials

### Shortcodes

| Shortcode | Purpose |
|-----------|---------|
| `{{< include _file.qmd >}}` | Include another qmd (prefix with `_` to hide from render) |
| `{{< var name >}}` | Print variable from `_variables.yml` |
| `{{< meta field >}}` | Print from document metadata |
| `{{< env VAR >}}` | Print environment variable |
| `{{< pagebreak >}}` | Insert page break |
| `{{< kbd Ctrl+S >}}` | Keyboard shortcut rendering |
| `{{< video url >}}` | Embed video |

The `include` shortcode is plain copy-paste — any YAML header in the included file replaces the current document's YAML.

### Cross-References

Prefix determines type: `fig-`, `tbl-`, `sec-`, `eq-`, `lst-`, `thm-`.

```markdown
![Caption](image.png){#fig-name}
See @fig-name for details.
```

Custom cross-reference types:
```yaml
crossref:
  custom:
    - kind: float
      key: txt
      reference-prefix: Text
```

### Citations

```yaml
bibliography: references.bib
csl: nature.csl
```

| Syntax | Output |
|--------|--------|
| `[@author2023]` | (Author, 2023) |
| `[@author2023, p. 15]` | (Author, 2023, p. 15) |
| `[@a; @b]` | (A; B) |
| `@author2023 says` | Author (2023) says |
| `[-@author2023]` | (2023) — suppress author |

### Callout Blocks

Five types: `note`, `tip`, `warning`, `caution`, `important`.

```markdown
::: {.callout-tip}
## Optional Title
Content here.
:::
```

### Conditional Content

```markdown
::: {.content-visible when-format="html"}
HTML-only content
:::

::: {.content-hidden when-format="revealjs"}
Hidden in presentations
:::

[Typst-only]{.content-visible when-format="typst"}
```

Conditions: `when-format`, `unless-format`, `when-meta`, `unless-meta`, `when-profile`, `unless-profile`.

### Code Annotations

```markdown
```r
library(tidyverse)    # <1>
data |> mutate(x)     # <2>
```
1. Load packages
2. Transform data
```

### Mermaid Diagrams

````markdown
```{mermaid}
%%| label: fig-diagram
%%| fig-width: 5
flowchart LR
  A --> B --> C
```
````

## Computation Engines

Always explicitly set the engine — auto-detection does not work for inline code.

```yaml
engine: knitr     # R
engine: jupyter   # Python
jupyter: python3
engine: julia     # Julia
```

### Code Cell Options

| Option | Description |
|--------|-------------|
| `eval` | Execute the code (`false` = display only) |
| `echo` | Show source code in output |
| `output` | Show results (`true`, `false`, `asis`) |
| `warning` | Include warnings |
| `error` | Include errors (won't halt render) |
| `include` | Suppress all output (code and results) |
| `code-fold` | Collapsible code blocks (HTML only) |
| `fig-cap` | Figure caption |
| `fig-width` / `fig-height` | Figure dimensions |
| `tbl-cap` | Table caption |
| `label` | Cross-reference label |

### Cache vs Freeze

| Aspect | `cache` | `freeze` |
|--------|---------|----------|
| Purpose | Speed up development | Control project-level re-execution |
| Scope | Session-level | Project-level |
| Code changes | Invalidates cache | Re-renders in `auto` mode |

```yaml
execute:
  cache: true      # Development speed
  freeze: auto     # Re-render only when source changes
  freeze: true     # Never re-render during project render
```

```bash
quarto render --cache
quarto render --no-cache
quarto render --cache-refresh
```

Golden rules: cache for development, freeze for collaboration. Always commit `_freeze/` to version control.

### Parameters

R parameters via YAML:
```yaml
params:
  region: "North"
  start_date: "2024-01-01"
```
Access: `params[["region"]]`

Python parameters via tags:
```python
#| tags: [parameters]
alpha = 0.1
country = "UK"
```

CLI execution:
```bash
quarto render report.qmd -P region:France -P year:2023
quarto render report.qmd --execute-params params.yml
```

Batch rendering:
```bash
for region in North South East West; do
  quarto render report.qmd -P region:$region
done
```

## Profiles and Environment Variables

### Profiles

```yaml
# _quarto.yml
profile:
  group: [basic, advanced]
  default: development
```

Activation:
```bash
export QUARTO_PROFILE=production
quarto render --profile production
quarto render --profile production,advanced
```

Profile-specific config: `_quarto-{profile}.yml`
Content targeting: `when-profile="advanced"` / `unless-profile="basic"`

### Environment Variables

| File | Purpose |
|------|---------|
| `_environment` | Default variables |
| `_environment.local` | Local overrides (auto-gitignored) |
| `_environment-{profile}` | Profile-specific |
| `_environment.required` | Documentation of required vars |

## Pre/Post Render Scripts

```yaml
project:
  pre-render:
    - data-prep.py
    - generate-content.R
  post-render:
    - cleanup.sh
    - deploy.ts
```

Available env vars in scripts: `QUARTO_PROJECT_RENDER_ALL`, `QUARTO_PROJECT_OUTPUT_DIR`, `QUARTO_PROJECT_INPUT_FILES`, `QUARTO_PROJECT_OUTPUT_FILES`.

## Resource Management

```yaml
project:
  resources:
    - "data/*.csv"
    - "images/"
    - "!temp/"
```

## Bootstrap Theming and SCSS

Available themes: default, cerulean, cosmo, cyborg, darkly, flatly, journal, litera, lumen, lux, materia, minty, morph, pulse, quartz, sandstone, simplex, sketchy, slate, solar, spacelab, superhero, united, vapor, yeti, zephyr.

Light/dark pair:
```yaml
format:
  html:
    theme:
      light: cosmo
      dark: darkly
```

Theme + custom SCSS:
```yaml
format:
  html:
    theme: [cosmo, custom.scss]
```

SCSS must use layer comments:
```scss
/*-- scss:defaults --*/
$h2-font-size: 1.6rem !default;
$headings-font-weight: 500 !default;

/*-- scss:rules --*/
h1, h2, h3 {
  text-shadow: -1px -1px 0 rgba(0, 0, 0, .3);
}
```

## Brand.yml

Place `_brand.yml` in project root:

```yaml
meta:
  name: "Organisation"
  link: "https://org.com"

color:
  palette:
    primary: "#2E86AB"
    secondary: "#A23B72"
    light: "#F8F9FA"
    dark: "#343A40"
  primary: primary
  foreground: dark
  background: light

logo:
  small: "assets/logo-small.png"
  medium: "assets/logo-medium.png"

typography:
  fonts:
    - family: "Inter"
      source: "google"
      weight: [300, 400, 500, 600, 700]
  base: "Inter"
  headings: "Inter"
  monospace: "SF Mono"
```

Integration: `theme: [cosmo, brand, styles.scss]`

Brand colors become `$brand-primary` (SCSS) and `--brand-primary` (CSS) automatically.

Brand extension scaffolding: `quarto create extension brand my-brand`

## Publishing

### Platform Selection

| Service | Best For | Notes |
|---------|----------|-------|
| Quarto Pub | Learning, public content | Free, 100MB limit |
| GitHub Pages | Open source projects | Git-native, custom domains |
| Netlify | Production sites | Preview deploys |
| Posit Connect | Corporate/institutional | Access controls |

### Quarto Pub

```bash
quarto publish quarto-pub
quarto publish quarto-pub --no-prompt --no-browser --no-render
```

### GitHub Pages

**Method 1 — render to `docs/`:**
```yaml
project:
  type: website
  output-dir: docs
```

**Method 2 — `quarto publish gh-pages`:**
```bash
git checkout --orphan gh-pages
git rm -rf . && git commit --allow-empty -m "Init gh-pages" && git push origin gh-pages
git checkout main
quarto publish gh-pages
```

**Method 3 — GitHub Actions (recommended):**
```yaml
name: Quarto Publish
on:
  workflow_dispatch:
  push:
    branches: main
jobs:
  build-deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - uses: quarto-dev/quarto-actions/setup@v2
      - uses: quarto-dev/quarto-actions/publish@v2
        with:
          target: gh-pages
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Freeze-Based Publishing Strategy

```yaml
execute:
  freeze: auto
```

```bash
quarto render
git add _freeze/
git commit -m "Update frozen computations"
git push
```

CI executes only Pandoc — no computation dependencies needed.

### Version Control Rules

Commit: `.qmd`, `_freeze/`, `_quarto.yml`, `_brand.yml`, `_variables.yml`, `_environment`, `_environment.required`.
Exclude: `_site/`, `_book/`, `_manuscript/`, `/.quarto/`, `_environment.local`.

### Custom Domains

Place `CNAME` file in project root. Configure DNS: A records for apex domains, CNAME for subdomains.

## Pandoc Template Syntax

Variables: `$title$`, `$author$`

Conditionals:
```
$if(subtitle)$
Subtitle: $subtitle$
$endif$
```

Loops:
```
$for(authors)$
- $it.name$ ($it.email$)
$endfor$
```

Separators: `$for(tags)$$it$$sep$, $endfor$`
