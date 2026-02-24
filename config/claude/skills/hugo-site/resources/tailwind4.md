---
name: hugo-theme-tailwind4
description: Tailwind CSS 4 integration with Hugo using the new CSS-first engine, Hugo Pipes, and modern configuration. Covers Tailwind 4 setup, utility patterns, component extraction, and build optimization.
license: CC-BY-4.0
compatibility: opencode
metadata:
  framework: hugo
  css-framework: tailwind-4
  focus: asset-pipeline
---

# Hugo Theme with Tailwind CSS 4

Tailwind CSS 4 integration patterns for Hugo using the new CSS-first engine and Hugo Pipes.

## Initial Setup

### package.json

```json
// Good: Tailwind CSS 4 with minimal dependencies
{
  "name": "hugo-tailwind4-theme",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "hugo server -D",
    "build": "hugo --minify"
  },
  "dependencies": {
    "tailwindcss": "^4.1.0"
  },
  "devDependencies": {
    "@tailwindcss/typography": "^0.5.10",
    "autoprefixer": "^10.4.16"
  }
}

// Bad: Tailwind 3 config
{
  "dependencies": {
    "tailwindcss": "^3.4.0"
    // Tailwind 4 has breaking changes
  }
}
```

### Tailwind Configuration (CSS-first)

```css
/* Good: assets/css/tailwind.css - Tailwind 4 syntax */
@import "tailwindcss";

/* Theme configuration */
@theme {
  --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --font-serif: Georgia, serif;
  --font-mono: ui-monospace, SFMono-Regular, monospace;
  
  --color-brand-50: #f0f9ff;
  --color-brand-500: #0ea5e9;
  --color-brand-900: #0c4a6e;
  
  --breakpoint-3xl: 1920px;
  
  --spacing-18: 4.5rem;
}

/* Custom utilities */
@utility tab-* {
  tab-size: *;
}

/* Component layer */
@layer components {
  .btn {
    @apply px-4 py-2 rounded font-medium transition-colors;
    @apply hover:opacity-90 active:opacity-80;
  }
  
  .btn-primary {
    @apply bg-brand-500 text-white;
  }
  
  .card {
    @apply bg-white rounded-lg shadow-sm p-6;
    @apply hover:shadow-md transition-shadow;
  }
}

/* Bad: Tailwind 3 JavaScript config */
// tailwind.config.js with module.exports
// Doesn't work with Tailwind 4's CSS-first approach
```

### PostCSS Configuration

```javascript
// Good: postcss.config.js
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {}
  }
};
```

## Hugo Pipes Integration

### CSS Processing

```html
<!-- Good: partials/head/styles.html -->
{{ $options := dict
  "targetPath" "css/style.css"
  "outputStyle" "expanded" }}

{{ $style := resources.Get "css/tailwind.css"
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

<!-- Bad: No processing -->
<link rel="stylesheet" href="/css/tailwind.css">
```

### Development vs Production

```html
<!-- Good: Conditional processing -->
{{ $css := resources.Get "css/tailwind.css" | toCSS | postCSS }}

{{ if hugo.IsProduction }}
  {{ $css = $css | minify | fingerprint }}
{{ end }}

<link rel="stylesheet" href="{{ $css.RelPermalink }}">
```

## Layout Patterns

### Container and Grid

```html
<!-- Good: Responsive container -->
<div class="container mx-auto px-4 sm:px-6 lg:px-8 max-w-7xl">
  {{ .Content }}
</div>

<!-- Good: Grid layout -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  {{ range .Pages }}
  <article class="bg-white rounded-lg shadow-sm p-6">
    <h2 class="text-xl font-bold mb-2">{{ .Title }}</h2>
    <p class="text-gray-600">{{ .Summary }}</p>
  </article>
  {{ end }}
</div>

<!-- Good: Flex layout with responsive direction -->
<div class="flex flex-col lg:flex-row gap-8">
  <main class="flex-1 order-2 lg:order-1">
    {{ .Content }}
  </main>
  <aside class="w-full lg:w-64 order-1 lg:order-2">
    {{ partial "sidebar.html" . }}
  </aside>
</div>

<!-- Bad: Fixed widths -->
<div style="width: 1200px; margin: 0 auto;">
  <!-- Not responsive -->
</div>
```

