---
name: quarto-typst
description: "Typst PDF document templates for Quarto format extensions. Covers typst-template.typ function structure, typst-show.typ Pandoc template bridge, set/show rules, page setup (headers/footers/backgrounds/margins), context blocks for page-aware logic, multi-mode templates (report/letterhead/certificate via boolean flags), font and color management, tables, callouts, and accessibility patterns. Use when building or modifying Typst templates within Quarto extensions. Companion to quarto-extensions skill."
---

# Quarto Typst Templates

Typst-specific patterns for Quarto format extensions. Use alongside the `quarto-extensions` skill for general extension structure.

## Two-File Architecture

Typst format extensions use two template partials declared in `_extension.yml`:

```yaml
typst:
  brand: brand.yml
  template-partials:
    - typst-template.typ    # Layout and styling logic
    - typst-show.typ        # Bridges Quarto YAML -> Typst function
```

Always use `template-partials` (not `template`) to preserve Quarto's built-in bibliography and footnote handling.

## typst-template.typ

Defines a function receiving document metadata as named arguments, body as final `doc` argument:

```typst
#let myformat(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  logo-vertical-path: none,
  logo-horizontal-path: none,
  logo-favicon-path: none,
  primary: rgb("#6b21a8"),
  dark: rgb("#1e1e2e"),
  light: rgb("#e5e5f0"),
  surface: rgb("#f8f8fc"),
  letterhead: false,
  letterhead-details: none,
  certificate: false,
  certificate-recipient: none,
  certificate-description: none,
  certificate-footer: none,
  title-style: "default",
  doc,
) = {
  // Show rules, page setup, title page...
  doc
}
```

Accept multiple logo paths (vertical, horizontal, favicon) with fallback logic for different contexts.

### Show Rules

Shared rules before mode branching:

```typst
show heading.where(level: 1): set text(fill: primary, weight: 500)
show heading.where(level: 2): set text(fill: primary, weight: 600)
show heading.where(level: 3): set text(fill: dark, weight: 600)

show emph: set text(weight: 700, style: "normal")

show quote: it => {
  block(
    width: 100%,
    inset: (left: 1.2em, rest: 0.8em),
    fill: primary.lighten(92%),
    stroke: (left: 4pt + primary),
    radius: (right: 0.75em),
    it.body
  )
}

set table(
  stroke: 0.5pt + light,
  inset: 8pt,
  fill: (_, y) => {
    if y == 0 { primary }
    else if calc.odd(y) { surface }
  },
)
show table.cell.where(y: 0): set text(
  fill: ensure-contrast(light, primary), weight: 600
)
```

### Page Setup

```typst
set page(
  paper: "a4",
  margin: (top: 3cm, bottom: 2.5cm, x: 2.5cm),
  header: context {
    let curr = counter(page).get().first()
    if curr > 1 {
      grid(
        columns: (auto, 1fr),
        column-gutter: 12pt,
        align: (left + horizon, right + horizon),
        if logo-horizontal-path != none {
          image(logo-horizontal-path, height: 18pt)
        },
        text(size: 8pt, fill: luma(120),
          if title != none { title }),
      )
      v(4pt)
      line(length: 100%, stroke: 0.5pt + light)
    }
  },
  footer: context {
    let curr = counter(page).get().first()
    if curr == 1 {
      line(length: 100%, stroke: 4pt + primary)
    } else {
      line(length: 100%, stroke: 0.5pt + light)
      v(4pt)
      grid(
        columns: (1fr, auto),
        align: (left + horizon, right + horizon),
        text(size: 8pt, fill: luma(120))[myorg.com],
        text(size: 8pt, fill: luma(120))[
          #counter(page).display("1 / 1", both: true)
        ],
      )
    }
  },
)
```

Use `context` blocks for page-aware logic — headers/footers that differ on page 1 need `context` + `counter(page).get()`.

### Background Decorations

Use `set page(background: { ... })` with `place()`, `rect()`, `circle()`:

