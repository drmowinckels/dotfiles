---
name: quarto-extensions
description: "Build Quarto format extensions that contribute custom document, presentation, and PDF formats. Covers _extension.yml configuration, brand.yml integration, _schema.yml validation, Lua filters (config hierarchy, format-aware rendering, module loading), multi-format extensions, file structure, scaffolding, distribution, and repository conventions. Use when creating, modifying, or debugging Quarto extensions that provide custom output formats."
---

# Quarto Format Extensions

Core patterns for building Quarto format extensions. Canonical example: `/Users/athanasm/workspace/rladies/quarto-rladiesplus`.

## File Structure

```
myextension/
├── _extensions/
│   └── myformat/
│       ├── _extension.yml        # Extension manifest
│       ├── brand.yml             # Design tokens (colors, fonts, logos)
│       ├── _schema.yml           # Custom YAML option validation
│       ├── html-theme.scss       # HTML light theme
│       ├── html-theme-dark.scss  # HTML dark theme
│       ├── dashboard-theme.scss  # Dashboard light theme
│       ├── dashboard-theme-dark.scss
│       ├── revealjs-theme.scss   # RevealJS theme
│       ├── typst-template.typ    # Typst template function
│       ├── typst-show.typ        # Typst metadata bridge
│       ├── filter.lua            # Lua filter
│       ├── _modules/             # Shared Lua utilities
│       └── logos/                # Logo assets (multiple variants)
├── _quarto.yml                   # Project config (output-dir, brand)
├── template.qmd                  # Starter for `quarto use template`
├── example.qmd                   # Working example
├── .quartoignore
└── README.md
```

Scaffold: `quarto create extension format:html` / `format:revealjs` / `format:typst`

## _extension.yml

```yaml
title: My Format
author: Author Name
version: 1.0.0
quarto-required: ">=1.6.0"
contributes:
  metadata:
    project:
      brand: brand.yml
  formats:
    html:
      theme:
        light: [cosmo, brand, html-theme.scss]
        dark: [cosmo, brand, html-theme-dark.scss]
      filters:
        - filter.lua
    dashboard:
      theme:
        light: [cosmo, brand, dashboard-theme.scss]
        dark: [cosmo, brand, dashboard-theme-dark.scss]
      logo: logos/logo-white.svg
      filters:
        - filter.lua
    revealjs:
      logo: logos/logo.svg
      theme: [default, brand, revealjs-theme.scss]
      filters:
        - filter.lua
    typst:
      brand: brand.yml
      template-partials:
        - typst-template.typ
        - typst-show.typ
      margin:
        x: 2.5cm
        y: 2.5cm
```

Key patterns:

- **Theme stacking** (HTML/RevealJS/Dashboard): Base theme, then `brand` (injects brand.yml as SCSS `!default` variables), then custom SCSS. `!default` variables set by brand cannot be overridden with `!default` in your SCSS — the brand value wins. To override brand, omit `!default` or change brand.yml itself.
- **Light/dark pairs**: Each format gets separate SCSS files for light and dark. Dark files redefine the palette with lighter tints for contrast on dark backgrounds.
- **Dashboard logo**: Use white/light variant since navbar is always colored.
- **Template partials** (Typst): Use `template-partials` not `template` to preserve Quarto's built-in bibliography and footnote handling.
- **Multi-format**: A single extension contributes HTML, dashboard, RevealJS, and Typst simultaneously.
- **Shared filters**: Declare in `common:` or per-format.
- **`resources` / `format-resources`**: Declare additional files to ship with the extension.

## brand.yml

Single source of truth for design tokens. Named palette colors referenced by semantic roles.

