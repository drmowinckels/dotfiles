---
name: hugo-site
description: Hugo static site development patterns for R-Ladies websites with Bootstrap 5, npm-managed dependencies, and semantic CSS. Focus on R-Ladies organizational patterns and migration from Bootstrap 4.
license: CC-BY-4.0
compatibility: opencode
metadata:
  framework: hugo
  css-framework: bootstrap-5
  organization: r-ladies
---

# Hugo Site Development - R-Ladies Patterns

Hugo development patterns specific to R-Ladies Global website infrastructure and organizational needs.

## Project Structure

Standard R-Ladies Hugo site layout:

```
site/
├── archetypes/          # Content templates
├── assets/
│   ├── scss/            # Bootstrap 5 + custom styles
│   └── js/              # JavaScript bundles
├── content/             # Markdown content
│   ├── directory/       # Chapter directory listings
│   ├── events/          # Event pages
│   └── blog/            # Blog posts
├── data/                # Data files (chapters, events, metadata)
├── layouts/
│   ├── partials/        # Reusable components
│   ├── shortcodes/      # Content shortcodes
│   └── _default/        # Base templates
├── static/              # Static assets (images, fonts)
├── package.json         # npm dependencies
├── package-lock.json
└── config.yaml          # Hugo configuration
```

## npm Dependency Management

### Migration from CDN to npm

```json
// Good: package.json with pinned versions
{
  "name": "rladies-site",
  "private": true,
  "dependencies": {
    "@fortawesome/fontawesome-free": "^6.4.0",
    "bootstrap": "^5.3.0",
    "fullcalendar": "^6.1.0",
    "@amcharts/amcharts5": "^5.3.0"
  },
  "scripts": {
    "sync": "node scripts/sync-assets.js"
  }
}

// Bad: No version control, CDN links in templates
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
<!-- Breaks when CDN is down, no version pinning -->
```

### Asset Sync Script Pattern

```javascript
// Good: scripts/sync-assets.js
const fs = require('fs');
const path = require('path');

const syncAssets = () => {
  // Copy from node_modules to static/
  const assets = [
    {
      from: 'node_modules/bootstrap/dist/css/bootstrap.min.css',
      to: 'static/css/bootstrap.min.css'
    },
    {
      from: 'node_modules/@fortawesome/fontawesome-free/css/all.min.css',
      to: 'static/css/fontawesome.min.css'
    },
    {
      from: 'node_modules/@fortawesome/fontawesome-free/webfonts',
      to: 'static/webfonts',
      isDirectory: true
    }
  ];

  assets.forEach(asset => {
    const fromPath = path.join(__dirname, '..', asset.from);
    const toPath = path.join(__dirname, '..', asset.to);
    
    if (asset.isDirectory) {
      fs.cpSync(fromPath, toPath, { recursive: true });
    } else {
      fs.copyFileSync(fromPath, toPath);
    }
    
    console.log(`✓ Synced ${asset.from}`);
  });
};

syncAssets();

// Bad: Manual copying without automation
// Leads to version drift and missing updates
```

## Bootstrap 5 Migration Patterns

### Navbar Updates

```html
<!-- Good: Bootstrap 5 navbar -->
<nav class="navbar navbar-expand-lg navbar-light bg-light">
  <div class="container-fluid">
    <button class="navbar-toggler" type="button" 
            data-bs-toggle="collapse" 
            data-bs-target="#navbarNav">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navbarNav">
      <ul class="navbar-nav ms-auto">
        <li class="nav-item">
          <a class="nav-link" href="/about">About</a>
        </li>
      </ul>
    </div>
  </div>
</nav>

<!-- Bad: Bootstrap 4 data attributes (won't work in BS5) -->
<nav class="navbar navbar-expand-lg">
  <button data-toggle="collapse" data-target="#navbarNav">
    <!-- data-toggle and data-target are BS4 syntax -->
  </button>
</nav>
```

### Utility Class Updates

```html
<!-- Good: Bootstrap 5 utilities -->
<div class="d-flex justify-content-between align-items-center mb-3">
  <h2 class="fw-bold text-primary">Title</h2>
  <span class="badge bg-success">New</span>
</div>

<!-- Bad: Bootstrap 4 classes that changed -->
<div class="d-flex justify-content-between align-items-center mb-3">
  <h2 class="font-weight-bold text-primary">Title</h2>
  <span class="badge badge-success">New</span>
  <!-- font-weight-bold → fw-bold -->
  <!-- badge-success → bg-success -->
</div>
```

