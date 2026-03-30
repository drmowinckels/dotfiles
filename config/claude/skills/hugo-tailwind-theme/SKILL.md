---
name: hugo-tailwind-theme
description: Build self-contained Hugo themes with Tailwind CSS 4, Alpine.js, and npm-managed vendor bundles. Theme users run only Hugo — all dependencies are pre-built inside the theme via npm postinstall. Covers the complete pattern for asset bundling, font self-hosting, dark mode, and on-demand vendor loading.
license: CC-BY-4.0
compatibility: opencode
metadata:
  framework: hugo
  css-framework: tailwindcss-4
  js-framework: alpinejs
  bundler: esbuild
---

# Hugo Theme with Tailwind CSS + Alpine.js

Patterns for building self-contained Hugo themes where **theme developers** manage npm, but **site users** only need Hugo. All vendor assets are pre-built inside the theme directory.

Builds on the `hugo-site` skill — use that for general Hugo templating, asset pipelines, i18n, and configuration. This skill covers the specific architecture for bundling a modern CSS/JS stack inside a Hugo theme.

## Architecture Overview

```
themes/my-theme/
├── package.json              # Theme-level npm (site users never touch this)
├── assets/
│   ├── css/
│   │   ├── main.css          # Tailwind entry point with @theme tokens
│   │   ├── components/       # Semantic component classes via @apply
│   │   └── vendor/           # Pre-built Tailwind output (gitignored or committed)
│   ├── scss/
│   │   └── fontawesome.scss  # FA compiled separately via Hugo toCSS
│   │   └── vendor/           # FA SCSS source (synced from node_modules)
│   └── js/
│       ├── darkmode.js       # Inlined in <head> to prevent FOUC
│       ├── counter.js        # Site-specific vanilla JS
│       ├── _calendar.entry.js # esbuild entry (underscore = not loaded directly)
│       └── vendor/           # Pre-built bundles (gitignored or committed)
├── static/
│   └── webfonts/             # Self-hosted fonts (synced from node_modules)
├── layouts/
│   └── ...                   # Hugo templates
└── theme.toml
```

**Key principle**: The `vendor/` directories and `static/webfonts/` are outputs of `npm run build`. Theme developers run npm; site users just run Hugo.

## package.json Pattern

```json
{
  "name": "hugo-my-theme",
  "private": true,
  "version": "1.0.0",
  "scripts": {
    "clean": "rm -rf assets/js/vendor assets/css/vendor assets/scss/vendor static/webfonts",
    "setup": "mkdir -p assets/js/vendor assets/css/vendor assets/scss/vendor static/webfonts",
    "build": "npm run clean && npm run setup && npm run build:css && npm run build:bundles && npm run sync:deps",
    "build:css": "npx @tailwindcss/cli -i assets/css/main.css -o assets/css/vendor/tailwind.css --minify",
    "build:bundles": "npm run build:calendar && npm run build:map",
    "build:calendar": "npx esbuild assets/js/_calendar.entry.js --bundle --minify --sourcemap --outfile=assets/js/vendor/calendar.bundle.min.js",
    "build:map": "npx esbuild assets/js/_map.entry.js --bundle --minify --sourcemap --outfile=assets/js/vendor/map.bundle.min.js --loader:.json=json",
    "sync:deps": "npm run sync:fontawesome && npm run sync:alpine && npm run sync:fonts",
    "sync:fontawesome": "rm -rf static/webfonts/fontawesome && mkdir -p static/webfonts/fontawesome && cp node_modules/@fortawesome/fontawesome-free/webfonts/*.woff2 static/webfonts/fontawesome/ && cp -r node_modules/@fortawesome/fontawesome-free/scss assets/scss/vendor/fontawesome",
    "sync:alpine": "cp node_modules/alpinejs/dist/cdn.min.js assets/js/vendor/alpine.min.js",
    "sync:fonts": "mkdir -p static/webfonts/google-fonts/myfont && cp node_modules/@fontsource/myfont/files/myfont-latin-*-normal.woff2 static/webfonts/google-fonts/myfont/",
    "update": "npm update && npm run build",
    "postinstall": "npm run build"
  },
  "devDependencies": {
    "esbuild": "^0.27.0"
  },
  "dependencies": {
    "@tailwindcss/cli": "^4.1.0",
    "tailwindcss": "^4.1.0",
    "alpinejs": "^3.14.0",
    "@fortawesome/fontawesome-free": "^6.7.0",
    "@fontsource/myfont": "^5.0.0"
  }
}
```

