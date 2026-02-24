---
name: hugo-theme
description: Hugo theme structure, templating patterns, and content organization. Covers layouts, partials, shortcodes, data files, and Hugo-specific features. Framework-agnostic foundation for theme development.
license: CC-BY-4.0
compatibility: opencode
metadata:
  framework: hugo
  audience: web-developers
  focus: theme-structure
---

# Hugo Theme Development

Framework-agnostic patterns for Hugo theme structure, templating, and content organization.

## Theme Structure

Standard Hugo theme layout:

```
themes/mytheme/
├── archetypes/          # Content templates
│   └── default.md
├── assets/              # Source files processed by Hugo Pipes
│   ├── css/
│   ├── js/
│   └── images/
├── data/                # Data files (YAML, JSON, TOML)
├── i18n/                # Translation files
├── layouts/
│   ├── _default/        # Default templates
│   │   ├── baseof.html
│   │   ├── list.html
│   │   ├── single.html
│   │   └── summary.html
│   ├── partials/        # Reusable components
│   ├── shortcodes/      # Content shortcodes
│   └── index.html       # Homepage template
├── static/              # Static files (copied as-is)
│   ├── images/
│   └── fonts/
└── theme.toml           # Theme metadata
```

## Base Template (baseof.html)

### Template Structure

```html
<!-- Good: Flexible baseof with multiple blocks -->
<!DOCTYPE html>
<html lang="{{ .Site.Language.Lang }}">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    
    {{ partial "head/meta.html" . }}
    {{ partial "head/styles.html" . }}
    
    {{ block "head" . }}{{ end }}
  </head>
  
  <body class="{{ block "body-class" . }}{{ end }}">
    {{ partial "header.html" . }}
    
    {{ block "before-main" . }}{{ end }}
    
    <main id="main-content" role="main">
      {{ block "main" . }}{{ end }}
    </main>
    
    {{ block "after-main" . }}{{ end }}
    
    {{ partial "footer.html" . }}
    
    {{ partial "scripts.html" . }}
    {{ block "scripts" . }}{{ end }}
  </body>
</html>

<!-- Bad: Rigid structure without extension points -->
<!DOCTYPE html>
<html>
  <head>
    <title>{{ .Title }}</title>
  </head>
  <body>
    {{ .Content }}
  </body>
</html>
```

## Layout Templates

### List Template

```html
<!-- Good: layouts/_default/list.html -->
{{ define "main" }}
<div class="list-page">
  <header class="list-header">
    <h1>{{ .Title }}</h1>
    {{ with .Params.description }}
      <p class="description">{{ . }}</p>
    {{ end }}
  </header>
  
  <div class="list-content">
    {{ .Content }}
  </div>
  
  {{ if .Pages }}
  <div class="list-items">
    {{ range .Pages }}
      {{ .Render "summary" }}
    {{ end }}
  </div>
  
  {{ partial "pagination.html" . }}
  {{ end }}
</div>
{{ end }}

<!-- Bad: No structure, minimal functionality -->
{{ define "main" }}
  {{ range .Pages }}
    <h2>{{ .Title }}</h2>
    {{ .Content }}
  {{ end }}
{{ end }}
```

### Single Template

```html
<!-- Good: layouts/_default/single.html -->
{{ define "main" }}
<article class="single-page">
  <header class="article-header">
    <h1>{{ .Title }}</h1>
    
    {{ partial "article-meta.html" . }}
  </header>
  
  {{ if .Params.featured_image }}
    {{ partial "featured-image.html" . }}
  {{ end }}
  
  <div class="article-content">
    {{ .Content }}
  </div>
  
  {{ if .Params.tags }}
    {{ partial "tags.html" . }}
  {{ end }}
  
  <footer class="article-footer">
    {{ partial "article-navigation.html" . }}
  </footer>
</article>
{{ end }}

{{ define "head" }}
  {{ with .Description }}
    <meta name="description" content="{{ . }}">
  {{ end }}
  {{ partial "opengraph.html" . }}
{{ end }}
```

## Partial Templates

### Navigation Partial

