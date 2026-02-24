---
name: hugo-theme-bs5
description: Bootstrap 5 integration with Hugo using npm, Hugo Pipes, and SCSS compilation. Covers Bootstrap 5 setup, component patterns, utility classes, and migration from Bootstrap 4.
license: CC-BY-4.0
compatibility: opencode
metadata:
  framework: hugo
  css-framework: bootstrap-5
  focus: asset-pipeline
---

# Hugo Theme with Bootstrap 5

Bootstrap 5 integration patterns for Hugo themes using npm and Hugo Pipes.

## Initial Setup

### package.json

```json
// Good: Bootstrap 5 with npm
{
  "name": "hugo-bs5-theme",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "hugo server -D",
    "build": "hugo --minify"
  },
  "dependencies": {
    "bootstrap": "^5.3.0",
    "@popperjs/core": "^2.11.8"
  },
  "devDependencies": {
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.24",
    "postcss-cli": "^10.1.0"
  }
}

// Bad: CDN links in templates
<!-- No version control, external dependency -->
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
```

### PostCSS Configuration

```javascript
// Good: postcss.config.js
module.exports = {
  plugins: {
    autoprefixer: {
      overrideBrowserslist: ['last 2 versions', '> 1%']
    }
  }
};
```

## SCSS Setup

### Main SCSS File

```scss
// Good: assets/scss/main.scss

// 1. Include functions first
@import "~bootstrap/scss/functions";

// 2. Custom variable overrides
@import "variables";

// 3. Import Bootstrap
@import "~bootstrap/scss/variables";
@import "~bootstrap/scss/variables-dark";
@import "~bootstrap/scss/maps";
@import "~bootstrap/scss/mixins";
@import "~bootstrap/scss/utilities";

// 4. Layout & components
@import "~bootstrap/scss/root";
@import "~bootstrap/scss/reboot";
@import "~bootstrap/scss/type";
@import "~bootstrap/scss/images";
@import "~bootstrap/scss/containers";
@import "~bootstrap/scss/grid";
@import "~bootstrap/scss/tables";
@import "~bootstrap/scss/forms";
@import "~bootstrap/scss/buttons";
@import "~bootstrap/scss/transitions";
@import "~bootstrap/scss/dropdown";
@import "~bootstrap/scss/nav";
@import "~bootstrap/scss/navbar";
@import "~bootstrap/scss/card";
@import "~bootstrap/scss/pagination";
@import "~bootstrap/scss/badge";
@import "~bootstrap/scss/alert";
@import "~bootstrap/scss/close";
@import "~bootstrap/scss/modal";
@import "~bootstrap/scss/tooltip";
@import "~bootstrap/scss/popover";

// 5. Helpers
@import "~bootstrap/scss/helpers";

// 6. Utilities
@import "~bootstrap/scss/utilities/api";

// 7. Custom components
@import "components/header";
@import "components/footer";
@import "components/article";

// Bad: Import everything
@import "~bootstrap/scss/bootstrap";
// Includes unused components, larger bundle
```

### Custom Variables

```scss
// Good: assets/scss/_variables.scss

// Color system
$primary: #0d6efd;
$secondary: #6c757d;
$success: #198754;
$info: #0dcaf0;
$warning: #ffc107;
$danger: #dc3545;

// Typography
$font-family-sans-serif: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
$font-size-base: 1rem;
$line-height-base: 1.6;

$h1-font-size: $font-size-base * 2.5;
$h2-font-size: $font-size-base * 2;
$h3-font-size: $font-size-base * 1.75;

// Spacing
$spacer: 1rem;
$spacers: (
  0: 0,
  1: $spacer * 0.25,
  2: $spacer * 0.5,
  3: $spacer,
  4: $spacer * 1.5,
  5: $spacer * 3,
  6: $spacer * 4,
  7: $spacer * 5
);

// Grid breakpoints
$grid-breakpoints: (
  xs: 0,
  sm: 576px,
  md: 768px,
  lg: 992px,
  xl: 1200px,
  xxl: 1400px
);

// Container widths
$container-max-widths: (
  sm: 540px,
  md: 720px,
  lg: 960px,
  xl: 1140px,
  xxl: 1320px
);

// Navbar
$navbar-padding-y: 0.5rem;
$navbar-padding-x: 1rem;

// Cards
$card-spacer-y: 1.25rem;
$card-spacer-x: 1.25rem;
$card-border-radius: 0.375rem;
$card-box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
```