## R-Ladies Directory Patterns

### Chapter Card Layout

```html
<!-- Good: Semantic card structure for chapters -->
<div class="row g-4">
  {{ range .Site.Data.chapters }}
  <div class="col-12 col-md-6 col-lg-4">
    <div class="card h-100 shadow-sm hover-lift">
      <div class="card-body d-flex flex-column">
        <h5 class="card-title">{{ .name }}</h5>
        <p class="card-text text-muted">{{ .city }}, {{ .country }}</p>
        
        <div class="mt-auto pt-3">
          {{ if .meetup_url }}
          <a href="{{ .meetup_url }}" class="btn btn-sm btn-outline-primary me-2">
            <i class="fab fa-meetup"></i> Meetup
          </a>
          {{ end }}
          
          {{ if .twitter }}
          <a href="https://twitter.com/{{ .twitter }}" class="btn btn-sm btn-outline-info">
            <i class="fab fa-twitter"></i> Twitter
          </a>
          {{ end }}
        </div>
      </div>
    </div>
  </div>
  {{ end }}
</div>

<!-- Bad: Unstructured layout without semantic HTML -->
<div>
  {{ range .Site.Data.chapters }}
  <div style="float:left; width:33%">
    <p><b>{{ .name }}</b></p>
    <a href="{{ .meetup_url }}">Meetup</a>
    <!-- No semantic structure, inline styles, poor responsive -->
  </div>
  {{ end }}
</div>
```

### Directory Filtering (JavaScript)

```javascript
// Good: Vanilla JS filtering without jQuery
const filterDirectory = () => {
  const searchInput = document.getElementById('chapter-search');
  const countryFilter = document.getElementById('country-filter');
  const cards = document.querySelectorAll('.chapter-card');
  
  const filterCards = () => {
    const searchTerm = searchInput.value.toLowerCase();
    const selectedCountry = countryFilter.value;
    
    cards.forEach(card => {
      const name = card.dataset.name.toLowerCase();
      const country = card.dataset.country;
      
      const matchesSearch = name.includes(searchTerm);
      const matchesCountry = !selectedCountry || country === selectedCountry;
      
      card.style.display = (matchesSearch && matchesCountry) ? 'block' : 'none';
    });
  };
  
  searchInput.addEventListener('input', filterCards);
  countryFilter.addEventListener('change', filterCards);
};

document.addEventListener('DOMContentLoaded', filterDirectory);

// Bad: jQuery dependency for simple filtering
$('#chapter-search').on('input', function() {
  $('.chapter-card').each(function() {
    // Unnecessary jQuery overhead
  });
});
```

## FullCalendar Integration

### Event Feed Setup

```javascript
// Good: FullCalendar with timezone handling
document.addEventListener('DOMContentLoaded', function() {
  const calendarEl = document.getElementById('calendar');
  
  const calendar = new FullCalendar.Calendar(calendarEl, {
    initialView: 'dayGridMonth',
    timeZone: 'UTC',  // Store all events in UTC
    headerToolbar: {
      left: 'prev,next today',
      center: 'title',
      right: 'dayGridMonth,timeGridWeek,listMonth'
    },
    events: '/events/feed.ics',  // iCal feed
    eventDidMount: function(info) {
      // Add Bootstrap tooltip for event details
      new bootstrap.Tooltip(info.el, {
        title: info.event.extendedProps.description,
        placement: 'top',
        trigger: 'hover',
        container: 'body'
      });
    }
  });
  
  calendar.render();
});

// Bad: No timezone handling, missing user experience features
new FullCalendar.Calendar(document.getElementById('calendar'), {
  events: '/events.json'
  // Missing timezone, poor UX, no tooltips
}).render();
```

### iCal Feed Generation (Hugo)

