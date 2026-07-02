---
name: mobile-accessibility-guard
description: Review Kotlin/Android and Flutter code for WCAG 2.1 AA accessibility violations before merge — missing content descriptions/semantics, undersized touch targets, insufficient color contrast, broken screen reader flow, and unannounced dynamic content. Use when reviewing feature implementations with new UI, when preparing for an accessibility audit, when a screen reader user reports a bug, or after a coding agent generated UI code. Apply this for TalkBack/VoiceOver support, touch target sizing, color contrast, form labels, and custom widget semantics. Use for "review this for accessibility", "is this screen reader friendly?", "check contrast/touch targets", "WCAG audit", or after implementing any new screen or interactive component.
---

# mobile-accessibility-guard

You are reviewing mobile code for accessibility violations before it ships. Apply the rules below after a UI feature is implemented, or while designing a new screen or component. This skill maps WCAG 2.1 AA to mobile-specific equivalents (Android/Flutter) — not the web checklist verbatim, since criteria like "page titles" or "keyboard traps" translate differently on a touchscreen with a screen reader.

## Compatibility

This skill works with:
- **Android**: `contentDescription`, `importantForAccessibility`, `AccessibilityNodeInfo`, TalkBack, Android Accessibility Scanner, Espresso Accessibility Checks
- **Flutter**: `Semantics` widget, `semanticsLabel`, `ExcludeSemantics`/`MergeSemantics`, TalkBack/VoiceOver via platform accessibility bridges, `SemanticsTester` in widget tests
- **Shared**: WCAG 2.1 AA success criteria, mapped to their mobile equivalents rather than applied literally

This skill complements mobile-architecture-guard, clean-code-guard, and mobile-security-guard. Accessibility bugs are usually UI-layer only — this skill doesn't duplicate architecture or security checks, it adds a fourth lens: "can a screen reader or low-vision user actually use this."

## Reference files

This SKILL.md covers the core rules and checklists. For deeper treatment, load these as needed:
- `references/screen-reader-patterns.md` — TalkBack/VoiceOver testing walkthroughs, semantic grouping with `MergeSemantics`/`AccessibilityNodeInfo`, live region announcements, and custom widget semantics setup.
- `references/touch-and-visual.md` — touch target sizing math, WCAG contrast ratio calculation with worked examples, and dynamic text scaling (`sp` units, `MediaQuery.textScaler`) across both platforms.

Read the relevant reference file when a violation needs more context than the summary here provides, or when setting up screen reader testing for the first time on a project.

## How to use this skill

**Guard-pass mode** (recommended): After implementing any new screen, dialog, or interactive component, check it against the imperatives below before merging.

**Live mode**: When designing a new screen or custom widget, apply these imperatives while building, then run the *Self-check before delivery* checklist.

**Review mode**: Walk the code and provide a structured findings report, severity-ranked, referencing the specific WCAG success criterion — not just "this isn't accessible" but which criterion it fails and who it blocks.

## Why this skill exists

Mobile accessibility failures follow a small number of repeating patterns:
- **Visual-only components**: a `Text` widget wrapped in a `GestureDetector` that looks like a button but has no button semantics — a screen reader announces it as plain text, giving no indication it's tappable.
- **Missing or wrong content descriptions**: icons and images with no `contentDescription`/`semanticsLabel`, or worse, a generic one ("image", "icon") that tells a screen reader user nothing.
- **Touch targets sized for sighted precision, not real thumbs**: 24dp icon buttons that are hard to hit even without a motor impairment.
- **Color as the only signal**: red/green form validation with no icon or text, invisible to color-blind users.
- **Silent dynamic updates**: a loading spinner resolves into new content, but nothing announces the change to a screen reader user who's already moved focus elsewhere.
- **Accessibility treated as a final QA pass** instead of a build-time concern, so it's discovered (or isn't) right before release when fixing it is most expensive.

These aren't edge cases — they're the default output of UI code that was never reviewed with a screen reader running.

## Always-applied imperatives

### Perceivable