## Hugo Pipes Integration

### Stylesheet Processing

```html
<!-- Good: partials/head/styles.html -->
{{ $options := dict
  "targetPath" "css/style.css"
  "outputStyle" "expanded"
  "enableSourceMap" (not hugo.IsProduction) }}

{{ $style := resources.Get "scss/main.scss"
  | toCSS $options
  | postCSS
  | minify
  | fingerprint "sha256" }}

<link rel="stylesheet"
      href="{{ $style.RelPermalink }}"
      {{ if hugo.IsProduction }}
      integrity="{{ $style.Data.Integrity }}"
      {{ end }}
      crossorigin="anonymous">

<!-- Bad: Direct CSS link -->
<link rel="stylesheet" href="/css/bootstrap.min.css">
```

### JavaScript Bundle

```html
<!-- Good: partials/scripts.html -->
{{ $js := resources.Get "js/bootstrap.bundle.js" }}
{{ if hugo.IsProduction }}
  {{ $js = $js | minify | fingerprint }}
{{ end }}

<script src="{{ $js.RelPermalink }}"
        {{ if hugo.IsProduction }}
        integrity="{{ $js.Data.Integrity }}"
        {{ end }}
        defer></script>

<!-- For separate Popper.js -->
{{ $popper := resources.Get "js/popper.js" }}
{{ $bootstrap := resources.Get "js/bootstrap.js" }}
{{ $bundle := slice $popper $bootstrap | resources.Concat "js/bundle.js" }}
{{ if hugo.IsProduction }}
  {{ $bundle = $bundle | minify | fingerprint }}
{{ end }}

<script src="{{ $bundle.RelPermalink }}" defer></script>
```

## Bootstrap 5 Components

### Navbar

```html
<!-- Good: Bootstrap 5 navbar -->
<nav class="navbar navbar-expand-lg navbar-light bg-light">
  <div class="container-fluid">
    <a class="navbar-brand" href="{{ .Site.BaseURL | relURL }}">
      {{ .Site.Title }}
    </a>
    
    <button class="navbar-toggler" 
            type="button" 
            data-bs-toggle="collapse" 
            data-bs-target="#navbarNav"
            aria-controls="navbarNav"
            aria-expanded="false" 
            aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>
    
    <div class="collapse navbar-collapse" id="navbarNav">
      <ul class="navbar-nav ms-auto">
        {{ range .Site.Menus.main }}
        <li class="nav-item">
          <a class="nav-link{{ if $.IsMenuCurrent "main" . }} active{{ end }}"
             {{ if $.IsMenuCurrent "main" . }}aria-current="page"{{ end }}
             href="{{ .URL | relLangURL }}">
            {{ .Name }}
          </a>
        </li>
        {{ end }}
      </ul>
    </div>
  </div>
</nav>

<!-- Bad: Bootstrap 4 syntax -->
<nav class="navbar navbar-expand-lg">
  <button data-toggle="collapse" data-target="#navbarNav">
    <!-- BS4: data-toggle/data-target don't work in BS5 -->
  </button>
</nav>
```

### Card Component

```html
<!-- Good: Bootstrap 5 card -->
<div class="card h-100 shadow-sm">
  {{ with .Params.image }}
    {{ $image := resources.Get . }}
    {{ if $image }}
      {{ $resized := $image.Resize "600x" }}
      <img src="{{ $resized.RelPermalink }}" 
           class="card-img-top" 
           alt="{{ $.Title }}"
           loading="lazy">
    {{ end }}
  {{ end }}
  
  <div class="card-body d-flex flex-column">
    <h5 class="card-title">
      <a href="{{ .RelPermalink }}" class="text-decoration-none">
        {{ .Title }}
      </a>
    </h5>
    
    <p class="card-text text-muted">{{ .Summary }}</p>
    
    <div class="mt-auto pt-3">
      <a href="{{ .RelPermalink }}" class="btn btn-primary">
        Read more
      </a>
    </div>
  </div>
  
  {{ if .Params.tags }}
  <div class="card-footer bg-transparent border-top-0">
    {{ range .Params.tags }}
      <span class="badge bg-secondary me-1">{{ . }}</span>
    {{ end }}
  </div>
  {{ end }}
</div>

<!-- Bad: Inconsistent spacing, no utility classes -->
<div class="card">
  <div class="card-body" style="padding: 20px;">
    <h5>{{ .Title }}</h5>
    <p>{{ .Summary }}</p>
  </div>
</div>
```