```html
<!-- Good: partials/nav.html with menu support -->
<nav class="site-nav" role="navigation" aria-label="Main navigation">
  {{ $currentPage := . }}
  <ul class="nav-list">
    {{ range .Site.Menus.main }}
    <li class="nav-item{{ if .HasChildren }} has-dropdown{{ end }}">
      {{ $isActive := or ($currentPage.IsMenuCurrent "main" .) ($currentPage.HasMenuCurrent "main" .) }}
      
      <a href="{{ .URL | relLangURL }}"
         {{ if $isActive }}aria-current="page"{{ end }}
         {{ if .HasChildren }}aria-haspopup="true"{{ end }}>
        {{ .Pre }}
        {{ .Name }}
        {{ .Post }}
      </a>
      
      {{ if .HasChildren }}
      <ul class="dropdown-menu">
        {{ range .Children }}
        <li>
          <a href="{{ .URL | relLangURL }}">{{ .Name }}</a>
        </li>
        {{ end }}
      </ul>
      {{ end }}
    </li>
    {{ end }}
  </ul>
</nav>

<!-- Bad: Hardcoded links -->
<nav>
  <a href="/">Home</a>
  <a href="/about">About</a>
  <a href="/blog">Blog</a>
</nav>
```

### Pagination Partial

```html
<!-- Good: partials/pagination.html -->
{{ $paginator := .Paginator }}
{{ if gt $paginator.TotalPages 1 }}
<nav class="pagination" role="navigation" aria-label="Pagination">
  <ul class="pagination-list">
    {{ if $paginator.HasPrev }}
    <li>
      <a href="{{ $paginator.Prev.URL }}" 
         class="pagination-prev"
         aria-label="Previous page">
        ← Previous
      </a>
    </li>
    {{ end }}
    
    {{ range $paginator.Pagers }}
    <li>
      {{ if eq . $paginator }}
      <span class="pagination-current" aria-current="page">
        {{ .PageNumber }}
      </span>
      {{ else }}
      <a href="{{ .URL }}" aria-label="Go to page {{ .PageNumber }}">
        {{ .PageNumber }}
      </a>
      {{ end }}
    </li>
    {{ end }}
    
    {{ if $paginator.HasNext }}
    <li>
      <a href="{{ $paginator.Next.URL }}" 
         class="pagination-next"
         aria-label="Next page">
        Next →
      </a>
    </li>
    {{ end }}
  </ul>
</nav>
{{ end }}

<!-- Bad: No accessibility, basic functionality -->
<div>
  <a href="{{ .Paginator.Prev.URL }}">Prev</a>
  <a href="{{ .Paginator.Next.URL }}">Next</a>
</div>
```

### Metadata Partials

```html
<!-- Good: partials/head/meta.html -->
<title>
  {{- if .IsHome }}
    {{ .Site.Title }}
    {{ with .Site.Params.subtitle }} - {{ . }}{{ end }}
  {{- else }}
    {{ .Title }} | {{ .Site.Title }}
  {{- end }}
</title>

{{ with .Description }}
  <meta name="description" content="{{ . }}">
{{ else }}
  {{ with .Site.Params.description }}
    <meta name="description" content="{{ . }}">
  {{ end }}
{{ end }}

{{ with .Site.Params.author }}
  <meta name="author" content="{{ . }}">
{{ end }}

<link rel="canonical" href="{{ .Permalink }}">

<!-- Good: partials/opengraph.html -->
{{ $title := cond .IsHome .Site.Title .Title }}
<meta property="og:title" content="{{ $title }}">
<meta property="og:type" content="{{ if .IsPage }}article{{ else }}website{{ end }}">
<meta property="og:url" content="{{ .Permalink }}">

{{ with .Params.featured_image }}
  {{ $image := resources.Get . }}
  {{ if $image }}
    <meta property="og:image" content="{{ $image.Permalink }}">
  {{ end }}
{{ end }}

{{ with .Description }}
  <meta property="og:description" content="{{ . }}">
{{ end }}
```

## Shortcodes

### Figure Shortcode

```html
<!-- Good: layouts/shortcodes/figure.html -->
{{ $src := .Get "src" }}
{{ $alt := .Get "alt" }}
{{ $caption := .Get "caption" | default (.Inner | markdownify) }}
{{ $link := .Get "link" }}
{{ $class := .Get "class" }}

<figure{{ with $class }} class="{{ . }}"{{ end }}>
  {{ if $link }}
    <a href="{{ $link }}">
  {{ end }}
  
  {{ $image := resources.Get $src }}
  {{ if $image }}
    {{ $resized := $image.Resize "800x" }}
    <img src="{{ $resized.RelPermalink }}"
         alt="{{ $alt }}"
         loading="lazy"
         width="{{ $resized.Width }}"
         height="{{ $resized.Height }}">
  {{ else }}
    <img src="{{ $src | relURL }}" alt="{{ $alt }}">
  {{ end }}
  
  {{ if $link }}
    </a>
  {{ end }}
  
  {{ with $caption }}
    <figcaption>{{ . }}</figcaption>
  {{ end }}
</figure>

<!-- Usage: -->
<!-- {{< figure src="images/photo.jpg" alt="Description" caption="Photo caption" >}} -->
```