### Card Component

```html
<!-- Good: Tailwind utility-first card -->
<article class="group bg-white rounded-lg overflow-hidden shadow-sm hover:shadow-md transition-shadow">
  {{ with .Params.image }}
    {{ $image := resources.Get . }}
    {{ if $image }}
      {{ $resized := $image.Resize "600x" }}
      <div class="aspect-video overflow-hidden">
        <img src="{{ $resized.RelPermalink }}"
             alt="{{ $.Title }}"
             class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
             loading="lazy">
      </div>
    {{ end }}
  {{ end }}
  
  <div class="p-6">
    <h3 class="text-xl font-bold mb-2 group-hover:text-brand-600 transition-colors">
      <a href="{{ .RelPermalink }}" class="stretched-link">
        {{ .Title }}
      </a>
    </h3>
    
    <p class="text-gray-600 mb-4 line-clamp-3">
      {{ .Summary }}
    </p>
    
    <div class="flex items-center justify-between text-sm text-gray-500">
      <time datetime="{{ .Date.Format "2006-01-02" }}">
        {{ .Date.Format "Jan 2, 2006" }}
      </time>
      <span>{{ .ReadingTime }} min read</span>
    </div>
    
    {{ if .Params.tags }}
    <div class="flex flex-wrap gap-2 mt-4">
      {{ range .Params.tags }}
        <span class="px-2 py-1 text-xs font-medium bg-gray-100 text-gray-700 rounded">
          {{ . }}
        </span>
      {{ end }}
    </div>
    {{ end }}
  </div>
</article>

<!-- Bad: Mixed inline styles and utilities -->
<div class="bg-white" style="border-radius: 8px; padding: 24px;">
  <!-- Inconsistent approach -->
</div>
```

### Navigation

```html
<!-- Good: Responsive navigation -->
<nav class="bg-white shadow-sm">
  <div class="container mx-auto px-4 sm:px-6 lg:px-8">
    <div class="flex items-center justify-between h-16">
      <a href="{{ .Site.BaseURL | relURL }}" 
         class="text-xl font-bold text-gray-900">
        {{ .Site.Title }}
      </a>
      
      <!-- Desktop menu -->
      <div class="hidden md:flex md:items-center md:space-x-8">
        {{ range .Site.Menus.main }}
        <a href="{{ .URL | relLangURL }}"
           class="text-gray-700 hover:text-brand-600 transition-colors font-medium{{ if $.IsMenuCurrent "main" . }} text-brand-600{{ end }}">
          {{ .Name }}
        </a>
        {{ end }}
      </div>
      
      <!-- Mobile menu button -->
      <button type="button"
              class="md:hidden inline-flex items-center justify-center p-2 rounded-md text-gray-700 hover:text-brand-600 hover:bg-gray-100"
              x-data="{ open: false }"
              @click="open = !open"
              aria-expanded="false">
        <span class="sr-only">Open main menu</span>
        <!-- Icon -->
      </button>
    </div>
  </div>
  
  <!-- Mobile menu -->
  <div class="md:hidden" x-show="open" x-cloak>
    <div class="px-2 pt-2 pb-3 space-y-1">
      {{ range .Site.Menus.main }}
      <a href="{{ .URL | relLangURL }}"
         class="block px-3 py-2 rounded-md text-base font-medium text-gray-700 hover:text-brand-600 hover:bg-gray-50{{ if $.IsMenuCurrent "main" . }} text-brand-600 bg-gray-50{{ end }}">
        {{ .Name }}
      </a>
      {{ end }}
    </div>
  </div>
</nav>
```

## Typography with @tailwindcss/typography

### Prose Styling

```html
<!-- Good: Typography plugin for content -->
<article class="prose prose-lg lg:prose-xl max-w-none">
  {{ .Content }}
</article>

<!-- Good: Custom prose colors -->
<article class="prose prose-gray prose-headings:font-bold prose-a:text-brand-600 hover:prose-a:text-brand-700">
  {{ .Content }}
</article>

<!-- Good: Dark mode prose -->
<article class="prose dark:prose-invert">
  {{ .Content }}
</article>
```