```yaml
meta:
  name: My Brand

logo:
  images:
    horizontal:
      path: logos/logo-horizontal.svg
      alt: "Logo"
    horizontal-white:
      path: logos/logo-horizontal-white.svg
      alt: "Logo for dark backgrounds"
    vertical:
      path: logos/logo-vertical.svg
      alt: "Stacked logo"
    favicon:
      path: logos/favicon.svg
      alt: "Icon"
  small:
    light: favicon
    dark: favicon
  medium:
    light: horizontal
    dark: horizontal-white

color:
  palette:
    primary-color: "#6b21a8"
    primary-light: "#a855f7"    # Lighter tint for dark mode
    primary-lighter: "#c4b5fd"  # Even lighter for dark mode links
    secondary-color: "#0f55cc"
    accent-color: "#e11d48"
    accent-light: "#f6a4c3"     # Dark mode accent
    dark-color: "#1e1e2e"
    light-color: "#e5e5f0"
    surface-color: "#f8f8fc"
    muted-color: "#6b7280"
  foreground: dark-color
  background: surface-color
  primary: primary-color
  secondary: secondary-color
  tertiary: accent-color
  light: light-color
  dark: dark-color
  link: primary-color

typography:
  fonts:
    - family: Inter
      source: google
      weight: [300, 400, 500, 600, 700]
    - family: JetBrains Mono
      source: google
  base:
    family: Inter
    size: 1em
    weight: 400
    line-height: 1.6
  headings:
    family: Inter
    weight: 600
    color: dark-color
  monospace:
    family: JetBrains Mono
    size: 0.9em
  link:
    decoration: underline
    color: primary-color
```

Palette names become SCSS variables as `$brand-COLOR_NAME`. In Typst: `brand-color.at("primary", default: ...)`.

**Accessibility**: Always verify contrast ratios in brand.yml. Fix accessibility at the source (brand.yml), not in SCSS overrides — fighting the theme stacking order is fragile.

## Dark Mode SCSS Strategy

Dark themes cannot use `$primary`/`$secondary` from brand — those are set for light mode contrast. Define explicit dark palette variables:

```scss
/*-- scss:defaults --*/
$my-primary: #a855f7 !default;    // Lighter tint for dark backgrounds
$my-secondary: #81acf7 !default;
$my-accent: #f6a4c3 !default;
$my-bg: #121220 !default;
$my-fg: #e5e5f0 !default;
$my-surface: #1a1a2e !default;

$body-bg: $my-bg !default;
$body-color: $my-fg !default;
$link-color: $my-primary !default;
$card-bg: $my-surface !default;
```

**Blockquote specificity gotcha**: Bootstrap/Cosmo sets `.blockquote` class colors at high specificity. Override with:

```scss
blockquote, blockquote.blockquote {
  color: $my-fg;
  p, em, strong, span { color: $my-fg; }
}
```

## _schema.yml

Define custom YAML options with validation. ID must match `<extensionname>-<format>`:

```yaml
- id: myformat-typst
  schema:
    letterhead:
      type: boolean
      default: false
      description: Enable letterhead mode.
    title-style:
      type: string
      default: default
      enum: [default, elaborate]

- id: myformat-revealjs
  schema:
    title-slide-attributes:
      type: object
      properties:
        class:
          type: string
          enum: [elaborate-title]
        data-background-color:
          type: string
          enum: ["#6b21a8", "#1e1e2e"]
```

## Lua Filters

### Format-Aware Rendering

```lua
if quarto.doc.is_format("html:js") then
  return pandoc.RawInline('html', html_output)
elseif quarto.doc.is_format("typst") then
  return pandoc.RawInline('typst', typst_output)
end
```

### Config Hierarchy

```lua
local function get_options(args, meta, defaults)
  local opts = {}
  for k, v in pairs(defaults) do opts[k] = v end
  if meta.extensions and meta.extensions["my-ext"] then
    for k, v in pairs(meta.extensions["my-ext"]) do opts[k] = v end
  end
  for k, v in pairs(args) do opts[k] = v end
  return opts
end
```

### Shared Modules

```lua
local utils = require(
  quarto.utils.resolve_path("_modules/utils.lua"):gsub("%.lua$", "")
)
```

## Distribution

```bash
quarto use template org/repo       # Full template + starter .qmd
quarto add org/repo                # Extension only
quarto add org/repo@1.2.0          # Pinned version
```

Usage: `format: myformat-revealjs: default`

## Companion Skills

- **quarto-revealjs** — SCSS theming, slide classes, background handling, inverted-slide mixin
- **quarto-typst** — Template functions, Pandoc bridge, page setup, multi-mode documents