```typst
set page(
  background: context {
    let curr = counter(page).get().first()
    if curr == 1 {
      rect(width: 100%, height: 100%, fill: light)
      place(top + right,
        circle(radius: 4.5cm, fill: surface))
      place(top + right,
        rect(width: 2cm, height: 2.5cm, fill: primary,
             radius: (bottom-left: 1cm)))
      place(right + horizon, dx: -0.25cm,
        rect(width: 0.8cm, height: 30%, fill: primary,
             radius: 0.4cm))
      place(bottom + left,
        rect(width: 2.5cm, height: 2cm, fill: primary,
             radius: (top-right: 1.5cm)))
    }
  },
)
```

### Title Page

Default centered layout:

```typst
v(2fr)
if logo-vertical-path != none {
  align(center, image(logo-vertical-path, width: 25%))
  v(1.2cm)
}
align(center)[
  #if title != none {
    text(size: 26pt, weight: 500, fill: dark, title)
  }
]
// ... subtitle, authors, date ...
v(3fr)
pagebreak()
```

Elaborate variant with logo fallback:

```typst
if title-style == "elaborate" {
  // Background decorations set via page background context
  place(top + right, dx: -1.8cm, dy: 0.8cm,
    if logo-favicon-path != none {
      image(logo-favicon-path, height: 4cm)
    } else if logo-vertical-path != none {
      image(logo-vertical-path, height: 3cm)
    }
  )
  // Left-aligned content constrained to ~60% width
  block(width: 60%)[
    #if title != none {
      text(size: 28pt, weight: 500, fill: dark, title)
    }
    // ...
  ]
}
```

Favicon/submark preferred for elaborate titles (fits better in decorative circle area). Fall back to vertical logo.

## Multi-Mode Templates

Use boolean flags to switch between document modes within a single template function:

```typst
if certificate {
  // Landscape, decorative, no page numbers
  set page(paper: "a4", flipped: true, numbering: none, ...)
  // Certificate content...
} else if letterhead {
  // Branded header/footer bands on every page
  set page(margin: (top: 3.8cm, bottom: 3.2cm), numbering: none, ...)
  doc
} else {
  // Default report mode: title page + clean headers
  set page(...)
  // Title page + doc
}
```

Shared show rules (headings, quotes, tables) go before the mode branching.

### Letterhead Mode

Branded header/footer bands with `set page(background: { ... })`. Support a `letterhead-details` content parameter for chapter name, contact info, etc.:

```typst
// Header: details text on the right
place(top + right, dx: -2.5cm, dy: 1.15cm,
  text(size: 8pt, fill: luma(100))[
    #if letterhead-details != none { letterhead-details }
  ]
)
// Footer: centered details text
place(bottom + center, dy: -0.85cm,
  text(size: 8pt, fill: luma(100))[
    #if letterhead-details != none { letterhead-details }
    else [myorg.com]
  ]
)
```

### Certificate Mode

Landscape layout with decorative elements. Key parameters:

- `certificate-recipient` — displayed prominently in primary color
- `certificate-description` — falls back to `subtitle` if not set
- `certificate-footer` — defaults to organization URL

```typst
set page(paper: "a4", flipped: true, numbering: none,
  margin: (left: 3cm, right: 3cm, top: 2.5cm, bottom: 2cm),
  background: {
    rect(width: 100%, height: 100%, fill: light)
    place(top + right, circle(radius: 5.5cm, fill: surface))
    place(top + right,
      rect(width: 2.5cm, height: 3cm, fill: primary,
           radius: (bottom-left: 1.2cm)))
    place(right + horizon, dx: -0.3cm,
      rect(width: 1cm, height: 40%, fill: primary,
           radius: 0.5cm))
    place(bottom + left,
      rect(width: 3cm, height: 2.5cm, fill: primary,
           radius: (top-right: 2cm)))
  },
)

// Logo in the decorative circle area
place(top + right, dx: -3cm, dy: 1.5cm,
  if logo-favicon-path != none {
    image(logo-favicon-path, height: 6cm)
  } else if logo-vertical-path != none {
    image(logo-vertical-path, height: 3.5cm)
  }
)
```

## typst-show.typ

Pandoc template partial bridging YAML front matter into the Typst function:

