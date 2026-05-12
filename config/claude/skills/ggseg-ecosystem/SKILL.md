---
name: ggseg-ecosystem
description: Development patterns and architecture for the ggsegverse brain visualization ecosystem.
license: CC-BY-4.0
compatibility: opencode
metadata:
  language: R
  audience: ggseg-developers
  focus: style-preferences
---

## Package Overview

The **ggsegverse** (Gross Geometry Brain Segmentation Universe) provides R tools for brain atlas visualization. The GitHub organisation is `ggsegverse` and the r-universe is at `https://ggsegverse.r-universe.dev`.

| Package | Purpose |
|---------|---------|
| `ggseg.formats` | Foundation: data structures, atlas classes, validation, FreeSurfer I/O |
| `ggseg` | 2D visualization via ggplot2 extension |
| `ggseg3d` | 3D visualization via Three.js/htmlwidgets |
| `ggseg.meshes` | Additional brain surface meshes (pial, white, sphere, smoothwm, orig, SUIT flatmap) |
| `ggseg.extra` | Atlas creation pipelines requiring FreeSurfer |

**Dependency hierarchy:**
```
ggseg.formats (foundation) ─── ships: inflated mesh, SUIT 3D pial mesh
├── ggseg (2D) ──────────────► sf, ggplot2, vctrs
├── ggseg3d (3D) ────────────► htmlwidgets, Three.js
│   └── Suggests: ggseg.meshes (pial, white, semi-inflated, sphere, smoothwm, orig, SUIT flat)
├── ggseg.meshes (meshes) ──► no hard deps, data-only package
└── ggseg.extra (utilities)
    └── Depends: ggseg.formats, ggseg3d, freesurfer, terra
```

## Design Philosophy

- **Unified atlas format**: Single `brain_atlas` class supports both 2D and 3D rendering
- **Type polymorphism**: Cortical, subcortical, cerebellar, and tract atlases share interface but differ in data storage
- **Tidyverse integration**: Pipe-friendly APIs, tibble-based data structures, dplyr verbs
- **ggplot2 extension pattern**: Custom ggproto classes for geoms, layers, positions
- **Validation-first**: Extensive input validation with informative cli error messages
- **Legacy compatibility**: Deprecated formats still supported with warnings
- **Mesh separation**: Brain meshes are split across packages by role — inflated in ggseg.formats (always needed), additional surfaces in ggseg.meshes (optional)

## Core Data Structures

### brain_atlas (unified format in ggseg.formats)

The primary atlas class supporting 2D and 3D rendering:

```r
brain_atlas(
  atlas = "dk",                    # atlas name (single string)
  type = "cortical",               # "cortical", "subcortical", "cerebellar", or "tract"
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
| cerebellar | `cerebellar_data()` | `sf` (flatmap geometry), `vertices` (0-indexed into SUIT mesh) |
| tract | `tract_data()` | `sf` (optional), centerlines + tangents for tube mesh generation |

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

**Mesh storage across packages:**

| Surface | Package | Resolution | Access function |
|---------|---------|------------|-----------------|
| inflated | `ggseg.formats` | 10,242v / 20,480f per hemi | `get_brain_mesh("lh", "inflated")` |
| SUIT 3D pial | `ggseg.formats` | 30,013v / 57,665f | `get_cerebellar_mesh()` |
| pial | `ggseg.meshes` | 10,242v / 20,480f per hemi | `get_cortical_mesh("lh", "pial")` |
| white | `ggseg.meshes` | 10,242v / 20,480f per hemi | `get_cortical_mesh("lh", "white")` |
| semi-inflated | `ggseg.meshes` | 10,242v / 20,480f per hemi | `get_cortical_mesh("lh", "semi-inflated")` |
| sphere | `ggseg.meshes` | 10,242v / 20,480f per hemi | `get_cortical_mesh("lh", "sphere")` |
| smoothwm | `ggseg.meshes` | 10,242v / 20,480f per hemi | `get_cortical_mesh("lh", "smoothwm")` |
| orig | `ggseg.meshes` | 10,242v / 20,480f per hemi | `get_cortical_mesh("lh", "orig")` |
| SUIT flatmap | `ggseg.meshes` | 28,935v / 56,588f | `get_cerebellar_flatmap()` |

All cortical meshes are fsaverage5 resolution. Each mesh is a list with `vertices` (data.frame: x, y, z) and `faces` (data.frame: i, j, k).

**Mesh resolution in ggseg3d** — `resolve_brain_mesh()` is the single entry point:
- `"inflated"` → delegates to `ggseg.formats::get_brain_mesh()`
- All other surfaces → delegates to `ggseg.meshes::get_cortical_mesh()` (Suggests dependency; informative error if not installed)
- Custom meshes can be passed via `brain_meshes` argument

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
- Mesh decimation via `Rvcg::vcgQEdecim()` (cortical meshes cannot be decimated)

### 3D Cerebellar (ggseg3d)

Vertex-based coloring on shared SUIT mesh:
- Same pattern as cortical but with 0-based face indices (converted at render time)
- Cap vertices (28,935–30,012) render as grey background
- SUIT flatmap available in ggseg.meshes for 2D cerebellar visualization

### 3D Tract (ggseg3d)

Orientation-based coloring on tube meshes:
- RGB encoding: R=left-right, G=anterior-posterior, B=superior-inferior
- `tangents_to_colors()` converts tangent vectors to colors
- Tube meshes generated at render time via parallel transport frames

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

ggseg3d(atlas = dk(), hemisphere = c("left", "right")) |>
  pan_camera("left lateral") |>
  add_glassbrain("right", opacity = 0.1)
```