### Alert Shortcode

```html
<!-- Good: layouts/shortcodes/alert.html -->
{{ $type := .Get "type" | default "info" }}
{{ $title := .Get "title" }}

<div class="alert alert-{{ $type }}" role="alert">
  {{ with $title }}
    <strong class="alert-title">{{ . }}</strong>
  {{ end }}
  <div class="alert-content">
    {{ .Inner | markdownify }}
  </div>
</div>

<!-- Usage: -->
<!-- {{< alert type="warning" title="Important" >}}
This is a warning message with **markdown** support.
{{< /alert >}} -->
```

## Data Files

### Using Data Files

```yaml
# Good: data/authors.yaml
john_doe:
  name: "John Doe"
  bio: "Software developer and writer"
  avatar: "images/authors/john.jpg"
  social:
    twitter: "johndoe"
    github: "johndoe"

jane_smith:
  name: "Jane Smith"
  bio: "Designer and UX researcher"
  avatar: "images/authors/jane.jpg"
  social:
    twitter: "janesmith"
    linkedin: "janesmith"
```

```html
<!-- Good: Using data in templates -->
{{ $authorID := .Params.author }}
{{ $author := index .Site.Data.authors $authorID }}

{{ with $author }}
<div class="author-info">
  {{ with .avatar }}
    <img src="{{ . | relURL }}" alt="{{ $author.name }}" class="author-avatar">
  {{ end }}
  
  <div class="author-details">
    <h3 class="author-name">{{ .name }}</h3>
    <p class="author-bio">{{ .bio }}</p>
    
    {{ with .social }}
    <ul class="author-social">
      {{ range $platform, $handle := . }}
      <li>
        <a href="{{ partial "social-url.html" (dict "platform" $platform "handle" $handle) }}">
          {{ $platform }}
        </a>
      </li>
      {{ end }}
    </ul>
    {{ end }}
  </div>
</div>
{{ end }}

<!-- Bad: Hardcoded author info in content -->
Author: John Doe (john@example.com)
<!-- No reusability, no structure -->
```

## Content Organization

### Archetypes

```markdown
# Good: archetypes/blog.md
---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
author: ""
tags: []
categories: []
featured_image: ""
description: ""
---

Write your content here.

<!-- Bad: archetypes/default.md -->
---
title: "{{ .Name }}"
date: {{ .Date }}
---
```

### Front Matter Patterns

```yaml
# Good: Structured front matter
---
title: "Article Title"
date: 2024-01-15
lastmod: 2024-01-20
draft: false

# Taxonomy
tags: ["hugo", "webdev"]
categories: ["tutorials"]

# SEO
description: "Clear description for search engines and social media"
keywords: ["hugo", "static site", "tutorial"]

# Display options
featured_image: "images/featured.jpg"
featured_image_alt: "Description of featured image"
toc: true
comments: true

# Custom parameters
author: "john_doe"
reading_time: 10
---

# Bad: Minimal front matter
---
title: My Post
date: 2024-01-15
---
```

## Hugo Functions and Conditionals

### Conditional Rendering

```html
<!-- Good: Checking for content and parameters -->
{{ with .Params.featured_image }}
  {{ partial "featured-image.html" (dict "src" . "alt" $.Title "context" $) }}
{{ end }}

{{ if and .Params.show_toc (gt .WordCount 400) }}
  {{ partial "toc.html" . }}
{{ end }}

{{ $relatedPages := .Site.RegularPages.Related . | first 3 }}
{{ if $relatedPages }}
  {{ partial "related-posts.html" (dict "pages" $relatedPages "context" .) }}
{{ end }}

<!-- Bad: Assuming content exists -->
<img src="{{ .Params.featured_image }}">
<!-- Breaks if parameter doesn't exist -->
```

### Range and Filtering

