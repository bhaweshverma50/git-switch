# UI/UX Review: Git Switch (macOS SwiftUI)

**Target:** `Git Switch/ContentView.swift` + `Git Switch/Git_SwitchApp.swift`
**Focus:** Comprehensive UI/UX — visual design, typography, color/contrast, interaction & motion, accessibility, macOS HIG, IA & content
**Method:** 7-dimension parallel review (100 agents) with per-finding adversarial calibration to drop subjective noise.

## Summary

Git Switch is genuinely polished for a v1 — coherent accent theming, tasteful micro-interactions, a nice empty state, and good SF Symbols usage. The issues are concentrated in **accessibility** (the largest cluster), **macOS-native conformance** (it looks like a web app reskinned in SwiftUI rather than a Mac app), and **terminology/content consistency**. There are **no critical** (app-breaking) issues.

**91 findings kept** (2 dropped as subjective): **0 critical · 17 major · 43 minor · 31 suggestions.**
By area: accessibility 19 · macOS HIG 16 · IA/content 15 · visual/layout 15 · interaction/motion 11 · typography 8 · color/contrast 7.

---

## Major issues (consolidated)

### M1 — Accent colors fail WCAG contrast for white text/icons `[accessibility/color]`
`ContentView.swift:415-417` (AppTheme.color), consumed at primary buttons (716, 896-904, 1010, 1110), selected checkmark (1300), header logo (19-23), avatar initials (118-122).
White-on-accent contrast: orange **2.21:1**, green **2.22:1**, teal **2.34:1**, pink 3.55, blue 4.00, purple 4.12 — *every* accent misses the 4.5:1 bar for the small white button labels, and orange/green/teal miss even the 3:1 non-text bar (so the selected-state checkmark is sub-threshold). Black-on-accent measures 5.9–9.5 (all pass).
**Fix:** add `var onAccent: Color` to `AppTheme` (`.black` for orange/green/teal/pink, `.white` for blue/purple) and use it everywhere `.foregroundColor(.white)` sits on the accent — keeps all six swatches usable. (Optionally also darken the three brightest accents.)

### M2 — Selected accent swatch is hard to identify `[accessibility/color]`
`ContentView.swift:1295-1310`. Selection = white checkmark + `Color.white.opacity(0.3)` *inner* ring on the swatch; on the bright accents both are sub-threshold and the `opacity(0.15)` cell tint vanishes in light mode.
**Fix:** draw a scheme-aware high-contrast ring *outside* the swatch (separator/`Color.primary`) and use the M1 `onAccent` color for the checkmark; consider a small size bump so selection isn't color-only (WCAG 1.4.11).

### M3 — Profile actions are hover-only `[usability/accessibility]`
`ContentView.swift:816` (`.opacity(isHovering ? 1 : 0.4)`), `:825`. Copy-key / Edit / **Delete** are the only way to act on a profile, yet dimmed to 0.4 until mouse-hover — undiscoverable, and **unreachable for keyboard/VoiceOver** (onHover never fires). Hiding a destructive Delete this way is the riskiest instance.
**Fix:** keep actions at full/near-full opacity (or reveal on `@FocusState` *and* hover); never drop below ~0.6; ensure keyboard focus + visible focus ring.

### M4 — Icon-only buttons have no accessibility labels (and no resting affordance) `[accessibility]`
`IconButton` (618-656) and `ActionButton` (841-871) render a bare `Image(systemName:)` with `Color.clear` behind it until hover, and **no `.accessibilityLabel`** — refresh, +, gear, key, pencil, trash, the menu-bar refresh (31-47), the Settings close X (1163), the folder-picker "…" (971), and the plain-text footer Open App / Quit (77-95). `.help()` does **not** supply a VoiceOver label on custom controls.
**Fix:** add `.accessibilityLabel(...)` to every icon-only button, and give them a faint persistent background (`Color.primary.opacity(0.05)`) so they read as controls at rest.

### M5 — No Reduce Motion support `[accessibility/motion]`
Project-wide: the 360° refresh spin (32, 631), per-index staggered list entrance (540-550), hover scale/shadow springs (733, 822), copy/appear springs. Nothing reads `@Environment(\.accessibilityReduceMotion)`.
**Fix:** read `accessibilityReduceMotion` and gate decorative animation — `withAnimation(reduceMotion ? nil : .spring(...))`, skip the rotation, replace entrance offset/scale with a plain fade.

### M6 — Global Identity inline edit is barely discoverable `[usability]`
`ContentView.swift:692-726`. Editing is only via a low-contrast `Color.primary.opacity(0.06)` "Edit" text pill; the name/email give no affordance (no hover/cursor/pencil).
**Fix:** strengthen the pill (outline + pencil icon) and/or reveal an edit control on card hover/focus.

### M7 — Should be a menu-bar accessory (LSUIElement) `[HIG]`
`project.pbxproj:252` (no LSUIElement), `Git_SwitchApp.swift`. The product is a menu-bar identity switcher but launches as a full Dock app *and* a status item — duplicated surfaces, stray default app menus.
**Fix (product decision):** either set `LSUIElement`/`.accessory` (pure menu-bar app, open the window on demand) or commit to a normal windowed app — not both.

### M8 — Window resizability conflicts with the scrollable content `[HIG/usability]`
`Git_SwitchApp.swift:20` (`.windowResizability(.contentSize)`) vs `ContentView.swift:474` (`minWidth 600/minHeight 500`) + a root `ScrollView`. `.contentSize` fights a growth-oriented list.
**Fix:** use `.windowResizability(.contentMinSize)` (or `.automatic`) + `.defaultSize(width: 720, height: 600)`.