1. **Every meaningful non-text element has a text alternative.** Icons, images, and icon-only buttons carry `contentDescription` (Android) or `semanticsLabel`/`Semantics(label:)` (Flutter) describing their *function*, not their appearance. "Delete item" not "trash icon."
   **Violation smell**: `Image(painter = ...)` or `IconButton` with no `contentDescription`, or one that just restates the icon name.

2. **Decorative images are explicitly excluded from the accessibility tree, not silently mislabeled.** A background pattern or purely visual flourish gets `contentDescription = null` with `importantForAccessibility = "no"` (Android) or `ExcludeSemantics` (Flutter) — not an empty string, which some screen readers still announce as "image."

3. **Color contrast meets WCAG AA minimums: 4.5:1 for normal text, 3:1 for large text (18pt+/14pt+bold) and meaningful UI components/icons.** Check this against the actual rendered colors (including any overlay/opacity), not the design file in isolation.
   **Violation smell**: light-gray-on-white secondary text, or a "disabled-looking" primary button that's actually meant to be tappable.

4. **Color, shape, or position is never the only signal.** Form validation, status indicators, and chart legends pair color with text, an icon, or a pattern — a color-blind user (roughly 1 in 12 men) must be able to get the same information without distinguishing red from green.

5. **Text scales with the user's system font size setting, and layouts don't break when it does.** Android: use `sp` for text size, never `dp`. Flutter: respect `MediaQuery.textScaler`, avoid `SizedBox`-constrained text that clips at larger scales. Test at the largest supported system font size, not just default.

### Operable

6. **Touch targets are at least 48x48dp (Android) / 44x44pt-equivalent (Flutter, matching platform guidance), even if the visual icon is smaller.** Use padding or a minimum-size wrapper to hit the target size without inflating the visible icon — this protects users with motor impairments and anyone using the app one-handed or in motion.
   **Violation smell**: a 24dp `IconButton` with no `minimumInteractiveComponentSize` or padding compensating for it.

7. **Focus/reading order matches visual reading order.** Screen reader traversal order (top-to-bottom, left-to-right in LTR layouts) should match what a sighted user sees, not the order elements happen to appear in the view hierarchy after a refactor. Test by swiping through with TalkBack/VoiceOver, not just reading the XML/widget tree.

8. **Focus indicators are visible for keyboard, switch-access, and D-pad navigation.** Custom-styled interactive components that suppress the default focus ring must provide their own visible equivalent — don't ship `outline: none`-equivalent styling with nothing replacing it.

9. **Time limits are extendable, removable, or absent for anything accessibility-relevant.** A session-expiry countdown or auto-advancing carousel doesn't block task completion for a user who reads or navigates more slowly — provide a pause/extend control.

10. **Complex or custom gestures have a simple alternative.** If a feature requires a multi-finger swipe or a precise drag, it also has a single-tap or button-based path — screen reader users navigate primarily by swipe-to-next-element and double-tap-to-activate, which conflicts with custom gesture handling that isn't screen-reader-aware.

### Understandable

11. **Form fields have a programmatically associated accessible label, not just a nearby visual one.** A floating label or placeholder-only field with no `labelFor`/`Semantics(label:)` binding reads as an unlabeled text field to a screen reader — "edit box, blank" tells the user nothing about what to enter.

12. **Validation errors are announced to the screen reader when they appear, not just displayed visually.** Use a live region (`View.ANNOUNCE_FOR_ACCESSIBILITY` / `Semantics(liveRegion: true)`) or move accessibility focus to the error so a screen reader user learns the field failed validation without having to re-explore the form.

13. **Navigation patterns and component behavior are consistent across the app.** The same-looking button doesn't mean different things on different screens; a back gesture or button behaves the same way everywhere it appears.

### Robust

14. **Custom interactive widgets expose the correct semantic role, not just correct visuals.** A tappable `Row`/`Column` acting as a button gets `Semantics(button: true, onTap: ...)` (Flutter) or a custom `AccessibilityNodeInfo` role (Android) — visual similarity to a button is not the same as being announced as one.