```go-html-template
<!-- Good: layouts/_default/list.ics.html -->
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//R-Ladies Global//Events//EN
CALSCALE:GREGORIAN
METHOD:PUBLISH
{{ range where .Site.RegularPages "Section" "events" }}
BEGIN:VEVENT
UID:{{ .File.UniqueID }}@rladies.org
DTSTAMP:{{ .Date.Format "20060102T150405Z" }}
DTSTART:{{ .Params.event_date | time.Format "20060102T150405Z" }}
DTEND:{{ .Params.event_end | time.Format "20060102T150405Z" }}
SUMMARY:{{ .Title }}
DESCRIPTION:{{ .Summary | plainify }}
LOCATION:{{ .Params.location | default "Online" }}
URL:{{ .Permalink }}
END:VEVENT
{{ end }}
END:VCALENDAR
```

## Semantic CSS Architecture

### Component-Based Styles

```scss
// Good: assets/scss/components/_chapter-card.scss
.chapter-card {
  transition: transform 0.2s ease-in-out;
  
  &:hover {
    transform: translateY(-4px);
  }
  
  .card-title {
    color: var(--bs-primary);
    font-weight: 600;
  }
  
  .social-links {
    display: flex;
    gap: 0.5rem;
    
    .btn {
      flex: 1;
    }
  }
}

// Bad: Utility-only approach or inline styles
.blue-card { color: blue; }
.mr-10 { margin-right: 10px; }
<!-- Over-reliance on utilities, no component structure -->
```

### SCSS Organization

```scss
// Good: assets/scss/main.scss structure
// 1. Bootstrap customization
@import "variables";  // Custom Bootstrap variables
@import "~bootstrap/scss/bootstrap";

// 2. Components
@import "components/navbar";
@import "components/chapter-card";
@import "components/event-calendar";
@import "components/footer";

// 3. Layouts
@import "layouts/directory";
@import "layouts/blog";

// 4. Utilities (minimal custom utilities)
@import "utilities/hover-effects";

// Bad: Single large CSS file or scattered styles
// - Hard to maintain
// - No clear organization
// - Difficult to find components
```

## Data File Patterns

### Chapter Data Structure

```yaml
# Good: data/chapters/oslo.yaml
name: "R-Ladies Oslo"
city: "Oslo"
country: "Norway"
region: "Europe"
status: "active"
founded: "2018-03-15"

social:
  meetup: "rladies-oslo"
  twitter: "RLadiesOslo"
  github: "rladies-oslo"
  email: "oslo@rladies.org"

coordinates:
  lat: 59.9139
  lon: 10.7522

organizers:
  - name: "Organizer Name"
    role: "Lead"

# Bad: Inconsistent structure across chapters
name: "R-Ladies Oslo"
meetup_url: "https://meetup.com/rladies-oslo"  # Full URL instead of handle
twitter: "@RLadiesOslo"  # Includes @ symbol inconsistently
# Missing standardized fields
```

## Responsive Layout Patterns

```html
<!-- Good: Mobile-first responsive grid -->
<div class="container">
  <div class="row gy-4">
    <div class="col-12 col-sm-6 col-md-4 col-lg-3">
      <!-- Card content -->
    </div>
  </div>
</div>

<!-- With responsive utilities -->
<nav class="d-flex flex-column flex-lg-row align-items-start align-items-lg-center">
  <!-- Vertical on mobile, horizontal on desktop -->
</nav>

<!-- Bad: Fixed widths or desktop-first -->
<div style="width: 300px">
  <!-- Breaks on mobile -->
</div>
```

## Works Well With

- `brand-yml` (Posit) - Apply consistent branding using brand.yml files for Quarto/Shiny integration
- `r-package` - When building Hugo sites for R package documentation

## When to Use Me

Use this skill when:
- Working on R-Ladies Global website or chapter sites
- Migrating Hugo sites from Bootstrap 4 to Bootstrap 5
- Setting up npm-based asset management for Hugo
- Implementing directory/calendar features for community organizations
- Need patterns for event feeds and chapter management

**Do NOT use for:**
- General Hugo basics (covered in Hugo documentation)
- Quarto sites (use Posit `brand-yml` skill instead)
- Non-community organization sites

## Quick Reference

**npm workflow:** `npm install` → `npm run sync` → Hugo build

**Bootstrap 5 key changes:**
- `data-toggle` → `data-bs-toggle`
- `font-weight-bold` → `fw-bold`
- `badge-*` → `bg-*`
- `ml-*/mr-*` → `ms-*/me-*`

**R-Ladies patterns:**
- Card-based directory layouts
- FullCalendar with iCal feeds
- Semantic component structure
- Vanilla JS for interactivity