```html
<!-- Good: Filtering and sorting -->
{{ $posts := where .Site.RegularPages "Section" "blog" }}
{{ $posts = where $posts "Params.featured" true }}
{{ $posts = $posts.ByDate.Reverse }}

{{ range first 5 $posts }}
  {{ partial "post-card.html" . }}
{{ end }}

<!-- Good: Grouping by taxonomy -->
{{ range .Site.Taxonomies.categories }}
  <h2>{{ .Page.Title }} ({{ .Count }})</h2>
  <ul>
    {{ range .Pages }}
      <li><a href="{{ .RelPermalink }}">{{ .Title }}</a></li>
    {{ end }}
  </ul>
{{ end }}

<!-- Bad: No filtering or organization -->
{{ range .Site.Pages }}
  {{ .Title }}
{{ end }}
```

## Multilingual Support

### Language Configuration

```yaml
# Good: config.yaml
languages:
  en:
    languageName: "English"
    weight: 1
    params:
      description: "English site description"
  no:
    languageName: "Norsk"
    weight: 2
    params:
      description: "Norsk nettsted beskrivelse"
```

```html
<!-- Good: Language switcher partial -->
{{ if .Site.IsMultiLingual }}
<nav class="language-switcher" aria-label="Language selector">
  <ul>
    {{ range .Site.Languages }}
      {{ if ne $.Site.Language . }}
      <li>
        <a href="{{ $.Page.RelPermalink | relLangURL .Lang }}"
           hreflang="{{ .Lang }}"
           lang="{{ .Lang }}">
          {{ .LanguageName }}
        </a>
      </li>
      {{ end }}
    {{ end }}
  </ul>
</nav>
{{ end }}
```

## RSS and Alternative Formats

### Custom RSS Template

```xml
<!-- Good: layouts/_default/rss.xml -->
{{- $pctx := . -}}
{{- if .IsHome -}}{{ $pctx = .Site }}{{- end -}}
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>{{ $pctx.Title }}</title>
    <link>{{ $pctx.Permalink }}</link>
    <description>{{ $pctx.Description }}</description>
    <language>{{ .Site.Language.Lang }}</language>
    <lastBuildDate>{{ now.Format "Mon, 02 Jan 2006 15:04:05 -0700" }}</lastBuildDate>
    <atom:link href="{{ .Permalink }}" rel="self" type="application/rss+xml" />
    
    {{ range first 20 (where .Site.RegularPages "Section" "blog") }}
    <item>
      <title>{{ .Title }}</title>
      <link>{{ .Permalink }}</link>
      <pubDate>{{ .Date.Format "Mon, 02 Jan 2006 15:04:05 -0700" }}</pubDate>
      <guid>{{ .Permalink }}</guid>
      <description>{{ .Summary | html }}</description>
    </item>
    {{ end }}
  </channel>
</rss>
```

## Theme Configuration

### Theme Parameters

```yaml
# Good: config.yaml with theme params
params:
  # Site metadata
  description: "Site description"
  author: "Author Name"
  
  # Features
  features:
    toc: true
    reading_time: true
    share_buttons: true
    comments: true
  
  # Navigation
  navigation:
    sticky: false
    show_logo: true
  
  # Footer
  footer:
    show_copyright: true
    show_powered_by: false
    custom_text: ""
```

## Works Well With

- `hugo-theme-bs5` - Bootstrap 5 specific setup and patterns
- `hugo-theme-tailwind4` - Tailwind CSS 4 specific setup and patterns
- `brand-yml` (Posit) - Apply consistent branding to Hugo sites

## When to Use Me

Use this skill when:
- Planning Hugo theme structure and layout
- Creating template hierarchy and partials
- Setting up content organization and archetypes
- Implementing Hugo-specific features (menus, taxonomies, multilingual)
- Need framework-agnostic theme patterns

**Then use framework-specific skills for:**
- CSS framework setup (Bootstrap, Tailwind)
- Asset bundling and processing
- Component styling

## Quick Reference

**Template hierarchy:** baseof.html → list.html/single.html → partials

**Blocks:** `{{ block "name" . }}{{ end }}` in baseof, `{{ define "name" }}` in child

**Partials:** `{{ partial "name.html" . }}` - reusable components

**Data access:** `.Site.Data.filename.key`

**Conditionals:** `{{ with }}`, `{{ if }}`, `{{ range }}`

**Filtering:** `where`, `first`, `ByDate`, `.Reverse`