```typst
#show: doc => myformat(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(by-author)$
  authors: ($for(by-author)$(name: [$it.name.literal$]),  $endfor$),
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
  logo-vertical-path: brand-logo-images.at("vertical", default: none).at("path", default: none),
  logo-horizontal-path: brand-logo-images.at("horizontal", default: none).at("path", default: none),
  logo-favicon-path: brand-logo-images.at("favicon", default: none).at("path", default: none),
  primary: brand-color.at("primary", default: rgb("#6b21a8")),
  light: brand-color.at("light", default: rgb("#e5e5f0")),
  surface: brand-color.at("background", default: rgb("#f8f8fc")),
  dark: brand-color.at("foreground", default: rgb("#1e1e2e")),
$if(letterhead)$
  letterhead: $letterhead$,
$endif$
$if(letterhead-details)$
  letterhead-details: [$letterhead-details$],
$endif$
$if(certificate)$
  certificate: $certificate$,
$endif$
$if(certificate-recipient)$
  certificate-recipient: [$certificate-recipient$],
$endif$
$if(certificate-description)$
  certificate-description: [$certificate-description$],
$endif$
$if(certificate-footer)$
  certificate-footer: [$certificate-footer$],
$endif$
$if(title-style)$
  title-style: "$title-style$",
$endif$
  doc,
)
```

Syntax rules:
- **Content** (title, subtitle, abstract, details): wrap in `[...]` for Typst content blocks
- **Booleans/numbers**: pass bare (no brackets)
- **Strings** for Typst string params: use `"$variable$"` (quoted)
- **Authors**: use `$for(by-author)$...$endfor$` loop
- **Brand data**: access `brand-color`, `brand-logo-images` directly (available when brand.yml is configured)
- **`doc`**: always passed last

## WCAG Contrast Utilities

```typst
#let luminance(c) = {
  let r = c.components().at(0) / 100%
  let g = c.components().at(1) / 100%
  let b = c.components().at(2) / 100%
  let linearize(v) = if v <= 0.03928 { v / 12.92 }
    else { calc.pow((v + 0.055) / 1.055, 2.4) }
  0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
}

#let contrast-ratio(c1, c2) = {
  let l1 = calc.max(luminance(c1), luminance(c2))
  let l2 = calc.min(luminance(c1), luminance(c2))
  (l1 + 0.05) / (l2 + 0.05)
}

#let ensure-contrast(fg, bg, min-ratio: 4.5) = {
  if contrast-ratio(fg, bg) >= min-ratio { fg }
  else if luminance(bg) > 0.5 { fg.darken(40%) }
  else { fg.lighten(40%) }
}
```

Use `ensure-contrast` for dynamically colored elements like table headers: `set text(fill: ensure-contrast(light, primary))`.

## Custom Callouts

```typst
#let callout(
  body: [],
  title: "Callout",
  background_color: rgb("#dddddd"),
  icon: none,
  icon_color: black,
  body_background_color: rgb("#f8f8fc"),
) = {
  block(
    breakable: false,
    fill: background_color,
    stroke: (left: 3pt + icon_color),
    width: 100%,
    radius: 0.5em,
    block(inset: 1pt, width: 100%, below: 0pt,
      block(fill: background_color, width: 100%,
            radius: (top: 0.5em), inset: 10pt,
      )[#text(icon_color, weight: 700)[#icon] #title]) +
    if body != [] {
      block(inset: 1pt, width: 100%,
        block(fill: body_background_color, width: 100%,
              radius: (bottom: 0.5em), inset: 10pt, body))
    }
  )
}
```

## Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Use `template:` in _extension.yml | Use `template-partials:` to preserve bibliography/footnotes |
| Hardcode colors in template body | Accept colors as parameters, pass from brand.yml via typst-show.typ |
| Forget `context` in headers/footers | Wrap page-counter logic in `context { }` blocks |
| Put mode-specific show rules before branching | Shared rules before `if`, mode-specific inside branches |
| Use `set page()` outside the function | All page configuration inside the template function |
| Use single logo path | Accept multiple logo paths with fallback (favicon > vertical > horizontal) |

## Works Well With

- **quarto-extensions** — General extension structure, _extension.yml, brand.yml, Lua filters
- **quarto-revealjs** — RevealJS companion for multi-format extensions
