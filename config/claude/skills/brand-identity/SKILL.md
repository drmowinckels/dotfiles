---
name: brand-identity
description: Building or auditing a visual identity — logos, brand colour palettes, brand books, print and textile specs. Use whenever defining or changing brand colours, producing logo asset packs, writing brand guidelines, or preparing artwork for print, merchandise or embroidery. Enforces that every brand colour carries a measured CMYK and Lab specification, not just a hex. Loads the companion skills that branding work usually needs.
license: CC-BY-4.0
compatibility: opencode
metadata:
  audience: designers-and-developers
  focus: colour-specification, print-production, asset-pipelines
---

# Brand Identity

Branding work fails in two predictable places: a colour that only ever existed as a hex
code, and an asset pack that was hand-exported once and never regenerated. This skill
prevents both.

## Load these too

Branding work almost never stands alone. At the **start** of the task, load whichever apply
— don't wait for them to trigger on their own:

| Situation | Load |
| --- | --- |
| Any chart, plot or data graphic in brand colours | `dataviz-guide`, and `dataviz` if present |
| Custom/interactive SVG visualisation | `d3js-skill` |
| Implementing the brand on a Hugo site | `hugo-site`, `hugo-tailwind-theme` |
| Quarto docs, slides or a `_brand.yml` | `quarto-cli`, `quarto:brand-yml`, `quarto-revealjs`, `quarto-typst` |
| Shiny app theming | `shiny:brand-yml`, `shiny:shiny-bslib-theming` |
| A UI, landing page or component work | `impeccable:impeccable`, `ui-ux-pro-max:ui-ux-pro-max`, `artifact-design` |
| Writing the guidelines prose | `drmo-voice`, `markdown` |
| Shipping the work | `clean-commit`, `ship` |

If the project has `DESIGN.md`, `PRODUCT.md`, `brand/` or `_brand.yml`, read them before
proposing anything — and **say so explicitly if the shipped artwork contradicts them**.
Stale brand docs are worse than none; flag the contradiction rather than silently
following one of them.

## The colour rule

> **A brand colour is not specified until it has a measured Lab value, a CMYK separation
> under a named ICC profile, and a known 1-bit behaviour. A hex code alone is a screen
> preview, not a specification.**

Every palette this skill touches ships, per colour:

| Field | Why |
| --- | --- |
| **Lab (D50)** | The master. Device independent — the only value that says what the colour *is*. Hand this to printers and Pantone matchers. |
| sRGB hex | Screen and web. |
| OKLCH L | For reasoning about lightness relationships and building ramps. |
| **CMYK % + ICC profile name** | Print. Meaningless without naming the profile. |
| **TAC** (total area coverage) | Sheet-fed coated tolerates ~300–340%; uncoated far less. |
| **ΔE00 round-trip** | How far the colour moves in CMYK. <1.5 imperceptible, 3+ visible. |
| **1-bit threshold** | Which side of mid-grey it lands — decides whether a two-colour mark survives photocopying. |
| Contrast on each ground | Measured, never estimated. |

`references/colour-workflow.md` has the runnable commands and formulas.

### Non-negotiables

- **Never invent Pantone numbers.** They are physical ink standards; a number derived from
  a screen conversion will be wrong on press. Supply Lab, have the supplier match in a
  current *physical* guide under D50, and approve a drawdown. Name the right library:
  Solid Coated/Uncoated for print, **TCX** for dyed fabric, **TPG** for product.
- **Name the ICC profile beside every CMYK value.** "C88 M42 Y31 K34" is not a spec;
  "…under PSO Coated v3 (FOGRA51)" is. A generic profile gives indicative values only —
  label them as such and tell the printer to reseparate from Lab.
- **Simulate colour-vision deficiency before locking a palette**, not after. Deuteranopia
  and protanopia at minimum. If two colours collapse, either fix the lightness separation
  or write an explicit rule that they never encode a distinction alone. Record which.
- **Measure minimum sizes, don't invent them.** Render the mark at candidate sizes, look at
  it, and publish the size where it still identifies. State what fails below it.
- **One-colour artwork is a knockout, not a white fill.** Produce it with a real boolean
  difference so the counters are holes. A white-filled charge only works on white.
- **Black-only artwork converts to DeviceGray**, so it prints 100% K. A four-colour black
  will not hold registration on small detail.

## Working method

1. **Read the existing docs** and the actual artwork. Measure the artwork's real colours —
   do not trust what the docs claim.
2. **Derive, don't invent.** Build ramps and support tones from the locked brand colours.
   Anchor a ramp on a brand colour so one step *is* the real thing.
3. **Measure everything** and put the numbers in the guidelines. Contrast ratios, ΔE, TAC,
   OKLCH lightness. Re-measure when a value moves.
4. **Generate the asset pack from source**, with a script, not by hand-exporting. The pack
   must rebuild reproducibly from the master artwork. Verify by deleting it and rebuilding.
5. **Test the reproduction cases** before writing the rules: small sizes, reversed on dark,
   one ink, greyscale, and on the actual substrate for textile work.
6. **Flag what fails.** A brand book that hides a failure is worse than one that names it.
   If the mark doesn't survive the stated minimum, say so and recommend the fix rather than
   quietly shipping artwork nobody approved.

## Asset pack shape

```
assets/
  logo/
    svg/       lockups x variants — flattened, transform-free masters
    png/       transparent rasters at a few sizes
    pdf/       vector RGB
    pdf-cmyk/  vector CMYK, separated through a named profile
    eps/       for printers who ask
    favicon/   ico, svg, app icons, maskable
  graphics/    supporting library
  README.md    which file to reach for
  PRINT-SPEC.md  Lab + CMYK + textile notes, written to hand to a supplier
```

Variants per lockup: `colour`, `reversed` (dark grounds), `mono-ink`, `mono-black`,
`mono-white`, and `mono-current` (SVG inheriting `currentColor`).

## Textile and merchandise

Most garment decoration is **not CMYK** — specify by Lab, approve a physical sample.

- A pale tint on a dark garment **needs a white underbase**, or it goes translucent.
- **Embroidery minimums are far larger than print** — typically 50–60 mm for a detailed
  mark. Finest line ≥1 mm at final size. Commission a stitch-simplified version rather
  than letting a digitiser improvise.
- Thread is matched from charts (Madeira, Isacord, Gunold) and reads lighter and more
  saturated than flat ink because it is glossy.
- Vinyl, laser and engraving take the mono knockout only.

## Brand book contents

Mark and lockups · clear space and measured minimum sizes · colour with measured contrast,
CVD results and 1-bit behaviour · typography specimen · graphics library · **misuse** ·
print/textile spec · accessibility statement · how to regenerate.

Publish it as HTML so the swatches and SVG are live, and print a PDF from it for people who
won't open a local file.
