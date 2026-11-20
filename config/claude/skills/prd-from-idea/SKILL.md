---
name: prd-from-idea
description: Turn a one-line feature idea into a short evidence-backed PRD before any code is written. Use when the user says "I want to build X" or "let's add Y" for non-trivial work — produces a 1-page scoped plan with success criteria, anti-goals, risks, and concrete first slices.
---

# /prd-from-idea

A working PRD is a planning aid for the next 1–4 hours of work, not a stage gate. Aim for ~1 printed page. Five sections:

## 1. The pitch (3 sentences)

- One sentence: what the user is trying to do (the user-visible job, not the implementation).
- One sentence: how this feature solves it.
- One sentence: why this is worth doing now vs. later.

## 2. Success criteria (testable)

Bullet list. Each criterion must be falsifiable by running a command, looking at a screenshot, or reading a log line. Examples:

- "`cargo test --package foo` passes with at least 3 new tests covering X / Y / Z"
- "On a fresh install, the user can complete A in under 5 steps"
- "Codecov patch coverage ≥ 80% on the changed files"

If a criterion isn't testable, it's a wish, not a criterion. Either rewrite or delete.

## 3. Anti-goals (what this is NOT)

Often more useful than the goals. List 3–5 things this PRD explicitly does NOT cover, even if related. Catches scope creep up front.

## 4. Risks + open questions

Two short lists:

- **Risks**: what could break, what could be slow, what could regress. One line each.
- **Open questions**: things you don't know yet that gate the design. If too many, the PRD is premature — investigate first.

## 5. First slice (concrete)

The smallest end-to-end change that delivers some of the success criteria. Should be shippable on its own (stacked PR #1). Name 3–7 files you expect to touch and the test(s) that will prove it works.

## How to use this skill

When the user describes a feature, draft each section in turn, ask one or two clarifying questions per section (don't batch all of them upfront — let answers shape later sections), and stop after the first slice. Resist filling out optional fields. Resist designing the whole feature. The PRD is done when the next 1–4 hours of work are unblocked.

## Format

Markdown. Output to stdout (don't write a file unless asked). Length: ~30–60 lines total. If it's longer, you're over-specifying.
