---
name: hugo-site
description: Hugo static site development best practices covering template architecture, asset pipelines (Hugo Pipes, Tailwind CSS, esbuild), multilingual content, performance, accessibility, and configuration patterns. Framework-agnostic guidance for building maintainable Hugo sites.
license: CC-BY-4.0
compatibility: opencode
metadata:
  framework: hugo
  min-version: "0.144.0"
---

# Hugo Static Site Development

Best practices for building and maintaining Hugo websites. Covers template architecture, asset pipelines, performance, accessibility, multilingual content, and configuration.

## Directory Structure

```
site/
├── archetypes/              # Content templates for `hugo new`
├── assets/                  # Processed by Hugo Pipes (CSS, JS, images)
│   ├── css/                 # Stylesheets (CSS, SCSS, or Tailwind)
│   │   └── components/      # Component-scoped styles
│   ├── js/                  # JavaScript source files
│   └── scss/                # SCSS if using Sass
├── config/
│   ├── _default/            # Base config (hugo.yaml, params.yaml, menu.yaml, languages.yaml)
│   ├── development/         # Dev overrides
│   └── production/          # Production overrides
├── content/                 # Markdown content (page bundles)
├── data/                    # Supplemental data (JSON, YAML, TOML)
├── i18n/                    # Translation strings per language
├── layouts/                 # Project-level layout overrides
├── static/                  # Copied as-is (favicon, robots.txt, fonts)
└── themes/theme-name/
    ├── assets/              # Theme assets (same structure as root)
    ├── layouts/
    │   ├── _default/        # baseof.html, list.html, single.html, terms.html
    │   ├── partials/        # Reusable template fragments
    │   │   ├── head/        # Meta, CSS, structured data
    │   │   ├── footer/      # Footer, scripts
    │   │   └── funcs/       # Pure-logic partials (return values, no HTML)
    │   └── shortcodes/      # Content-invokable components
    └── theme.toml           # Theme metadata
```

**Key rule**: Processable assets (CSS, JS, SCSS, images needing resize) go in `assets/`. Only files that need no processing go in `static/`.

## Template Architecture

### Base Template and Blocks

`baseof.html` defines the HTML shell. Child templates override blocks via `define`:

```go-html-template
{{/* baseof.html */}}
<!DOCTYPE html>
<html lang="{{ .Site.Language.Lang }}">
  <head>
    {{ partial "head/meta.html" . }}
    {{ partial "head/css.html" . }}
    {{ block "head" . }}{{ end }}
  </head>
  <body>
    {{ partial "nav.html" . }}
    <main id="main">
      {{ block "main" . }}{{ end }}
    </main>
    {{ partial "footer/footer.html" . }}
    {{ partial "footer/scripts.html" . }}
    {{ block "footer" . }}{{ end }}
  </body>
</html>
```

```go-html-template
{{/* section-name/list.html */}}
{{ define "head" }}
  {{/* Section-specific CSS */}}
{{ end }}

{{ define "main" }}
  <h1>{{ .Title }}</h1>
  {{ .Content }}
  {{ range .Pages }}
    {{ partial "card.html" . }}
  {{ end }}
{{ end }}

{{ define "footer" }}
  {{/* Section-specific JS */}}
{{ end }}
```

Rules:
- Child templates using a base template must contain **only** `define` actions, whitespace, and comments
- Always pass the dot (`.`) to blocks and partials
- Provide default content in `block` so pages render before blocks are overridden

### Partials

Organize by concern, not alphabetically:

```
partials/
├── head/          # <head> content: meta, CSS, structured data, analytics
├── footer/        # Footer HTML and script loading
├── home/          # Homepage section partials
├── post/          # Blog post components (header, authors, dates)
├── funcs/         # Logic-only partials that return values (no HTML output)
└── nav.html       # Navigation
```

**Use `partialCached`** for partials whose output doesn't vary per page:

```go-html-template
{{/* Good: cached since nav is the same on every page */}}
{{ partialCached "nav.html" . }}

{{/* Good: cached per language */}}
{{ partialCached "nav.html" . .Lang }}

{{/* Only use plain partial when output varies per page */}}
{{ partial "post/header.html" . }}
```

