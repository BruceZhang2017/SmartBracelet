---
name: "ux-ui-expert"
description: "Audits and redesigns app UI/UX with product-grade layout, hierarchy, and interaction polish. Invoke when user asks for UI optimization, visual redesign, screenshot review, or premium UX refinement."
---

# UX/UI Expert

## Purpose

This skill is for product-grade UI/UX optimization work in app screens, especially when the user asks to:

- optimize a page layout
- improve visual hierarchy
- make a screen look more premium
- audit a screenshot after changes
- redesign a page without adding new features
- unify a module into a consistent design language

Use this skill before making UI changes, not after a weak solution is already implemented.

## Core Working Rules

1. Treat UI work as product design work, not as random style edits.
2. Do not add new functional modules unless the user explicitly asks for new features.
3. Prefer improving:
   - spacing
   - hierarchy
   - alignment
   - typography
   - card structure
   - section rhythm
   - color consistency
   - state clarity
4. Avoid low-quality "visual upgrades" such as:
   - adding extra cards without structural need
   - forcing large summary blocks into non-scrolling hero areas
   - decorative animations that reduce readability
   - mismatched illustrations or assets
   - mixing too many radii, shadows, or text styles on one screen

## Required Workflow

When invoked, follow this order:

1. Identify the page type
   - dashboard
   - detail page
   - device management page
   - settings page
   - list page
   - empty state page

2. Audit the current UI before coding
   - read the screen structure
   - identify major containers
   - identify existing state logic
   - identify whether the page is scroll-based or fixed-height
   - identify high-risk overlap zones

3. Decide the design goal
   - premium but restrained
   - brand-consistent
   - no feature expansion unless requested
   - maintain readability first

4. Build a layout plan before editing
   - what is the primary visual focus
   - what is the reading order
   - which sections should be merged
   - which sections should be de-emphasized
   - where white space should increase

5. Implement in controlled scope
   - prefer adjusting existing structures first
   - only add new views if the page truly lacks a necessary layer
   - keep state transitions compatible with current logic

6. Validate after changes
   - check diagnostics
   - verify no overlap risk
   - verify no "empty premium card" artifacts
   - verify screenshots would still look balanced on small screens

## Design Standards

### Layout

- Build a clear reading order from top to bottom.
- Keep the number of major visual blocks limited.
- Use larger section spacing between unrelated modules.
- Use tighter internal spacing inside the same card.
- Prefer structural polish over adding more content.

### Typography

- One strong title level per page or section.
- Secondary text must support, not compete.
- Avoid too many bold labels in one viewport.
- Long description text should rarely appear in fixed-height hero regions.

### Cards

- Use consistent corner radius by page family.
- Use subtle shadows and borders, not both aggressively.
- Keep card padding visually balanced.
- Make all cards belong to the same design system.

### Interaction

- Remove flashy, pulsing, or distracting motion unless the user explicitly wants it.
- Keep press feedback subtle and fast.
- Avoid spring-heavy motion on information pages.

### Screenshot Review Rules

When the user provides a screenshot:

1. First identify visible layout failures:
   - overlap
   - clipping
   - empty blocks
   - bad hierarchy
   - awkward spacing
   - oversized text blocks
2. Fix those before discussing style refinement.
3. If a redesign caused visible regression, prefer rolling back the problematic layer instead of defending it.

## Project-Specific Guidance

For SmartBracelet:

- Favor restrained premium UIKit design over over-designed concept visuals.
- Keep compatibility with existing iOS versions and current project structure.
- Respect existing business logic and navigation flow.
- When optimizing health or device pages, prefer brand-color coherence and product hierarchy over decorative additions.

## Output Expectation

A good result should feel:

- cleaner
- more professional
- more consistent
- easier to scan
- visually premium without being noisy

A bad result usually looks:

- crowded
- randomly cardified
- top-heavy
- over-animated
- visually inconsistent

## Short Reminder

Before every UI change, ask internally:

"Am I improving structure, or just adding more stuff?"

If the answer is "adding more stuff", stop and redesign the layout plan first.