### Typography Configuration

```css
/* Good: Custom prose styles in tailwind.css */
@theme {
  --prose-body: theme(colors.gray.700);
  --prose-headings: theme(colors.gray.900);
  --prose-links: theme(colors.brand.600);
  --prose-bold: theme(colors.gray.900);
  --prose-code: theme(colors.gray.900);
  --prose-pre-bg: theme(colors.gray.900);
}
```

## Component Patterns

### Button Variants

```html
<!-- Good: Extracted button component -->
{{ $baseClasses := "inline-flex items-center justify-center px-4 py-2 rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2" }}
{{ $variant := .variant | default "primary" }}

{{ $variantClasses := dict
  "primary" "bg-brand-600 text-white hover:bg-brand-700 focus:ring-brand-500"
  "secondary" "bg-gray-600 text-white hover:bg-gray-700 focus:ring-gray-500"
  "outline" "border-2 border-brand-600 text-brand-600 hover:bg-brand-50 focus:ring-brand-500"
}}

<button class="{{ $baseClasses }} {{ index $variantClasses $variant }}">
  {{ .text }}
</button>

<!-- Usage in templates -->
{{ partial "button.html" (dict "text" "Click me" "variant" "primary") }}
{{ partial "button.html" (dict "text" "Cancel" "variant" "outline") }}
```

### Alert Component

```html
<!-- Good: partials/alert.html -->
{{ $type := .type | default "info" }}
{{ $title := .title }}
{{ $content := .content }}

{{ $typeClasses := dict
  "info" "bg-blue-50 border-blue-200 text-blue-900"
  "success" "bg-green-50 border-green-200 text-green-900"
  "warning" "bg-yellow-50 border-yellow-200 text-yellow-900"
  "error" "bg-red-50 border-red-200 text-red-900"
}}

{{ $iconColors := dict
  "info" "text-blue-600"
  "success" "text-green-600"
  "warning" "text-yellow-600"
  "error" "text-red-600"
}}

<div class="border-l-4 p-4 {{ index $typeClasses $type }}" role="alert">
  <div class="flex">
    <div class="flex-shrink-0">
      <svg class="h-5 w-5 {{ index $iconColors $type }}" viewBox="0 0 20 20" fill="currentColor">
        <!-- Icon path -->
      </svg>
    </div>
    <div class="ml-3">
      {{ with $title }}
        <h3 class="text-sm font-medium">{{ . }}</h3>
      {{ end }}
      <div class="text-sm {{ if $title }}mt-2{{ end }}">
        {{ $content }}
      </div>
    </div>
  </div>
</div>
```

## Responsive Design

### Mobile-First Breakpoints

```html
<!-- Good: Mobile-first responsive classes -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
  <!-- Scales from 1 column → 2 → 3 → 4 -->
</div>

<h1 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold">
  <!-- Responsive typography -->
</h1>

<div class="p-4 sm:p-6 md:p-8 lg:p-10">
  <!-- Responsive spacing -->
</div>

<!-- Good: Hide/show at breakpoints -->
<div class="hidden lg:block">Desktop only</div>
<div class="block lg:hidden">Mobile only</div>
```

### Container Queries (Tailwind 4)

```css
/* Good: Container queries in Tailwind 4 */
@layer components {
  .card-container {
    container-type: inline-size;
  }
  
  .card-content {
    @apply p-4;
    
    @container (min-width: 400px) {
      @apply p-6;
    }
  }
}
```

## Dark Mode

### Dark Mode Setup

```html
<!-- Good: Dark mode toggle -->
<button class="p-2 rounded-lg bg-gray-200 dark:bg-gray-700"
        onclick="toggleDarkMode()">
  <svg class="w-5 h-5 hidden dark:block"><!-- moon icon --></svg>
  <svg class="w-5 h-5 block dark:hidden"><!-- sun icon --></svg>
</button>

<script>
function toggleDarkMode() {
  document.documentElement.classList.toggle('dark');
  localStorage.setItem('darkMode', 
    document.documentElement.classList.contains('dark')
  );
}

// Initialize
if (localStorage.getItem('darkMode') === 'true' || 
    (!localStorage.getItem('darkMode') && 
     window.matchMedia('(prefers-color-scheme: dark)').matches)) {
  document.documentElement.classList.add('dark');
}
</script>
```

