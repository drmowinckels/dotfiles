---
name: ggseg-ecosystem
description: Development patterns and architecture for the ggseg brain visualization ecosystem.
license: CC-BY-4.0
compatibility: opencode
metadata:
  language: R
  audience: ggseg-developers
  focus: style-preferences
---

## Package Overview

The ggseg ecosystem provides R tools for brain atlas visualization:

| Package | Purpose |
|---------|---------|
| `ggseg.formats` | Foundation: data structures, atlas classes, validation, FreeSurfer I/O |
| `ggseg` | 2D visualization via ggplot2 extension |
| `ggseg3d` | 3D visualization via Three.js/htmlwidgets |
| `ggsegExtra` | Atlas creation utilities requiring FreeSurfer |

**Dependency hierarchy:**
```
ggseg.formats (foundation)
├── ggseg (2D) ─────────────► sf, ggplot2, vctrs
├── ggseg3d (3D) ───────────► htmlwidgets, Three.js
└── ggsegExtra (utilities)
    └── Depends: ggseg.formats, ggseg3d, freesurfer, terra
```

## Design Philosophy

- **Unified atlas format**: Single `brain_atlas` class supports both 2D and 3D rendering
- **Type polymorphism**: Cortical, subcortical, and tract atlases share interface but differ in data storage
- **Tidyverse integration**: Pipe-friendly APIs, tibble-based data structures, dplyr verbs
- **ggplot2 extension pattern**: Custom ggproto classes for geoms, layers, positions
- **Validation-first**: Extensive input validation with informative cli error messages
- **Legacy compatibility**: Deprecated formats still supported with warnings

## Core Data Structures

### brain_atlas (unified format in ggseg.formats)

The primary atlas class supporting 2D and 3D rendering:

```r
brain_atlas(
  atlas = "dk",                    # atlas name (single string)
  type = "cortical",               # "cortical", "subcortical", or "tract"
  core = data.frame(               # required columns: hemi, region, label
    hemi = c("lh", "rh"),
    region = c("bankssts", "bankssts"),
    label = c("lh_bankssts", "rh_bankssts")
  ),
  data = cortical_data(...),       # type-specific data container
  palette = c(lh_bankssts = "#FF0000", ...)  # named hex colors (optional)
)
```

**Type-specific data containers:**

| Type | Container | Contents |
|------|-----------|----------|
| cortical | `cortical_data()` | `sf` (2D geometry), `vertices` (list-column of 0-indexed integers) |
| subcortical | `subcortical_data()` | `sf` (optional), `meshes` (list-column with vertices/faces data frames) |
| tract | `tract_data()` | `sf` (optional), `meshes` (tube meshes with optional tangent metadata) |

**Design rationale:**
- `core` separates metadata from rendering data
- `data` container enforces type-appropriate validation
- `palette` keeps colors with atlas rather than requiring user specification
- Labels in `data` must match labels in `core` (cross-validated)

### ggseg_atlas (ggseg package)

Tibble-based class for 2D plotting with nested `brain_polygon` data:

```r
# Structure: tibble with class "ggseg_atlas"
tibble(
  atlas = "dk",
  type = "cortical",
  hemi = c("left", "right"),
  view = c("lateral", "medial"),
  region = "bankssts",
  label = "lh_bankssts",
  ggseg = list(<brain_polygon>)  # nested polygon coordinates
)

# brain_polygon is a vctrs custom vector class
# Format: < p:NUM - v:NUM > (polygons and vertices)
```

**Conversion between formats:**
```r
as_ggseg_atlas(brain_atlas)  # brain_atlas → ggseg_atlas
as_brain_atlas(ggseg_atlas)  # ggseg_atlas → brain_atlas
```

### Brain Meshes

fsaverage5 resolution: 10,242 vertices, 20,480 faces per hemisphere

Stored as named list with `{hemi}_{surface}` keys (e.g., `lh_inflated`, `rh_white`).
Each mesh contains `vertices` (x, y, z data frame) and `faces` (i, j, k triangle indices).

## Rendering Modes

### 2D (ggseg)

Uses sf geometry with custom ggplot2 layer:
- `LayerBrain` merges user data with atlas via `brain_join()`
- `PositionBrain` handles view arrangement (formula-based)
- `GeomBrain` delegates to `GeomPolygon` for rendering

### 3D Cortical (ggseg3d)

