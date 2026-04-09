# Design System Strategy: RepFoundry Performance Editorial

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"Kinetic Precision."** 

We are moving away from the "utility-first" look of standard fitness trackers and toward a high-end, editorial experience that feels like a premium digital coach. While we utilize Material 3 (M3) logic, we reject the "flat" default. This system breaks the template through **Intentional Asymmetry**—using offset typography and overlapping elements—to create a sense of forward motion. The layout isn't just a container; it’s a reflection of the energy found in the gym.

## 2. Colors & Surface Philosophy
The palette is rooted in deep violets and electric amethysts, designed to reduce eye strain in low-light gym environments while maintaining high-energy accents.

### The "No-Line" Rule
**Prohibition:** Designers are strictly forbidden from using 1px solid borders (`outline`) for sectioning. 
**Execution:** Boundaries must be defined solely through background color shifts. For example, a `surface-container-low` (#1d0832) workout tile must sit on a `surface` (#16052a) background. The change in tone provides the "edge," keeping the UI feeling expansive and expensive.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of frosted glass.
*   **Base:** `surface` (#16052a) for the main app background.
*   **Secondary Content:** `surface-container` (#240e3b) for grouped data.
*   **Emphasis/Action:** `surface-container-highest` (#32194e) for active workout tiles.
*   **Nesting:** Inner elements (like a "Set" counter inside a "Workout Card") should use a lower-tier container than their parent to create a "recessed" look, rather than a "protruding" one.

### The "Glass & Gradient" Rule
To elevate beyond standard M3, use **Glassmorphism** for floating elements (like the Navigation Bar). Use `surface-bright` (#391e58) at 60% opacity with a 20px backdrop-blur. 
**Signature Texture:** Use a linear gradient from `primary` (#b99fff) to `primary-dim` (#8354f4) for high-impact CTAs to provide "soul" and depth that flat hex codes cannot achieve.

## 3. Typography
We use a high-contrast pairing to balance technical data with aggressive motivation.

*   **Display & Headlines (Space Grotesk):** This geometric sans-serif communicates industrial strength. Use `display-lg` (3.5rem) for "Total Weight Lifted" or "Personal Bests" to make data feel like an achievement.
*   **Body & Labels (Manrope):** A modern, highly legible sans-serif. Use `body-md` (0.875rem) for instructions and `label-sm` (0.6875rem) for technical metrics (e.g., Tempo: 3-0-1-0).
*   **Editorial Spacing:** Use `headline-sm` for section titles, but intentionally offset them (e.g., 4px left-margin more than the card below) to break the rigid vertical grid and add a signature "editorial" feel.

## 4. Elevation & Depth
In this system, elevation is conveyed through **Tonal Layering** rather than traditional drop shadows.

*   **The Layering Principle:** Stack `surface-container-low` cards on a `surface` background. If you need a "lifted" state (e.g., a card being dragged), shift the color to `surface-container-highest`.
*   **Ambient Shadows:** For the Floating Action Button (FAB), use a diffused shadow: `on-surface` color at 6% opacity, Blur: 24px, Y: 8px. This mimics soft gym lighting rather than a harsh digital drop shadow.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, use the `outline-variant` token (#534067) at **15% opacity**. Never use 100% opaque borders.

## 5. Components

### Cards & Workout Tiles
*   **Execution:** Forbid the use of divider lines. Separate "Exercise Name" from "Sets/Reps" using a `2.5` (0.625rem) vertical spacing gap.
*   **Visual Soul:** Use a subtle corner accent of `tertiary` (#ff97b7) for cards representing a "New Record" to provide immediate visual feedback.

### Floating Action Button (FAB)
*   **Styling:** Use the `primary-container` (#ac8eff) with `on-primary-container` (#2a006f) icons. 
*   **Shape:** Use the `xl` (1.5rem) roundedness rather than a perfect circle to keep it modern and aligned with the M3 aesthetic.

### Navigation Bar (5 Tabs)
*   **Styling:** Apply the Glassmorphism rule. No top-border. Use `surface-container-highest` for the active state indicator pill, but keep the pill background at 30% opacity for a sophisticated "tinted glass" look.

### Charts & Progress
*   **Visual Direction:** Use `primary` (#b99fff) for the main data line. 
*   **The "Glow" Effect:** Under the line chart, use a gradient fill from `primary` at 20% opacity to `transparent` at the bottom to create a soft, energetic glow.

### Input Fields
*   **Execution:** Unfilled, "Flushed" style. Use `surface-container-highest` for the background with no border. When focused, change the background to `surface-bright` and add a `2px` bottom-only indicator in `primary`.

## 6. Do’s and Don’ts

### Do:
*   **Use Asymmetry:** Place "Date" labels slightly offset from the main card alignment to create a "Scrapbook/Editorial" feel.
*   **Embrace Negative Space:** Use the `12` (3rem) spacing scale between major sections. Let the data breathe.
*   **Layer with Intent:** Ensure every container change (from Surface to Surface-Container) serves a purpose, like grouping a superset.

### Don’t:
*   **No Dividers:** Never use a horizontal line to separate list items. Use the `surface-container` tiers or vertical white space.
*   **No Pure Black:** The darkest point is `surface-container-lowest` (#000000) only for deep backgrounds; use `surface` (#16052a) for most backgrounds to maintain the purple tonal depth.
*   **No High-Contrast Borders:** These break the "frosted glass" immersion of the design system.