### Dark Mode Utilities

```html
<!-- Good: Dark mode variants -->
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
  <h1 class="text-brand-600 dark:text-brand-400">Title</h1>
  <p class="text-gray-700 dark:text-gray-300">Content</p>
</div>

<article class="prose dark:prose-invert">
  {{ .Content }}
</article>
```

## Custom Utilities

### Utility Extraction

```css
/* Good: Custom utilities in tailwind.css */
@utility backdrop-blur-* {
  backdrop-filter: blur(*);
}

@utility text-balance {
  text-wrap: balance;
}

@utility text-pretty {
  text-wrap: pretty;
}

/* Usage in templates */
<h1 class="text-balance">{{ .Title }}</h1>
```

## Performance Optimization

### Purge Configuration

```css
/* Good: Content paths in CSS */
@source "../../layouts/**/*.html";
@source "../../content/**/*.md";

/* Tailwind 4 automatically scans these paths */
```

### Critical CSS Inlining

```html
<!-- Good: Inline critical CSS -->
{{ $criticalCSS := resources.Get "css/critical.css" | toCSS | postCSS | minify }}
<style>{{ $criticalCSS.Content | safeCSS }}</style>

<!-- Defer full stylesheet -->
{{ $fullCSS := resources.Get "css/tailwind.css" | toCSS | postCSS | minify | fingerprint }}
<link rel="stylesheet" 
      href="{{ $fullCSS.RelPermalink }}" 
      media="print"
      onload="this.media='all'">
```

## Alpine.js Integration

### Interactive Components

```html
<!-- Good: Alpine.js for interactivity -->
<div x-data="{ open: false }">
  <button @click="open = !open"
          class="px-4 py-2 bg-brand-600 text-white rounded-lg hover:bg-brand-700">
    Toggle
  </button>
  
  <div x-show="open"
       x-transition
       class="mt-4 p-4 bg-gray-100 rounded-lg">
    Content
  </div>
</div>

<!-- Good: Dropdown menu -->
<div x-data="{ open: false }" @click.away="open = false">
  <button @click="open = !open"
          class="px-4 py-2 bg-white border border-gray-300 rounded-lg">
    Menu
  </button>
  
  <div x-show="open"
       x-transition:enter="transition ease-out duration-100"
       x-transition:enter-start="opacity-0 scale-95"
       x-transition:enter-end="opacity-100 scale-100"
       class="absolute mt-2 w-48 bg-white rounded-lg shadow-lg">
    <!-- Menu items -->
  </div>
</div>
```

## Works Well With

- `hugo-theme` - Base Hugo theme structure and templating patterns
- `brand-yml` (Posit) - Apply consistent branding to Tailwind sites

## When to Use Me

Use this skill when:
- Setting up Tailwind CSS 4 with Hugo
- Using the new CSS-first configuration approach
- Need utility-first styling patterns for Hugo
- Want modern responsive and dark mode patterns
- Integrating Alpine.js for interactivity

**Do NOT use for:**
- Tailwind CSS 3 (different configuration approach)
- Component libraries (Tailwind UI, Headless UI)
- React/Vue integration (Hugo is server-rendered)

## Quick Reference

**Setup:** `npm install tailwindcss @tailwindcss/typography`

**Config:** CSS-first with `@theme` in tailwind.css

**Hugo Pipes:** CSS → PostCSS → minify → fingerprint

**Key classes:**
- Layout: `container mx-auto px-4`
- Grid: `grid grid-cols-1 md:grid-cols-3 gap-6`
- Flex: `flex flex-col lg:flex-row gap-4`
- Typography: `prose prose-lg dark:prose-invert`
- Colors: `bg-white dark:bg-gray-900`