### Grid Layouts

```html
<!-- Good: Bootstrap 5 grid with gutters -->
<div class="container">
  <div class="row g-4">
    {{ range where .Site.RegularPages "Section" "blog" }}
    <div class="col-12 col-sm-6 col-lg-4">
      {{ .Render "card" }}
    </div>
    {{ end }}
  </div>
</div>

<!-- Good: Responsive column ordering -->
<div class="row">
  <div class="col-12 col-lg-8 order-2 order-lg-1">
    <main>{{ .Content }}</main>
  </div>
  <div class="col-12 col-lg-4 order-1 order-lg-2">
    <aside>{{ partial "sidebar.html" . }}</aside>
  </div>
</div>

<!-- Bad: Fixed widths, no responsiveness -->
<div class="row">
  <div class="col-4">
    <!-- Breaks on mobile -->
  </div>
</div>
```

## Bootstrap 4 to 5 Migration

### Data Attributes

```html
<!-- Good: Bootstrap 5 data attributes -->
<button data-bs-toggle="modal" data-bs-target="#myModal">
<div data-bs-spy="scroll" data-bs-target="#navbar">
<a data-bs-toggle="tab" href="#profile">

<!-- Bad: Bootstrap 4 attributes (won't work) -->
<button data-toggle="modal" data-target="#myModal">
<div data-spy="scroll" data-target="#navbar">
<a data-toggle="tab" href="#profile">
```

### Utility Classes

```html
<!-- Good: Bootstrap 5 utility classes -->
<div class="d-flex justify-content-between align-items-center mb-3">
  <h2 class="fw-bold text-primary mb-0">Title</h2>
  <span class="badge bg-success">New</span>
</div>

<div class="ms-3 me-2 ps-4 pe-3">
  <p class="text-start text-lg-end">Content</p>
</div>

<!-- Bad: Bootstrap 4 classes -->
<div class="d-flex justify-content-between align-items-center mb-3">
  <h2 class="font-weight-bold text-primary mb-0">Title</h2>
  <span class="badge badge-success">New</span>
</div>

<div class="ml-3 mr-2 pl-4 pr-3">
  <!-- ml/mr/pl/pr don't exist in BS5 -->
</div>
```

### Form Controls

```html
<!-- Good: Bootstrap 5 forms -->
<div class="mb-3">
  <label for="email" class="form-label">Email address</label>
  <input type="email" class="form-control" id="email" placeholder="name@example.com">
  <div class="form-text">We'll never share your email.</div>
</div>

<div class="form-check">
  <input class="form-check-input" type="checkbox" id="check1">
  <label class="form-check-label" for="check1">
    Check me out
  </label>
</div>

<!-- Bad: Bootstrap 4 forms -->
<div class="form-group">
  <label for="email">Email address</label>
  <input type="email" class="form-control" id="email">
  <small class="form-text text-muted">We'll never share your email.</small>
</div>
```

## Utility-First Patterns

### Spacing Utilities

```html
<!-- Good: Using spacing utilities -->
<article class="p-4 mb-5">
  <header class="mb-4 pb-3 border-bottom">
    <h1 class="mb-2">{{ .Title }}</h1>
    <p class="text-muted mb-0">{{ .Date.Format "January 2, 2006" }}</p>
  </header>
  
  <div class="content mt-4">
    {{ .Content }}
  </div>
</article>

<!-- Bad: Custom classes for every spacing need -->
<article class="article-container">
  <header class="article-header">
    <!-- Custom CSS for every element -->
  </header>
</article>
```