**Function partials** return values without side effects:

```go-html-template
{{/* partials/funcs/social-url.html */}}
{{ $urls := dict
  "github"   (printf "https://github.com/%s" .handle)
  "mastodon" .handle
  "bluesky"  (printf "https://bsky.app/profile/%s" .handle)
}}
{{ return index $urls .type }}
```

### Template Lookup Order

Hugo selects templates from most specific to most general: section type > page kind > default. Create section-specific templates (`layouts/blog/single.html`) to override defaults without conditionals.

### Nil-Safe Access

```go-html-template
{{/* Good: nil-safe with `with` */}}
{{ with .Params.author }}
  <span>{{ . }}</span>
{{ end }}

{{/* Good: provide a default */}}
{{ .Params.description | default .Site.Params.description }}

{{/* Bad: will error if .Params.author is nil */}}
{{ if .Params.author }}{{ .Params.author }}{{ end }}
```

## Asset Pipeline (Hugo Pipes)

### CSS

```go-html-template
{{/* SCSS → CSS → minify → fingerprint */}}
{{ $css := resources.Get "scss/main.scss" | toCSS | minify | fingerprint }}
<link rel="stylesheet" href="{{ $css.RelPermalink }}" integrity="{{ $css.Data.Integrity }}">
```

### Tailwind CSS (v4+)

Two approaches:

**1. Native Hugo function** (Hugo 0.154.5+):
```go-html-template
{{ $css := resources.Get "css/main.css" | css.TailwindCSS | minify | fingerprint }}
<link rel="stylesheet" href="{{ $css.RelPermalink }}" integrity="{{ $css.Data.Integrity }}">
```

Requires in `hugo.yaml`:
```yaml
build:
  buildStats:
    enable: true
```

**2. Pre-built via npm** (for complex setups with plugins):
```json
{
  "scripts": {
    "build:css": "npx @tailwindcss/cli -i assets/css/main.css -o assets/css/vendor/tailwind.css --minify"
  }
}
```
Then load the pre-built file via `resources.Get "css/vendor/tailwind.css"` and pipe through Hugo for fingerprinting.

### Tailwind CSS Architecture

Use CSS-first configuration with `@theme` for design tokens:

```css
@import "tailwindcss";

@theme {
  --color-primary: #881ef9;
  --color-primary-dark: #6b0fd4;
  --font-sans: 'Poppins', sans-serif;
  --radius-md: 1rem;
  --shadow-card: 0 1px 3px rgba(0,0,0,0.06);
}
```

**Prefer semantic component classes** over raw utilities in templates:

```css
/* assets/css/components/cards.css */
@layer components {
  .card {
    @apply bg-raised rounded-md shadow-card transition-shadow;
  }
  .card-hover:hover {
    @apply shadow-card-hover;
  }
}
```

```go-html-template
{{/* Good: semantic classes */}}
<div class="card card-hover">

{{/* Acceptable: layout-only utilities that don't warrant a class */}}
<div class="max-w-3xl mx-auto">

{{/* Bad: long utility strings that obscure intent */}}
<div class="bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow p-6 border border-gray-200">
```

Organize components in separate files and import from main entry:

```css
/* main.css */
@import "tailwindcss";
@import "./components/layout.css";
@import "./components/nav.css";
@import "./components/cards.css";
@import "./components/buttons.css";
@import "./components/typography.css";
```

### Dark Mode via CSS Custom Properties

Override design tokens on a `.dark` class — components automatically adapt:

```css
@custom-variant dark (&:where(.dark, .dark *));

.dark {
  --color-primary: #bb86f7;
  --color-bg: #121220;
  --color-surface: #1a1a2e;
  --color-dark: #ededf4;
  color-scheme: dark;
}
```

Load the dark mode script inline in `<head>` to prevent flash of wrong theme:

```go-html-template
{{ $darkmode := resources.Get "js/darkmode.js" | minify }}
<script>{{ $darkmode.Content | safeJS }}</script>
```

### JavaScript

**Hugo's `js.Build`** (uses esbuild internally):