Vertex-based coloring on shared brain meshes:
- Single mesh per hemisphere (memory efficient)
- Colors assigned per-vertex via `vertices_to_colors()`
- `colorMode = "vertexcolor"` in Three.js
- Edge detection via `find_boundary_edges()`

### 3D Subcortical (ggseg3d)

Per-region mesh rendering:
- Separate mesh per brain structure
- `colorMode = "facecolor"` in Three.js
- Marching cubes mesh generation from volumes

### 3D Tract (ggseg3d)

Orientation-based coloring on tube meshes:
- RGB encoding: R=left-right, G=anterior-posterior, B=superior-inferior
- `tangents_to_colors()` converts tangent vectors to colors
- Centerline extraction from streamlines

## Coding Style

### Error Messaging with cli

All user-facing errors and warnings use `cli` package with semantic formatting:

```r
cli::cli_abort(c(
  "Atlas must be a brain_atlas object",
  "i" = "Got class: {.cls {class(atlas)}}",
  "x" = "Use {.fn as_brain_atlas} to convert"
))

cli::cli_warn(c(
  "Some regions not found in atlas",
  "i" = "Missing: {.val {missing_regions}}"
))
```

### S3 Class Conventions

- Use S3 classes exclusively (no S4)
- Implement `print()`, `format()`, `as.data.frame()` methods
- Validation functions named `validate_*()` or `is_*()` predicates
- Coercion via `as_*()` generics with methods for common types

### ggplot2 Extension Pattern

```r
# Geom via ggproto
GeomBrain <- ggproto("GeomBrain", Geom,
  default_aes = aes(...),
  draw_panel = function(...) { ... }
)

# Custom layer class for data preprocessing
LayerBrain <- ggproto("LayerBrain", ggplot2:::Layer,
  setup_layer = function(self, data, plot) { ... }
)

# Position transformation
PositionBrain <- ggproto("PositionBrain", Position,
  compute_layer = function(self, data, params, layout) { ... }
)
```

### vctrs Custom Vectors

Used for `brain_polygon` class to efficiently store nested coordinate data:

```r
new_brain_polygon <- function(x = list()) {
  vctrs::new_vctr(x, class = "brain_polygon")
}

format.brain_polygon <- function(x, ...) {
 sprintf("< p:%d - v:%d >", n_polygons, n_vertices)
}
```

### Data Manipulation

Heavy use of tidyverse patterns:
- `dplyr::left_join()` for merging user data with atlas
- `tidyr::nest()`/`unnest()` for grouped polygon data
- Pipe-friendly function design (return modified input)
- Use `.data$column` pronoun in dplyr verbs

### htmlwidgets Pattern (ggseg3d)

```r
# Widget creation
ggseg3d <- function(...) {
  x <- list(meshes = ..., options = ...)
  htmlwidgets::createWidget("ggseg3d", x, ...)
}

# Pipe-friendly modifications
set_background <- function(p, colour) {
  p$x$options$backgroundColor <- col2hex(colour)
  p
}

# Shiny bindings
ggseg3dOutput <- function(outputId, ...) {
  htmlwidgets::shinyWidgetOutput(outputId, "ggseg3d", ...)
}
```

## Testing Patterns

testthat files should mirror R source files, and test the functions in the respective source file.
Uses testthat 3rd edition with `describe/it` blocks:

```r
describe("brain_atlas()", {
  it("creates valid atlas from components", {
    atlas <- brain_atlas(
      atlas = "test",
      type = "cortical",
      core = data.frame(hemi = "lh", region = "test", label = "lh_test"),
      data = cortical_data(vertices = data.frame(
        label = "lh_test",
        vertices = I(list(0:10))
      ))
    )
    expect_s3_class(atlas, "brain_atlas")
    expect_equal(atlas_type(atlas), "cortical")
  })

  it("errors on invalid type", {
    expect_error(brain_atlas(..., type = "invalid"), "type must be")
  })
})
```

**Visual regression tests (ggseg):**
```r
it("renders correctly", {
  p <- ggplot() + geom_brain(atlas = dk)
  vdiffr::expect_doppelganger("dk-lateral", p)
})
```

**Widget testing (ggseg3d):**
```r
it("supports pipe chaining", {
  p <- ggseg3d(atlas = dk) |>
    set_background("black") |>
    pan_camera("left lateral")
  expect_equal(p$x$options$backgroundColor, "#000000")
})
```