### Render on different surfaces

```r
library(ggseg3d)

# Requires ggseg.meshes package
ggseg3d(atlas = dk(), surface = "pial") |>
  pan_camera("left lateral")

ggseg3d(atlas = dk(), surface = "white") |>
  pan_camera("left lateral")
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
ggseg3d(.data = my_data, atlas = dk(), colour = "value")
```

### Create atlas from FreeSurfer

```r
library(ggseg.extra)

# Cortical from annotation
atlas <- create_cortical_atlas(
  annot = "aparc",
  subject = "fsaverage5",
  subjects_dir = freesurfer::fs_subj_dir()
)

# Subcortical from volume
atlas <- create_subcortical_atlas(
  volume = "aseg.mgz",
  color_lut = freesurfer::fs_lut()
)

# Cerebellar from volume (SUIT-based)
atlas <- create_cerebellar_from_volume(
  parcellation = "cerebellar_atlas.nii.gz",
  label_table = label_df
)

# Whole-brain from NIfTI volume
atlas <- create_wholebrain_atlas(
  parcellation = "atlas.nii.gz",
  label_table = label_df
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

# Convert legacy atlases
atlas <- convert_legacy_brain_atlas(old_atlas)
```

## Atlas Creation Pipelines (ggseg.extra)

| Pipeline | Function | Input | Output |
|----------|----------|-------|--------|
| Cortical | `create_cortical_atlas()` | FreeSurfer `.annot` | vertex-indexed atlas |
| Subcortical | `create_subcortical_atlas()` | Volume `.mgz`/`.nii` | per-region mesh atlas |
| Cerebellar | `create_cerebellar_from_volume()` | NIfTI in MNI space | SUIT vertex-indexed atlas |
| Tract | `create_tract_atlas()` | Tractography files | centerline-based atlas |
| Whole-brain | `create_wholebrain_atlas()` | NIfTI volume | mixed cortical+subcortical |

Key implementation details:
- Subcortical meshes can be decimated via `Rvcg::vcgQEdecim()` (default 50%)
- Cortical meshes CANNOT be decimated (shared vertex indices would break)
- Whole-brain pipeline uses `mri_vol2surf` with `--projfrac-max 0 1 0.1` for 100% coverage
- Cerebellar pipeline uses SUIT deformation fields for MNI→SUIT space transformation

## Package Infrastructure

All ggsegverse packages follow a consistent setup:

**GitHub Actions (6 workflows):**
- `R-CMD-check.yaml` — multi-platform matrix (macOS, Windows, Ubuntu x3)
- `code-quality.yaml` — lintr + goodpractice with PR comments
- `test-coverage.yaml` — covr with self-hosted coverage badge
- `pkgdown.yaml` — site build + gh-pages deploy
- `render-readme.yaml` — quarto-based README rendering
- `rhub.yaml` — manual R-hub checks

**pkgdown:** Uses `ggseg.docs` template package (`Config/Needs/website: ggsegverse/ggseg.docs`)

**README pattern:** `README.Rmd` with `output: github_document`, badges block, install from r-universe, usage examples, citation, funding section.

## System Requirements

**For atlas creation (ggseg.extra):**
- FreeSurfer (annotation files, surface meshes, mri_convert, mri_vol2surf)
- fsaverage5 template (shipped with FreeSurfer)

**For visualization only:**
- No external dependencies required
- Pre-built atlases available through the ggsegverse r-universe

**For mesh rebuilding (ggseg.meshes data-raw):**
- FreeSurfer + `freesurferformats` R package (cortical surfaces)
- `gifti` R package (SUIT flatmap)

## CRAN Submission Order

Packages must be submitted in dependency order. Packages within the same tier can be submitted in parallel.

| Tier | Package(s) | Blocked by |
|------|-----------|------------|
| 1 | `ggseg.formats` | — |
| 2 | `ggseg.meshes`, `ggseg.docs` | `ggseg.formats` (Suggests) |
| 3 | `ggseg`, `ggseg3d` | `ggseg.formats` (Imports) |
| 4 | `ggseg.extra` | `ggseg.formats` + `ggseg3d` (Imports) |
| 5 | `ggsegverse` | all core packages (Imports) |

Atlas packages (ggsegDKT, ggsegYeo2011, etc.) depend on `ggseg.formats` and can be submitted any time after Tier 1.