```go-html-template
{{ $js := resources.Get "js/main.js"
  | js.Build (dict "minify" hugo.IsProduction "target" "es2020")
  | fingerprint }}
<script src="{{ $js.RelPermalink }}" integrity="{{ $js.Data.Integrity }}" defer></script>
```

**Bundling multiple files**:

```go-html-template
{{ $js := slice
  (resources.Get "js/counter.js")
  (resources.Get "js/scroll-reveal.js")
  | resources.Concat "bundle.js"
  | minify
  | fingerprint }}
<script src="{{ $js.RelPermalink }}" defer></script>
```

**For complex bundles** (libraries with many imports like FullCalendar, D3), pre-bundle with esbuild via npm:

```json
{
  "scripts": {
    "build:calendar": "npx esbuild assets/js/_calendar.entry.js --bundle --minify --outfile=assets/js/vendor/calendar.bundle.min.js"
  }
}
```

Then load the pre-built bundle through Hugo Pipes for fingerprinting only.

### npm Integration

```json
{
  "private": true,
  "scripts": {
    "clean": "rm -rf assets/js/vendor assets/css/vendor",
    "setup": "mkdir -p assets/js/vendor assets/css/vendor",
    "build": "npm run clean && npm run setup && npm run build:css && npm run build:js && npm run sync:deps",
    "postinstall": "npm run build"
  }
}
```

Key principles:
- `postinstall` ensures assets are ready after `npm install`
- Vendor outputs go to `assets/*/vendor/` (gitignored, rebuilt from source)
- Copy only needed files from `node_modules/` (fonts, pre-built JS)
- Never commit `node_modules/`

### Resource Concatenation and Fingerprinting

```go-html-template
{{/* Concatenate multiple CSS files, then minify and fingerprint once */}}
{{ $tw := resources.Get "css/vendor/tailwind.css" }}
{{ $custom := resources.Get "css/custom.css" }}
{{ $css := slice $tw $custom
  | resources.Concat "bundle.min.css"
  | minify
  | fingerprint }}
<link rel="stylesheet" href="{{ $css.RelPermalink }}" integrity="{{ $css.Data.Integrity }}">
```

Always use `.Data.Integrity` for Subresource Integrity on production assets.

## Performance

### Font Loading

```go-html-template
{{/* Preload critical font weights only */}}
<link rel="preload" href="{{ "/webfonts/main-400.woff2" | relURL }}"
      as="font" type="font/woff2" crossorigin>
<link rel="preload" href="{{ "/webfonts/main-600.woff2" | relURL }}"
      as="font" type="font/woff2" crossorigin>
```

```css
@font-face {
  font-family: 'Main';
  src: url('/webfonts/main-400.woff2') format('woff2');
  font-weight: 400;
  font-display: swap;
}
```

- Self-host fonts (npm packages like `@fontsource/*`)
- Use `font-display: swap` to prevent invisible text
- Preload only the 1-2 most critical weights
- Use woff2 format exclusively (universal browser support)

### Image Optimization

```go-html-template
{{ with .Resources.GetMatch "featured.*" }}
  {{ $small := .Resize "480x webp" }}
  {{ $medium := .Resize "960x webp" }}
  {{ $large := .Resize "1440x webp" }}
  <img src="{{ $medium.RelPermalink }}"
       srcset="{{ $small.RelPermalink }} 480w,
               {{ $medium.RelPermalink }} 960w,
               {{ $large.RelPermalink }} 1440w"
       sizes="(max-width: 480px) 480px, (max-width: 960px) 960px, 1440px"
       width="{{ .Width }}" height="{{ .Height }}"
       loading="lazy"
       alt="{{ $.Params.imageAlt | default $.Title }}">
{{ end }}
```

- Always set `width` and `height` to prevent layout shifts
- Use `loading="lazy"` on all images except hero/LCP
- Convert to WebP via Hugo's image processing
- Enable goldmark lazy loading for markdown images: `markup.goldmark.renderer.lazyLoadImages: true`

### Non-Critical CSS

Defer non-essential CSS (e.g., icon fonts):

```go-html-template
{{ $fa := resources.Get "scss/fontawesome.scss" | toCSS | minify | fingerprint }}
<link rel="stylesheet" href="{{ $fa.RelPermalink }}"
      media="print" onload="this.media='screen'">
<noscript><link rel="stylesheet" href="{{ $fa.RelPermalink }}"></noscript>
```