### M9 — Settings should be the standard Settings scene `[HIG]`
`ContentView.swift:482, 1127`. Settings are a hand-rolled 320×300 sheet with a custom close X.
**Fix:** add a `Settings { … }` scene — free `Settings…` menu item + ⌘, + a proper preferences window.

### M10 — Custom capsule/plain buttons instead of native controls `[HIG]`
Create/Save/Add (896, 1010, 1110) are accent capsules; Cancel is flat gray text (1004, 1104). No default-action (↩) or cancel (⎋) keyboard shortcuts, no system focus rings.
**Fix:** `.borderedProminent` + `.keyboardShortcut(.defaultAction)` for primaries; `.bordered`/plain + `.keyboardShortcut(.cancelAction)` for Cancel.

### M11 — One concept, three names: Profile / Context / Identity `[content]`
"Context Profiles" (519), "Identity Manager" (595), "Add Context" (609, 897), "New Context" (925), "Edit Identity" (1089), "profile" (placeholder/count). 
**Fix:** standardize on **"Profile"** (matches `GitProfile` and the name field) everywhere.

### M12 — Edit/Delete/Global-Save can fail silently `[usability]`
Only `createProfile` surfaces errors (289 → 1061). `updateProfile` (337), `deleteProfile` (348), `saveGlobalConfig` (263) discard failures via `try?`.
**Fix:** give them the same `completion(error)` pattern + inline/alert messages ("Couldn't write ~/.gitconfig — check permissions.").

---

## Minor issues (grouped themes)

**Typography & Dynamic Type** — No shared type scale; every font is a hardcoded `.system(size:)` (9→22). 9–10pt labels (127) are below the macOS legibility floor. Defeats Dynamic Type. → Define a small type ramp and/or use semantic styles + `@ScaledMetric`; raise the smallest labels to ≥11pt.

**Color system in light/dark** — `Color.primary.opacity(0.03–0.12)` surfaces nearly vanish in light mode (143); shadows tuned for light disappear on dark (733); accent-tinted icon tiles make the folder glyph low-contrast in light mode (166); tertiary text (folder paths, footer) borderline (783). → Prefer system materials (`.regularMaterial`), `Color(nsColor:.controlBackgroundColor)`/separators, and scheme-aware shadows.

**Visual consistency** — Card corner radius varies (10/12/14) for equivalent cards (731); sibling shadow values differ (733); no spacing scale (magic numbers throughout); three sheet widths (420/380/320) + a fixed 300pt Settings height that strands empty space; AddProfileSheet header is centered while its form is left-aligned (938); menu-bar dropdown rows are cramped and the 200pt list clips abruptly. → Establish spacing + radius + shadow tokens; unify sheet sizing.

**Interaction/motion** — Two divergent press systems (`ScaleButtonStyle` vs `ActionButton`'s custom `DragGesture`, 1388) → unify into one button style; hover scale is imperceptible/inconsistent (1.005 vs 1.008) and causes sub-pixel text shimmer; refresh spin is decoupled from the actual data load (false loading signal); copy "Copied" relies on a 2s timer that desyncs on rapid taps.

**Accessibility (beyond M1–M5)** — color-only signaling (green=copied/190, red=delete/794); appearance/accent pickers lack the selected accessibility trait (1216, 1276) and aren't exposed as a group; avatar initials unlabeled; decorative logo glyphs not hidden from VoiceOver; literal empty-value strings ("Not Set"/"—").

**Content/IA** — No onboarding or global-vs-profile explanation; delete confirmation names the *folder* not the profile and omits "SSH key is kept"; folder placeholder is ambiguous with no example; no success feedback for create/edit/delete/save; version label hardcoded "v1.0.1" instead of read from the bundle; menu vs window use different empty-value copy.

---

## Suggestions (nice-to-have)

Honor the **system accent color** / `reduce transparency` / high-contrast; build sheets as native `Form`s; wire ⌘Q + standard menus; hide branding glyphs from VoiceOver; normalize heading weights (`.bold` vs `.semibold` for equivalent titles); tune the per-index entrance so long lists don't cascade slowly.

---

## Positive observations

- Coherent accent-theming system with light/dark/system appearance support.
- Tasteful, restrained micro-interactions and a genuinely good empty state.
- Consistent SF Symbols usage; sensible information grouping (avatar + name + email + path).
- Destructive delete already uses a confirmation `alert`.
- Uses `Color(nsColor:.windowBackgroundColor/.controlBackgroundColor)` in places (good for dark mode).

## Recommended order of work

1. **Accessibility quick wins (M1, M4, M5, + color-only signaling)** — `onAccent` color, `.accessibilityLabel` on every icon button, reduce-motion gate. Mostly mechanical, high impact.
2. **Discoverability (M3, M6)** — stop hiding profile actions behind hover; strengthen the global-edit affordance.
3. **macOS-native conformance (M7–M10)** — Settings scene, native buttons + key shortcuts, window resizability, LSUIElement decision.
4. **Content pass (M11, M12 + delete/onboarding copy)** — one noun ("Profile"), surface all errors, success feedback.
5. **Design-token cleanup (minors)** — spacing/radius/shadow/type scales; unify the two button-press systems.

_Full machine-readable findings (91) retained from the review run; this is the consolidated, deduplicated view._