Key design decisions:
- `postinstall` runs the full build automatically after `npm install`
- `clean` + `setup` ensures fresh vendor directories on every build
- Underscore-prefixed JS files (`_calendar.entry.js`) are esbuild entry points, not directly loaded by Hugo
- Each sync script copies only what's needed — no wholesale `node_modules/` copies
- `2>/dev/null || true` on optional syncs prevents build failures for unused deps

### When to commit vendor output vs gitignore

**Commit vendor output** (recommended for themes distributed to non-technical users):
- Site users run `hugo` without npm
- CI/CD doesn't need Node.js
- Predictable builds

**Gitignore vendor output** (for teams that already use npm):
- Smaller repo
- CI runs `npm install --prefix themes/my-theme` before Hugo build
- Add to `.github/workflows/`: `npm install --prefix themes/my-theme`

## Tailwind CSS 4 Setup

### Entry Point

```css
/* assets/css/main.css */
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  --color-primary: #881ef9;
  --color-primary-light: #a152f8;
  --color-primary-dark: #6b0fd4;
  --color-accent-blue: #146af9;
  --color-accent-rose: #ff5b92;
  --color-dark: #2f2f30;
  --color-light: #ededf4;
  --color-bg: #ededf4;
  --color-muted: #5d5f66;
  --color-surface: #f8f8fc;
  --color-raised: #ffffff;
  --color-border: #e5e7eb;

  --font-sans: 'MyFont', sans-serif;
  --font-mono: 'MonoFont', monospace;

  --radius-sm: 0.5rem;
  --radius-md: 1rem;

  --shadow-card: 0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04);
  --shadow-card-hover: 0 10px 25px rgba(136,30,249,0.08), 0 4px 10px rgba(0,0,0,0.06);
}

[x-cloak] { display: none !important; }

@layer base {
  @font-face {
    font-family: 'MyFont';
    src: url('/webfonts/google-fonts/myfont/myfont-latin-400-normal.woff2') format('woff2');
    font-weight: 400;
    font-display: swap;
  }

  html {
    scroll-behavior: smooth;
    color: var(--color-dark);
    background-color: var(--color-bg);
  }

  @media (prefers-reduced-motion: reduce) {
    html { scroll-behavior: auto; }
  }

  :focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
  }
}

/* Component imports */
@import "./components/layout.css";
@import "./components/nav.css";
@import "./components/buttons.css";
@import "./components/cards.css";
@import "./components/typography.css";
@import "./components/darkmode.css";
```

### Component CSS Pattern

```css
/* assets/css/components/cards.css */
@layer components {
  .card {
    @apply rounded-md overflow-hidden;
    background-color: var(--color-raised);
    box-shadow: var(--shadow-card);
    border: 1px solid var(--color-border);
  }

  .card-hover {
    @apply transition-shadow duration-200;
  }

  .card-hover:hover {
    box-shadow: var(--shadow-card-hover);
  }

  .card-body {
    @apply p-6;
  }
}
```

### Why @apply + Semantic Classes

Tailwind utilities in templates create long, hard-to-read class strings. The pattern here uses `@apply` in component CSS files to create semantic classes:

```go-html-template
{{/* Good: semantic classes, readable templates */}}
<div class="card card-hover">
  <div class="card-body">
    <h3 class="card-title">{{ .Title }}</h3>
  </div>
</div>

{{/* Acceptable: layout utilities that don't warrant a named class */}}
<div class="max-w-3xl mx-auto py-12">

{{/* Bad: utility soup in templates */}}
<div class="bg-white rounded-lg shadow-md hover:shadow-lg p-6 border border-gray-200 transition-shadow">
```

Reserve raw Tailwind utilities for one-off layout concerns. Create named component classes for anything reusable or complex.

## Dark Mode

### CSS Custom Property Override

The entire dark mode works by swapping design tokens on a `.dark` class:

```css
/* assets/css/components/darkmode.css */
@layer components {
  .dark {
    --color-primary: #bb86f7;
    --color-primary-light: #d4b9f5;
    --color-primary-dark: #a152f8;
    --color-bg: #121220;
    --color-surface: #1a1a2e;
    --color-dark: #ededf4;
    --color-muted: #9ca3af;
    --color-border: rgba(255, 255, 255, 0.1);
    --color-raised: #1e1e30;
    --shadow-card: 0 1px 3px rgba(0,0,0,0.3);
    color-scheme: dark;
  }
}
```

Because components reference `var(--color-*)`, most things adapt automatically. Only add per-component dark overrides for edge cases (vendor widget styling, specific opacity tweaks).

### JavaScript (Inlined in head)

```javascript
/* assets/js/darkmode.js — inlined to prevent FOUC */
(function () {
  function getTheme() {
    const stored = localStorage.getItem('theme');
    if (stored) return stored;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function applyTheme(theme) {
    document.documentElement.classList.toggle('dark', theme === 'dark');
  }

  applyTheme(getTheme());

  window.toggleTheme = function () {
    const isDark = document.documentElement.classList.contains('dark');
    const next = isDark ? 'light' : 'dark';
    localStorage.setItem('theme', next);
    applyTheme(next);
    window.dispatchEvent(new CustomEvent('themechange', { detail: { theme: next } }));
  };

  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function (e) {
    if (!localStorage.getItem('theme')) {
      applyTheme(e.matches ? 'dark' : 'light');
    }
  });
})();
```

Load it inline in `<head>` (not as an external file) to run before first paint:

```go-html-template
{{ $darkmode := resources.Get "js/darkmode.js" | minify }}
<script>{{ $darkmode.Content | safeJS }}</script>
```

### Toggle Button (Alpine.js)

```go-html-template
<button @click="toggleTheme()"
        class="dark-mode-toggle"
        aria-label="{{ i18n "toggle_dark_mode" }}">
  <i class="fa-solid fa-moon dark:hidden" aria-hidden="true"></i>
  <i class="fa-solid fa-sun hidden dark:inline" aria-hidden="true"></i>
</button>
```

## Asset Loading in Hugo Templates

### Head — CSS Pipeline

```go-html-template
{{/* layouts/partials/head/head.html */}}

{{/* Dark mode: inline in <head> to prevent FOUC */}}
{{ $darkmode := resources.Get "js/darkmode.js" | minify }}
<script>{{ $darkmode.Content | safeJS }}</script>

{{/* Preload critical fonts */}}
<link rel="preload" href="{{ "/webfonts/google-fonts/myfont/myfont-latin-400-normal.woff2" | relURL }}"
      as="font" type="font/woff2" crossorigin>

{{/* Main CSS: pre-built Tailwind → concat → minify → fingerprint */}}
{{ $tw := resources.Get "css/vendor/tailwind.css" }}
{{ $css := slice $tw
  | resources.Concat "theme-bundle.min.css"
  | minify
  | fingerprint
}}
<link rel="stylesheet" href="{{ $css.RelPermalink }}"
      integrity="{{ $css.Data.Integrity }}" media="screen">

{{/* FontAwesome: compiled from SCSS, deferred loading */}}
{{ $fa := resources.Get "scss/fontawesome.scss" | toCSS | minify | fingerprint }}
<link rel="stylesheet" href="{{ $fa.RelPermalink }}"
      integrity="{{ $fa.Data.Integrity }}"
      media="print" onload="this.media='screen'">
<noscript><link rel="stylesheet" href="{{ $fa.RelPermalink }}"></noscript>
```

### Footer — JS Pipeline

```go-html-template
{{/* layouts/partials/footer/scripts.html */}}

{{/* Site JS: concat custom scripts → minify → fingerprint */}}
{{ $js := slice
    (resources.Get "js/counter.js")
    (resources.Get "js/scroll-reveal.js")
    | resources.Concat "theme-bundle.js"
    | minify
    | fingerprint
}}
<script src="{{ $js.RelPermalink }}"
        integrity="{{ $js.Data.Integrity }}" defer></script>

{{/* Alpine.js: loaded from pre-built vendor copy */}}
{{ $alpine := resources.Get "js/vendor/alpine.min.js" | fingerprint }}
<script src="{{ $alpine.RelPermalink }}"
        integrity="{{ $alpine.Data.Integrity }}" defer></script>
```