### Flexbox Utilities

```html
<!-- Good: Flexbox utilities -->
<div class="d-flex flex-column flex-md-row align-items-start align-items-md-center justify-content-between gap-3">
  <div class="flex-grow-1">
    <h3>Title</h3>
    <p class="text-muted mb-0">Description</p>
  </div>
  <div class="flex-shrink-0">
    <button class="btn btn-primary">Action</button>
  </div>
</div>

<!-- Bad: Custom flexbox CSS -->
<div style="display: flex; align-items: center;">
  <!-- Inline styles instead of utilities -->
</div>
```

### Color Utilities

```html
<!-- Good: Color utilities -->
<div class="bg-light text-dark p-3 mb-3">
  <p class="text-primary mb-2">Primary text</p>
  <p class="text-success mb-2">Success text</p>
  <p class="text-danger mb-0">Danger text</p>
</div>

<button class="btn btn-outline-primary">Outline</button>
<span class="badge bg-info">Info</span>
<div class="alert alert-warning" role="alert">Warning</div>

<!-- Bad: Custom color classes -->
<div class="light-bg dark-text">
  <p class="blue-text">Text</p>
</div>
```

## Custom Components

### Component SCSS

```scss
// Good: assets/scss/components/_article.scss

.article-meta {
  display: flex;
  align-items: center;
  gap: $spacer;
  color: $text-muted;
  font-size: $font-size-sm;
  
  @include media-breakpoint-down(sm) {
    flex-direction: column;
    align-items: flex-start;
    gap: $spacer * 0.5;
  }
}

.article-tags {
  display: flex;
  flex-wrap: wrap;
  gap: $spacer * 0.5;
  margin-top: $spacer * 1.5;
  
  .badge {
    font-weight: $font-weight-normal;
  }
}

// Using Bootstrap mixins
.custom-card {
  @include border-radius($card-border-radius);
  @include box-shadow($card-box-shadow);
  
  &:hover {
    @include box-shadow($card-box-shadow-hover);
  }
}
```

## Dark Mode Support

### Dark Mode Toggle

```html
<!-- Good: Dark mode with Bootstrap -->
<button class="btn btn-link" 
        id="theme-toggle"
        aria-label="Toggle dark mode">
  <svg class="sun-icon" width="24" height="24"><!-- sun icon --></svg>
  <svg class="moon-icon" width="24" height="24"><!-- moon icon --></svg>
</button>

<script>
(() => {
  const getStoredTheme = () => localStorage.getItem('theme');
  const setStoredTheme = theme => localStorage.setItem('theme', theme);
  
  const getPreferredTheme = () => {
    const storedTheme = getStoredTheme();
    if (storedTheme) {
      return storedTheme;
    }
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  };
  
  const setTheme = theme => {
    document.documentElement.setAttribute('data-bs-theme', theme);
  };
  
  setTheme(getPreferredTheme());
  
  document.getElementById('theme-toggle')?.addEventListener('click', () => {
    const currentTheme = document.documentElement.getAttribute('data-bs-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
    setStoredTheme(newTheme);
  });
})();
</script>
```

## Works Well With

- `hugo-theme` - Base Hugo theme structure and templating patterns
- `brand-yml` (Posit) - Apply consistent branding to Bootstrap sites

## When to Use Me

Use this skill when:
- Setting up Bootstrap 5 with Hugo and npm
- Configuring SCSS compilation with Hugo Pipes
- Migrating Hugo themes from Bootstrap 4 to 5
- Need Bootstrap 5 component patterns for Hugo
- Want utility-first approach with Bootstrap

## Quick Reference

**Setup:** `npm install bootstrap @popperjs/core`

**SCSS:** Import functions → variables → Bootstrap → custom

**Hugo Pipes:** SCSS → PostCSS → minify → fingerprint

**BS5 changes:**
- `data-toggle` → `data-bs-toggle`
- `data-target` → `data-bs-target`
- `font-weight-bold` → `fw-bold`
- `ml-*/mr-*` → `ms-*/me-*`
- `badge-*` → `bg-*`
- Form groups → `mb-3` spacing