15. **Dynamic content changes are announced via live regions when they happen off-screen from current focus.** A snackbar, toast, inline error, or async-loaded content update that a sighted user notices visually needs an equivalent announcement for a screen reader user whose focus is elsewhere.

16. **Related content is grouped into a single accessibility node where fragmenting it would be noise, and kept separate where independent interaction is needed.** A card with a title, subtitle, and icon that's all one tap target should merge into one semantic node (`MergeSemantics`, or a single `contentDescription` on the container) rather than forcing a screen reader user to swipe through three separate announcements for what's functionally one thing.

17. **Screen and dialog titles are announced on navigation.** When a new screen or modal opens, accessibility focus moves to (or an announcement fires for) its title, so a screen reader user knows where they landed instead of hearing whatever happened to be first in the new view's tree.

### Testing & Process

18. **Automated accessibility checks run before merge, not just before release.** Android Accessibility Scanner or Espresso Accessibility Checks, and Flutter's `SemanticsTester`/`meetsGuideline` matchers in widget tests, catch missing labels and contrast issues cheaply and early — wire them into the same PR check as everything else, don't leave them for a pre-release audit.

19. **New or significantly changed screens get a manual screen reader pass, not automated checks alone.** Automated tools catch missing labels and contrast; they don't catch a confusing reading order, a poorly worded label, or a group that should have been merged. Swipe through the actual screen with TalkBack or VoiceOver before calling it done.

20. **Accessibility is verified across every UI state — loading, empty, error, and populated — not just the happy path.** A loading spinner with no "loading" announcement, or an error state that only communicates via a red border, is exactly as broken as a missing label on the populated state, and it's the state most often skipped in review.

## Self-check before delivery

Before marking an accessibility review complete, confirm:

- [ ] Every icon/image/icon-button has a meaningful `contentDescription`/`semanticsLabel`, or is explicitly marked decorative
- [ ] Color contrast checked against rendered colors: 4.5:1 text, 3:1 large text/UI components
- [ ] No status/validation/chart information relies on color alone
- [ ] Touch targets are ≥48dp/44pt-equivalent, even where the visual icon is smaller
- [ ] Reading/focus order matches visual order (verified with a screen reader, not just by reading the code)
- [ ] Custom focus indicators exist wherever the default was suppressed
- [ ] Form fields have programmatically associated labels
- [ ] Validation errors and async content changes are announced, not just displayed
- [ ] Custom tappable widgets expose the correct role (button, header, etc.), not just visual styling
- [ ] Related content is merged into one semantic node where fragmenting it would be noise
- [ ] Screen/dialog titles are announced on navigation
- [ ] Text scales correctly at the largest supported system font size without breaking layout
- [ ] Automated accessibility checks pass, AND a manual TalkBack/VoiceOver pass was done on new/changed screens
- [ ] Loading, empty, and error states were checked, not just the populated happy path

## Findings report format (Review mode)

When reviewing existing code, report findings as:

```
[SEVERITY] Short title
File: path/to/File.kt:line
WCAG: 1.1.1 Non-text Content (or relevant success criterion)
Issue: What's wrong, in one sentence.
Impact: Who this blocks and how — e.g. "TalkBack users cannot tell this is tappable."
Fix: Specific remediation (imperative # from above where relevant).
```

Severity guide: **Critical** = blocks task completion entirely for screen reader or switch-access users (unlabeled primary action, untappable custom button). **High** = usable but significantly degraded (fragmented/confusing announcement order, undersized primary touch targets). **Medium** = friction without full blockage (missing decorative-image exclusion, contrast slightly under threshold on secondary text). **Low** = polish (generic-but-present label that could be more descriptive).

## Troubleshooting

- If TalkBack announces an element twice, check for both a `contentDescription` on a container *and* on its focusable child — merge or exclude one.
- If a custom widget is skipped entirely by the screen reader, check `importantForAccessibility`/`ExcludeSemantics` isn't set on it or an ancestor by mistake.
- If contrast checks pass in isolation but look wrong in the running app, check for opacity/alpha applied at render time that isn't reflected in the source color value used for the calculation.
