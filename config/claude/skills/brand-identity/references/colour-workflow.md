# Colour workflow — runnable commands

macOS. `brew install little-cms2 ghostscript imagemagick` and Inkscape.

## ICC profiles

macOS ships only *Generic CMYK Profile.icc*, which is **not a press standard** — fine for
indicative numbers, not for a print order. Install a real one and name it in the spec:

- Europe: **PSO Coated v3 (FOGRA51)**, **PSO Uncoated v3 (FOGRA52)**, or **Coated FOGRA39** — free from eci.org
- North America: **GRACoL 2013**, **SWOP 2013** — idealliance.org

Drop into `~/Library/ColorSync/Profiles/`.

## sRGB to CMYK, numerically

`transicc` transforms numbers directly, with no image round-trip noise:

```sh
echo "26 80 96" | transicc -i "/System/Library/ColorSync/Profiles/sRGB Profile.icc" \
                           -o "$CMYK_PROFILE" -t 1
# C=88.05 M=42.24 Y=30.97 K=34.34        (-t 1 = relative colorimetric)
```

Round-trip back to sRGB and compute ΔE00 against the original to measure gamut loss.
Under 1.5 is imperceptible; 3+ is visible to someone holding the guide against the proof.

## CMYK vector PDFs

```sh
cp "$CMYK_PROFILE" /tmp/cmyk.icc        # gs -dSAFER needs a permitted path
gs -dBATCH -dNOPAUSE -dSAFER -q --permit-file-read=/tmp/cmyk.icc \
   -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -dAutoRotatePages=/None \
   -dProcessColorModel=/DeviceCMYK -sColorConversionStrategy=CMYK \
   -sOutputICCProfile=/tmp/cmyk.icc -dOverrideICC=true -dRenderIntent=1 \
   -sOutputFile=out-cmyk.pdf in-rgb.pdf
```

Black-only artwork instead gets `-dProcessColorModel=/DeviceGray
-sColorConversionStrategy=Gray` so it prints 100% K.

**Verify, don't assume.** ImageMagick re-encodes CMYK to sRGB for histograms, so read raw
pixels:

```sh
gs -dBATCH -dNOPAUSE -dSAFER -q -sDEVICE=tiff32nc -r100 -sOutputFile=v.tif out-cmyk.pdf
magick v.tif -sample 80x -depth 8 txt: | grep -oE "cmyk\([0-9,]+\)" | sort | uniq -c | sort -rn
```

Values are 0–255; divide by 2.55 for percent.

## 1-bit behaviour

```
y = 0.299R + 0.587G + 0.114B      # 0-255; <128 goes black, else white
```

A two-colour mark survives one-ink reproduction **by construction** when its two tinctures
land on opposite sides. Check this before designing keylines to compensate.

## Colour-vision simulation

Viénot/Brettel/Mollon, in linear RGB via LMS. Simulate deuteranopia and protanopia, then
compute WCAG contrast between the *simulated* pair. Below 3:1 the pair is not safe to use
as the only cue.

A palette built at two lightness tiers will separate across tiers and collapse within one.
That is a usable rule: *never encode a distinction with two colours from the same tier.*

## Contrast and OKLCH

WCAG relative luminance for contrast; OKLCH L for perceptual lightness and ramps. Build a
ramp at even OKLCH L steps and anchor one step on an actual brand colour so the scale
contains the real thing.

## Minimum size testing

```sh
inkscape mark.svg --export-type=png --export-filename=m.png --export-height=24
magick m.png -background '#FFF' -flatten -filter point -resize 1000% big.png
```

Nearest-neighbour magnification shows exactly what fills in. Publish the size that still
identifies, and name what fails below it.