**System-dependent tests:**
```r
it("requires FreeSurfer", {
  skip_if_no_freesurfer()
  # test code
})
```

## Key Patterns

### Vertex Index Mapping

Vertices are 0-indexed integers referencing positions in brain meshes:

```r
vertices_to_colors <- function(atlas_data, n_vertices, na_colour) {
  vertex_colors <- rep(na_colour, n_vertices)
  for (i in seq_len(nrow(atlas_data))) {
    idx <- atlas_data$vertices[[i]] + 1L
    idx <- idx[idx >= 1 & idx <= n_vertices]
    vertex_colors[idx] <- atlas_data$colour[i]
  }
  vertex_colors
}
```

### Position Formula Syntax (ggseg)

```r
# Arrange by hemisphere (rows) and view (columns)
geom_brain(atlas = dk, position = position_brain(hemi ~ view))

# Stack views vertically
geom_brain(atlas = dk, position = position_brain(view ~ .))

# Grid layout
geom_brain(atlas = dk, position = position_brain(hemi + view ~ .))
```

### Data Merge Strategy

User data is merged with atlas using common columns:
- Full outer join preserves all atlas regions
- Warns on unmatched user data (likely typos)
- Handles grouped data frames

```r
brain_join <- function(atlas_data, user_data) {
  common_cols <- intersect(names(atlas_data), names(user_data))
  if (length(common_cols) == 0) {
    cli::cli_abort("No common columns for joining")
  }
  dplyr::full_join(atlas_data, user_data, by = common_cols)
}
```

### Atlas Type Detection

```r
is_unified_atlas <- function(atlas) {
  inherits(atlas, "brain_atlas") &&
    !is.null(atlas$data$vertices)
}

is_mesh_atlas <- function(atlas) {
  inherits(atlas, "brain_atlas") &&
    !is.null(atlas$data$meshes)
}

is_tract_atlas <- function(atlas) {
  inherits(atlas, "brain_atlas") &&
    atlas$type == "tract"
}
```

## Common Workflows

### Plot unified atlas in 2D

```r
library(ggseg)
library(ggplot2)

ggplot() +
  geom_brain(atlas = dk, position = position_brain(hemi ~ view)) +
  theme_brain()
```

### Plot unified atlas in 3D

```r
library(ggseg3d)

ggseg3d(atlas = dk, hemisphere = c("left", "right")) |>
  pan_camera("left lateral") |>
  add_glassbrain("right", opacity = 0.1)
```

### Add user data

```r
my_data <- data.frame(
  region = c("bankssts", "fusiform", "precentral"),
  value = c(0.5, 0.8, 0.3)
)

# 2D
ggplot(my_data) +
  geom_brain(atlas = dk, aes(fill = value)) +
  scale_fill_viridis_c()

# 3D
ggseg3d(.data = my_data, atlas = dk, colour = "value")
```

### Create atlas from FreeSurfer

```r
library(ggsegExtra)

# Cortical from annotation
atlas <- make_cortical_atlas(
  annot = "aparc",
  subject = "fsaverage5",
  subjects_dir = freesurfer::fs_dir()
)

# Subcortical from volume
atlas <- make_subcortical_atlas(
  volume = "aseg.mgz",
  color_lut = freesurfer::fs_lut()
)

# Tract from tractography
atlas <- make_tract_atlas(
  tracts_dir = "path/to/trk_files",
  output_dir = "output"
)
```

### Convert and validate atlases

```r
library(ggseg.formats)

# Check atlas type
if (is_brain_atlas(atlas)) {
  type <- atlas_type(atlas)
  regions <- brain_regions(atlas)
  labels <- brain_labels(atlas)
}

# Convert between formats
ggseg_atlas <- as_ggseg_atlas(brain_atlas)
brain_atlas <- as_brain_atlas(ggseg_atlas)

# Extract data for custom processing
sf_data <- atlas_sf(atlas)
vertices <- atlas_vertices(atlas)
meshes <- atlas_meshes(atlas)
```

## System Requirements

**For atlas creation (ggsegExtra):**
- FreeSurfer (annotation files, surface meshes, mri_convert)
- ImageMagick (image processing for 2D geometry)
- Chrome/Chromium (webshot rendering)
- fsaverage5 template (shipped with FreeSurfer)

**For visualization only:**
- No external dependencies required
- Pre-built atlases available via `install_ggseg_atlas()`

**System check:**
```r
ggsegExtra::setup_sitrep()
```
