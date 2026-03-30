---
name: quarto-revealjs
description: "RevealJS presentation theming for Quarto format extensions. Covers SCSS section decorators, key Sass variables, semantic slide classes, background color handling, logo positioning, theme stacking, title slide customization, inverted-slide mixins, footer/slide-number styling, multi-column layouts, and plugin extensions. Use when building or modifying RevealJS themes within Quarto extensions. Companion to quarto-extensions skill."
---

# Quarto RevealJS Theming

RevealJS-specific patterns for Quarto format extensions. Use alongside the `quarto-extensions` skill for general extension structure.

## SCSS Theme File

RevealJS themes are SCSS files with required section decorators.

### scss:defaults — Sass Variables

```scss
/*-- scss:defaults --*/

$my-primary: #6b21a8 !default;
$my-secondary: #0f55cc !default;
$my-accent: #e11d48 !default;
$my-dark: #1e1e2e !default;
$my-light: #e5e5f0 !default;
$my-surface: #f8f8fc !default;

$body-bg: $my-light !default;
$body-color: $my-dark !default;

$presentation-font-size-root: 36px !default;
$presentation-heading-font-weight: 600 !default;
$presentation-heading-letter-spacing: -0.02em !default;
$presentation-h1-font-size: 1.8em !default;
$presentation-h2-font-size: 1.4em !default;
$presentation-h3-font-size: 1.1em !default;
$link-decoration: none !default;

$callout-color-note: $my-primary !default;
$callout-color-tip: $my-secondary !default;
$callout-color-warning: $my-accent !default;
$callout-color-important: $my-accent !default;
$callout-color-caution: $my-accent !default;
```

Use `!default` on all definitions so users can override from YAML. Prefix custom variables with a namespace (e.g. `$my-*`, `$org-*`).

Key variable groups:

| Category | Variables |
|----------|-----------|
| Colors | `$body-bg`, `$body-color`, `$link-color`, `$selection-bg` |
| Fonts | `$font-family-sans-serif`, `$presentation-font-size-root` |
| Headings | `$presentation-heading-color`, `$presentation-h1-font-size` through `h4` |
| Code | `$code-block-bg`, `$code-color`, `$code-bg` |
| Callouts | `$callout-color-note`, `$callout-color-tip`, `$callout-color-warning` |

Additional valid decorators: `/*-- scss:functions --*/`, `/*-- scss:mixins --*/`.

### scss:mixins — Reusable Patterns

#### Inverted Slide Mixin

DRY approach for background color handling. Define once, apply per-color:

```scss
/*-- scss:mixins --*/

@mixin inverted-slide($text, $link, $code-bg, $blockquote-border,
                      $blockquote-bg, $title-bar-bg, $title-bar-color,
                      $column-h3) {
  color: $text;
  h1, h2, h3, h4 { color: $text; }
  p, li, span { color: $text; }

  a {
    color: $link;
    border-bottom-color: rgba($link, 0.5);
    &:hover { border-bottom-color: $link; }
  }

  code:not(pre code) {
    background: rgba($text, 0.15);
    color: $text;
  }

  blockquote {
    border-left-color: $blockquote-border;
    background: $blockquote-bg;
    color: $text;
  }

  &.title-bar > h2 {
    background: $title-bar-bg;
    color: $title-bar-color;
  }

  &.statement h2, &.statement p { color: $text; }
  .callout { color: $my-dark; }
  .columns h3 { color: $column-h3; }

  .footer {
    color: rgba($text, 0.6);
    border-top-color: rgba($text, 0.15);
  }
}
```

Apply per background color:

```scss
/*-- scss:rules --*/

.reveal section[data-background-color="PRIMARY_HEX"] {
  @include inverted-slide(
    $text: $my-light,
    $link: $my-light,
    $code-bg: rgba($my-light, 0.15),
    $blockquote-border: $my-light,
    $blockquote-bg: rgba($my-light, 0.08),
    $title-bar-bg: $my-light,
    $title-bar-color: $my-primary,
    $column-h3: $my-light
  );
}

.reveal section[data-background-color="DARK_HEX"] {
  @include inverted-slide(
    $text: $my-light,
    $link: lighten($my-primary, 30%),
    $code-bg: rgba($my-light, 0.15),
    $blockquote-border: lighten($my-primary, 20%),
    $blockquote-bg: rgba($my-primary, 0.15),
    $title-bar-bg: $my-primary,
    $title-bar-color: $my-light,
    $column-h3: lighten($my-secondary, 30%)
  );
}
```

#### Elaborate Title Background Mixin

Multi-layer gradient background for decorative title slides:

```scss
@mixin elaborate-title-bg($cutout, $stripe, $stripe-dot, $corner, $header) {
  background:
    radial-gradient(circle 40px at 0 28%,
      $cutout 99%, transparent 100%),
    radial-gradient(circle 2px at 2px calc(28% + 2px),
      $stripe-dot 99%, transparent 100%),
    linear-gradient($stripe, $stripe)
      no-repeat 2px 28% / calc(100% - 2px) 4px,
    radial-gradient(circle 70px at 0 100%,
      $corner 99%, transparent 100%),
    linear-gradient($header, $header)
      no-repeat 0 0 / 100% 28%
    !important;
}
```