### On-Demand Vendor Loading

Heavy libraries (calendar, maps, select widgets) load only on pages that need them via the block system:

```go-html-template
{{/* baseof.html defines the blocks */}}
{{ block "head" . }}{{ end }}   {{/* for page-specific CSS */}}
{{ block "footer" . }}{{ end }} {{/* for page-specific JS */}}

{{/* events/list.html uses them */}}
{{ define "head" }}
  {{ $calCss := resources.Get "css/vendor/calendar.min.css" | minify | fingerprint }}
  <link rel="stylesheet" href="{{ $calCss.RelPermalink }}"
        integrity="{{ $calCss.Data.Integrity }}">
{{ end }}

{{ define "footer" }}
  {{ $cal := resources.Get "js/vendor/calendar.bundle.min.js" | fingerprint }}
  <script src="{{ $cal.RelPermalink }}"
          integrity="{{ $cal.Data.Integrity }}" defer></script>
{{ end }}
```

Create small partials for vendor loading to keep templates clean:

```go-html-template
{{/* partials/footer/choices-js.html */}}
{{ $choices := resources.Get "js/vendor/choices.min.js" | fingerprint }}
<script src="{{ $choices.RelPermalink }}"
        integrity="{{ $choices.Data.Integrity }}" defer></script>

{{/* Then in the section template */}}
{{ define "footer" }}
  {{ partial "footer/choices-js.html" . }}
{{ end }}
```

## esbuild Entry Point Pattern

For libraries with many imports (FullCalendar, D3, etc.), create entry point files that bundle everything and expose it on `window`:

```javascript
/* assets/js/_calendar.entry.js — underscore prefix = esbuild entry, not loaded directly */
import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import listPlugin from '@fullcalendar/list';

window.FullCalendar = { Calendar };
window.FullCalendar.plugins = {
  dayGrid: dayGridPlugin,
  list: listPlugin
};
```

```javascript
/* assets/js/_map.entry.js */
import { geoEqualEarth, geoPath } from 'd3-geo';
import { select } from 'd3-selection';
import { zoom, zoomIdentity } from 'd3-zoom';
import { feature } from 'topojson-client';
import world from 'world-atlas/countries-110m.json';

window.__d3map = {
  geoEqualEarth, geoPath, select, zoom, zoomIdentity, feature, world
};
```

Then a separate vanilla JS file (loaded via Hugo Pipes) reads from `window.__d3map` to initialize the UI. This keeps the bundled library separate from the page-specific init code.

## Alpine.js Patterns

Alpine handles all declarative UI interactions — no custom JS needed for these:

```go-html-template
{{/* Mobile nav toggle */}}
<nav x-data="{ open: false, scrolled: false }"
     @scroll.window="scrolled = (window.scrollY > 50)"
     :class="scrolled ? 'nav-solid' : 'nav-transparent'">

  <button @click="open = !open" :aria-expanded="open">
    <i class="fa fa-bars" x-show="!open"></i>
    <i class="fa fa-times" x-show="open" x-cloak></i>
  </button>

  <div x-show="open" x-transition x-cloak>
    {{/* mobile menu content */}}
  </div>
</nav>

{{/* Dropdown */}}
<div x-data="{ dropOpen: false }"
     @mouseenter="dropOpen = true"
     @mouseleave="dropOpen = false"
     @keydown.escape="dropOpen = false">
  <button @click="dropOpen = !dropOpen"
          :aria-expanded="dropOpen"
          aria-haspopup="true">
    Menu <i class="fa fa-chevron-down" :class="dropOpen && 'rotate-180'"></i>
  </button>
  <div x-show="dropOpen" x-transition x-cloak role="menu">
    {{/* dropdown items */}}
  </div>
</div>

{{/* Back to top */}}
<button x-data="{ show: false }"
        @scroll.window="show = (window.scrollY > 600)"
        x-show="show" x-transition x-cloak
        @click="window.scrollTo({ top: 0, behavior: 'smooth' })"
        aria-label="Back to top">
  <i class="fa fa-chevron-up" aria-hidden="true"></i>
</button>

{{/* Tab panels */}}
<div x-data="{ tab: 'current' }">
  <button :class="tab === 'current' && 'active'" @click="tab = 'current'">Current</button>
  <button :class="tab === 'past' && 'active'" @click="tab = 'past'">Past</button>
  <div x-show="tab === 'current'">...</div>
  <div x-show="tab === 'past'" x-cloak>...</div>
</div>
```