### HTML Minification

```yaml
# hugo.yaml
minify:
  minifyOutput: true
```

Also build with `hugo --minify` in production.

## Accessibility

### Semantic HTML

```go-html-template
<a href="#main" class="skip-link">Skip to main content</a>
<nav aria-label="Main navigation">...</nav>
<main id="main">
  <article>
    <h1>{{ .Title }}</h1>
    {{ .Content }}
  </article>
</main>
<aside aria-label="Table of contents">...</aside>
<footer>...</footer>
```

- One `<h1>` per page, proper heading hierarchy
- Use `<button>` for actions, `<a>` for navigation
- Skip-to-content link as first focusable element
- `aria-label` on `<nav>` when there are multiple navs
- `aria-hidden="true"` on decorative icons

### Focus and Keyboard

```css
:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}
```

- All interactive elements must be keyboard-accessible
- Visible focus indicators on `:focus-visible`
- Respect `prefers-reduced-motion`:

```css
@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

### External Links

Use a render hook to automatically handle external links:

```go-html-template
{{/* layouts/_markup/render-link.html */}}
<a href="{{ .Destination | safeURL }}"
  {{- if strings.HasPrefix .Destination "http" }} target="_blank" rel="noopener noreferrer"{{ end }}
  {{- with .Title }} title="{{ . }}"{{ end }}>
  {{- .Text | safeHTML -}}
</a>
```

### Images

```go-html-template
{{/* Always require alt text */}}
<img src="{{ .RelPermalink }}" alt="{{ .Params.alt | default .Title }}"
     width="{{ .Width }}" height="{{ .Height }}">

{{/* Decorative images */}}
<img src="decorative.svg" alt="" aria-hidden="true">
```

## SEO and Structured Data

### Meta Tags

```go-html-template
{{ $desc := .Description | default .Site.Params.description }}
{{ $title := .Title | plainify }}
{{ $siteTitle := .Site.Title | plainify }}

<title>{{ cond (eq $title $siteTitle) $title (printf "%s - %s" $title $siteTitle) }}</title>
<meta name="description" content="{{ $desc }}">
<link rel="canonical" href="{{ .Permalink }}">

{{/* Open Graph */}}
<meta property="og:title" content="{{ $title }}">
<meta property="og:description" content="{{ $desc }}">
<meta property="og:url" content="{{ .Permalink }}">
<meta property="og:type" content="{{ cond .IsPage "article" "website" }}">

{{/* Twitter Card */}}
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{{ $title }}">
<meta name="twitter:description" content="{{ $desc }}">
```

### Hreflang for Multilingual

```go-html-template
{{ if hugo.IsMultilingual }}
  {{ range .AllTranslations }}
    <link rel="alternate" hreflang="{{ .Lang }}" href="{{ .Permalink }}">
  {{ end }}
  <link rel="alternate" hreflang="x-default" href="{{ .Permalink }}">
{{ end }}
```

### JSON-LD Structured Data

```go-html-template
{{ if .IsHome }}
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "{{ .Site.Title }}",
  "url": "{{ .Site.BaseURL }}",
  "logo": "{{ "images/logo.svg" | absURL }}"
}
</script>
{{ end }}
```

### RSS

Enable RSS for sections with regular content:

```yaml
outputs:
  home: [HTML, RSS]
  section: [HTML, RSS]
  page: [HTML]
```

### Robots and Sitemap

```yaml
enableRobotsTXT: true
```

Hugo auto-generates `sitemap.xml`. Submit it to search engines.

## Multilingual

### Configuration

```yaml
# config/_default/languages.yaml
en:
  params:
    languageName: "English"
    weight: 1
fr:
  params:
    languageName: "Français"
    weight: 2
```

### Content Organization (filename-based)

```
content/
  about/
    _index.en.md
    _index.fr.md
  blog/
    my-post/
      index.en.md
      index.fr.md
      featured.jpg    # Shared across translations
```

Pages are linked automatically by shared base filename.

### Translation Strings

```yaml
# i18n/en.yaml
read_more:
  other: "Read more"
