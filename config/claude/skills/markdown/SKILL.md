---
name: markdown
description: "Markdown formatting conventions for clean diffs, accessible images, and consistent typography"
license: CC-BY-4.0
compatibility: opencode
---

# Markdown Conventions

Rules for writing markdown that produces clean git diffs, stays accessible, and reads well.

## Line Breaks

One sentence per line.
This keeps diffs minimal — a changed sentence shows as a single changed line, not a rewrapped paragraph.

Do not hard-wrap at a character limit.
Let each sentence occupy exactly one line regardless of length.

## Headings

Never bold headings.
Headings already carry visual weight from their level — adding `**` is redundant.

```markdown
<!-- yes -->
## My heading

<!-- no -->
## **My heading**
```

## Images and Figures

Always provide alt text and captions.

**Pure markdown images:**

```markdown
![Descriptive alt text for the image](path/to/image.png "Caption describing the figure")
```

**Code chunk figures (R, Python, Quarto, R Markdown):**

Always use Quarto-style `#|` chunk options — even in R Markdown documents.
Label every chunk, and always set both `fig-alt` and `fig-cap` on figure chunks.

````markdown
```{r}
#| label: scatter-age-score
#| fig-alt: "Descriptive alt text for the generated plot"
#| fig-cap: "Caption describing what the figure shows"
plot(x, y)
```
````

Never use knitr-style chunk headers or inline comments:

````markdown
<!-- no -->
```{r, fig.alt="...", fig.cap="..."}
```

<!-- no -->
```{r}
# fig.alt = "..."
```
````

Alt text describes _what the image shows_ for screen readers.
Captions describe _why the image matters_ in context.

Use descriptive image filenames based on content — never generic names like `screenshot_01.png`.

## Links

Prefer inline hyperlinks over footnotes for relevant resources.

```markdown
<!-- yes — link is part of the narrative -->
The [tidyverse style guide](https://style.tidyverse.org/) covers this in detail.

<!-- no — footnote breaks reading flow for directly relevant content -->
The tidyverse style guide covers this in detail.[^1]

[^1]: https://style.tidyverse.org/
```

Reserve footnotes for supplementary information that is not directly relevant to the current point — asides, caveats, or tangential references the reader might want later.

## Lists

End each list item with two trailing spaces to ensure correct line breaks.

```markdown
<!-- yes -->
- First item  
- Second item  
- Third item  

<!-- no -->
- First item
- Second item
- Third item
```

## Emphasis

Use underscores for italics, not asterisks.

```markdown
<!-- yes -->
_italic text_

<!-- no -->
*italic text*
```

## Em Dashes

Always add spaces around em dashes.

```markdown
<!-- yes -->
This is important — especially for readability.

<!-- no -->
This is important—especially for readability.
This is important — especially for readability.
```