Provide color-inverted variants for each supported background color.

## Theme Stacking

In `_extension.yml`:

```yaml
revealjs:
  theme: [default, brand, my-theme.scss]
```

Order: `default` provides base, `brand` sets variables at lowest precedence, your SCSS provides final overrides.

## Title Slide

Target `#title-slide`:

```scss
#title-slide {
  text-align: left;

  h1.title {
    color: $my-primary;
    font-weight: 500;
    font-size: 2.2em;
    line-height: 1.2;
  }

  .subtitle { color: $my-dark; font-size: 1em; }
  .author, .date, .institute { color: $my-dark; font-size: 0.65em; }
}
```

### Elaborate Title Variant

Users apply via YAML:

```yaml
title-slide-attributes:
  class: elaborate-title
  data-background-color: "#6b21a8"
```

Use `::before`/`::after` pseudo-elements for accent blocks. Use `> *` with `z-index: 1` to keep content above background layers. Apply `@include elaborate-title-bg(...)` with inverted colors for each supported background.

## Semantic Slide Classes

### Title Bar — Branded heading band

```scss
.reveal section.title-bar > h2 {
  background: $my-primary;
  color: $my-light;
  font-weight: 600;
  font-size: 1.15em;
  padding: 0.35em 0.8em;
  margin: -0.2em -2.5% 0.6em;
  border-radius: 0 0 0.6rem 0;
  text-align: left;
}
```

Usage: `## Slide Title {.title-bar}`

### Statement — Large impact text

```scss
.reveal section.statement {
  display: flex !important;
  flex-direction: column;
  justify-content: center;
  align-items: flex-start;
  text-align: left;

  h2 { font-size: 1.8em; font-weight: 500; color: $my-primary; }
}
```

Usage: `## Big statement here {.statement}`

### Section Divider

```scss
.reveal section.elaborate-section {
  text-align: left;
  padding-left: 2em;
  border-left: 6px solid $my-primary;
  h1 { color: $my-primary; font-size: 2em; }
}
```

Provide `[data-background-color]` variants for each section class.

### Image Slide — Full-bleed background

```scss
.reveal section.image-slide > h2 {
  background: rgba($my-primary, 0.92);
  color: $my-light;
  padding: 0.35em 0.8em;
  border-radius: 0 0 0.6rem 0;
}
```

Bottom variant: `.image-slide-bottom` with `justify-content: flex-end`.

Usage: `## Title {.image-slide background-image="photo.jpg" background-size="cover"}`

## Footer and Slide Numbers

**Critical selector**: Footer uses `.reveal > .footer` (sibling of `.slides`), NOT `.reveal .slide .footer`:

```scss
.reveal .slide .footer,
.reveal > .footer {
  font-size: 0.5em;
  color: $my-dark;
  border-top: 1px solid rgba($my-primary, 0.15);
  padding-top: 0.4em;
  p { color: $my-dark; }
}

.reveal .slide-number,
.reveal .slide-number a {
  color: $my-dark !important;
}
```

Footer colors must be inverted inside the `inverted-slide` mixin for colored backgrounds.

## Logo

Set in `_extension.yml`: `revealjs: logo: logos/logo.svg`

Position with `!important`: `.slide-logo { position: fixed !important; }`

Invert on dark backgrounds using CSS filter:

```scss
.reveal section[data-background-color="DARK_HEX"] .slide-logo {
  filter: brightness(0) invert(1) opacity(0.92);
}
```

## Two-Column Layouts

```scss
.reveal section.title-bar .columns h3 {
  color: $my-secondary;
  font-weight: 600;
  font-size: 0.85em;
}
```

Usage in .qmd:

```markdown
## Slide Title {.title-bar}

:::: {.columns}
::: {.column width="50%"}
### Left Column
:::
::: {.column width="50%"}
### Right Column
:::
::::
```

## General Element Styling

All rules must use `.reveal .slide` or `.reveal section` prefixes to override reveal.js specificity.

```scss
.reveal .slide blockquote {
  border-left: 4px solid $my-primary;
  background: rgba($my-primary, 0.06);
  border-radius: 0 0.75rem 0.75rem 0;
  font-style: normal;
}

.reveal .slide a {
  border-bottom: 2px solid rgba($my-primary, 0.3);
  transition: border-color 0.2s ease;
  &:hover { border-bottom-color: $my-primary; }
}

.reveal .slide code:not(pre code) {
  background: rgba($my-primary, 0.08);
  border-radius: 0.25rem;
  padding: 0.1em 0.35em;
}
```

## Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Write CSS without `.reveal` prefix | Use `.reveal .slide` or `.reveal section` |
| Hardcode colors in rules | Use SCSS variables in defaults |
| Skip `!default` on variables | Always use `!default` |
| Repeat color inversions per-class | Use `@mixin inverted-slide` |
| Target `.reveal .slide .footer` only | Also target `.reveal > .footer` |
| Forget logo inversion on dark backgrounds | Add `filter: brightness(0) invert(1)` |

## Works Well With

- **quarto-extensions** — General extension structure, _extension.yml, brand.yml, Lua filters
- **quarto-typst** — Typst companion for multi-format extensions