# i18n/fr.yaml
read_more:
  other: "Lire la suite"
```

```go-html-template
{{ i18n "read_more" | default "Read more" }}
```

### URL Construction

```go-html-template
{{/* Good: language-aware URL helpers */}}
<a href="{{ "about/" | relLangURL }}">
<a href="{{ .RelPermalink }}">

{{/* Bad: hardcoded paths break in non-default languages */}}
<a href="/about/">
```

**Never construct URLs manually.** Always use `.Permalink`, `.RelPermalink`, `relLangURL`, or `absLangURL`.

Run `hugo --printI18nWarnings` during development to find missing translations.

## Configuration

### Directory-Based Config

```
config/
  _default/        # Always loaded
    hugo.yaml      # Core: title, theme, outputs, build
    params.yaml    # Site parameters
    menu.yaml      # Navigation menus
    languages.yaml # Language definitions
    markup.yaml    # Markdown rendering options
  development/
    hugo.yaml      # Dev: buildDrafts: true, no minify
  production/
    hugo.yaml      # Prod: minify, analytics
```

Select environment: `hugo --environment production`

### Essential Settings

```yaml
# config/_default/hugo.yaml
enableRobotsTXT: true
enableGitInfo: true

buildDrafts: false       # Override in development only
buildFuture: false       # Override if needed

minify:
  minifyOutput: true

markup:
  goldmark:
    renderer:
      lazyLoadImages: true

taxonomies:
  category: categories
  tag: tags
```

### Environment-Conditional Logic

```go-html-template
{{ if hugo.IsProduction }}
  {{/* Analytics, minified assets, etc. */}}
{{ end }}
```

## Content Patterns

### Page Bundles

Co-locate content with its resources:

```
content/blog/my-post/
  index.md           # The page
  featured.jpg       # Accessible via .Resources
  diagram.svg
```

Access in templates: `{{ .Resources.GetMatch "featured.*" }}`

### Front Matter Conventions

```yaml
---
title: "Post Title"
date: 2026-03-14
description: "100-160 char description for SEO"
draft: false
tags: ["tag1", "tag2"]
image: featured.jpg
---
```

### Archetypes

```yaml
# archetypes/blog.md
---
title: "{{ replace .File.ContentBaseName "-" " " | title }}"
date: {{ .Date }}
draft: true
description: ""
tags: []
---
```

## Remote Data

```go-html-template
{{ with try (resources.GetRemote "https://api.example.com/data.json") }}
  {{ with .Err }}
    {{ errorf "Remote fetch failed: %s" . }}
  {{ else }}
    {{ $data := .Value | transform.Unmarshal }}
    {{/* use $data */}}
  {{ end }}
{{ end }}
```

Hugo caches remote resources. For build resilience, consider fallback data files in `data/`.

## Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Put processable assets in `static/` | Use `assets/` for anything Hugo Pipes should touch |
| Hardcode URLs (`/path/to/page`) | Use `.Permalink`, `relLangURL`, `absURL` |
| Use `.Page.URL` (deprecated) | Use `.Permalink` or `.RelPermalink` |
| Inline large `<script>` blocks in templates | Extract to `assets/js/` and bundle via Hugo Pipes |
| Use `var` in JavaScript | Use `const`/`let` (esbuild handles transpilation) |
| Load external scripts without SRI | Add `integrity` attribute or self-host |
| Skip `width`/`height` on images | Always set dimensions to prevent layout shifts |
| Use `readDir`/`readFile` in themes | Breaks portability; use data files or page resources |
| Commit `node_modules/` or vendor output | Gitignore and rebuild via `postinstall` |
| Set `buildDrafts: true` in default config | Override in `config/development/hugo.yaml` only |

## When to Use This Skill

Use when:
- Building or maintaining any Hugo static site
- Setting up Hugo asset pipelines (CSS, JS, fonts)
- Implementing multilingual Hugo sites
- Optimizing Hugo site performance
- Structuring Hugo templates and partials
- Integrating npm dependencies with Hugo

**Do NOT use for:**
- Quarto sites (use Posit skills instead)
- Non-Hugo static site generators (Eleventy, Astro, etc.)