Always add `x-cloak` on elements hidden by default and include this CSS rule:

```css
[x-cloak] { display: none !important; }
```

## Font Self-Hosting

Use `@fontsource` packages via npm. The sync script copies only woff2 files:

```bash
# In package.json sync:fonts script
mkdir -p static/webfonts/google-fonts/poppins
for w in 300 400 500 600 700; do
  cp node_modules/@fontsource/poppins/files/poppins-latin-${w}-normal.woff2 \
     static/webfonts/google-fonts/poppins/
done

# Variable fonts
mkdir -p static/webfonts/google-fonts/inconsolata
cp node_modules/@fontsource-variable/inconsolata/files/inconsolata-latin-*-normal.woff2 \
   static/webfonts/google-fonts/inconsolata/
```

Declare in CSS with `font-display: swap`:

```css
@font-face {
  font-family: 'Poppins';
  src: url('/webfonts/google-fonts/poppins/poppins-latin-400-normal.woff2') format('woff2');
  font-weight: 400;
  font-display: swap;
}
```

Preload only the 1-2 most critical weights in the `<head>`.

## FontAwesome via SCSS

FontAwesome is compiled from SCSS source (synced from npm) rather than loading the full CSS:

```scss
/* assets/scss/fontawesome.scss */
$fa-font-path: "/webfonts/fontawesome";
@import "vendor/fontawesome/fontawesome";
@import "vendor/fontawesome/_solid";
@import "vendor/fontawesome/_brands";
@import "vendor/fontawesome/_regular";
```

Hugo compiles this via `toCSS`. Load it deferred since icons aren't critical for first paint:

```go-html-template
{{ $fa := resources.Get "scss/fontawesome.scss" | toCSS | minify | fingerprint }}
<link rel="stylesheet" href="{{ $fa.RelPermalink }}"
      media="print" onload="this.media='screen'">
<noscript><link rel="stylesheet" href="{{ $fa.RelPermalink }}"></noscript>
```

## Theme Developer Workflow

```bash
cd themes/my-theme

# Initial setup
npm install          # postinstall runs the full build automatically

# After changing Tailwind CSS or component styles
npm run build:css

# After changing an esbuild entry point
npm run build:bundles

# After updating npm dependencies
npm run update       # updates packages + rebuilds everything

# Full rebuild
npm run build
```

## Site User Workflow

```bash
# No npm needed — just Hugo
hugo server -D                           # local dev
hugo --environment production            # production build

# If theme deps need updating (CI/CD)
npm install --prefix themes/my-theme     # postinstall handles the rest
```

## Checklist for New Themes

- [ ] `package.json` with `postinstall` that runs full build
- [ ] Tailwind entry in `assets/css/main.css` with `@theme` tokens
- [ ] Component CSS in `assets/css/components/` using `@apply`
- [ ] Dark mode via CSS custom property overrides on `.dark`
- [ ] `darkmode.js` inlined in `<head>` (not external)
- [ ] Alpine.js synced to `assets/js/vendor/alpine.min.js`
- [ ] Fonts self-hosted in `static/webfonts/`
- [ ] FontAwesome compiled from SCSS, loaded deferred
- [ ] Heavy vendor libs as esbuild bundles loaded on-demand via blocks
- [ ] All vendor JS/CSS fingerprinted with SRI via Hugo Pipes
- [ ] `[x-cloak]` CSS rule in main stylesheet

## Works Well With

- `hugo-site` — General Hugo templating, i18n, configuration, and content patterns
- `d3js-skill` — D3 visualization patterns for maps and charts

## When to Use This Skill

Use when:
- Creating a new Hugo theme with Tailwind CSS 4 and Alpine.js
- Setting up vendor asset bundling inside a Hugo theme
- Implementing dark mode with CSS custom property swapping
- Self-hosting fonts and icons inside a theme
- Loading heavy JS libraries on-demand in Hugo

**Do NOT use for:**
- General Hugo templating (use `hugo-site`)
- Sites using Bootstrap, Bulma, or other CSS frameworks
- Sites where users manage their own npm/Tailwind setup at root level
