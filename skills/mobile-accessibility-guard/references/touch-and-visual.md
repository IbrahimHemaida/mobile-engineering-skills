# Touch Targets & Visual Accessibility — Extended Reference

## Touch target sizing

**Minimums**: Material Design (Android) recommends 48x48dp minimum; Apple's Human Interface Guidelines recommend 44x44pt. WCAG 2.1 AA (2.5.5, technically AAA but treated as a practical baseline by most mobile teams) uses 44x44 CSS px as its reference point. Target 48dp on Android and the Flutter equivalent regardless of platform, since it comfortably satisfies both platforms' own guidance.

**The icon can stay small — the tap target doesn't have to match it visually**:

```kotlin
// A visually 24dp icon with a 48dp tappable area via padding
IconButton(
    modifier = Modifier.size(48.dp), // tap target
    onClick = { /* ... */ }
) {
    Icon(
        imageVector = Icons.Default.Delete,
        modifier = Modifier.size(24.dp), // visual size
        contentDescription = "Delete item"
    )
}
```

```dart
// Flutter: IconButton has a built-in minimum tap target via
// VisualDensity/theme; verify it isn't shrunk below 48 by a
// custom ButtonStyle or a tightly constrained parent.
IconButton(
  iconSize: 24,
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
  icon: const Icon(Icons.delete),
  onPressed: onDelete,
  tooltip: 'Delete item',
)
```

**Adjacent small targets** (e.g. a row of icon actions) need spacing between them, not just individual sizing — a screen reader or motor-impaired user hitting the wrong adjacent target is a common failure even when each target individually meets 48dp.

## Color contrast

**WCAG 2.1 AA thresholds**:
- Normal text (under 18pt, or under 14pt bold): **4.5:1**
- Large text (18pt+, or 14pt+ bold): **3:1**
- UI components and graphical objects that convey meaning (icons, chart lines, focus indicators, form field borders): **3:1**

**Contrast ratio formula** (relative luminance-based):

```
ratio = (L1 + 0.05) / (L2 + 0.05)
```

where L1 is the relative luminance of the lighter color and L2 the darker, and relative luminance is computed from the sRGB channel values per the WCAG spec (not a simple average of RGB — gamma-corrected per channel then weighted: `0.2126*R + 0.7152*G + 0.0722*B`).

**In practice**: don't hand-calculate this. Check contrast with a tool against the actual rendered hex values:
- Android Accessibility Scanner flags contrast issues automatically during a screen scan.
- Any WCAG contrast checker (WebAIM's is a common reference) takes two hex values and returns pass/fail per level.

**Check the rendered value, not the design token** — a color with alpha/opacity applied at render time (e.g. `Color.Black.copy(alpha = 0.6f)` over a white background) has a different *effective* contrast than the base color alone. Compute against the composited result.

## Common contrast failure patterns

- **Placeholder text styled too light**: placeholder/hint text is often deliberately muted, but muted below 4.5:1 against the field background fails for anyone who actually needs to read it (not just decorative).
- **Disabled-looking active elements**: a "disabled" gray applied to a button that's actually tappable — this is both a contrast issue and a discoverability issue (looks non-interactive).
- **Text over images/gradients**: contrast must hold across the *worst* point of the image/gradient behind the text, not just the average — add a scrim/overlay if the image varies too much.
- **Dark mode inversions that weren't re-checked**: a color pair that passed in light mode doesn't automatically pass when both colors are algorithmically inverted for dark mode — verify both themes independently.

## Dynamic text scaling

**Android**: always use `sp` (scale-independent pixels) for text size, never `dp`. `sp` respects the user's system font size setting; `dp` doesn't scale with it, silently breaking accessibility for users who've increased their system text size.

```kotlin
// Correct
android:textSize="16sp"

// Wrong — ignores user's font size preference entirely
android:textSize="16dp"
```

**Flutter**: text respects `MediaQuery.textScaler` (formerly `textScaleFactor`) by default via `Text` widgets — the failure mode is usually a parent that constrains height/width tightly enough that scaled text clips or overflows rather than reflowing.

```dart
// Test at maximum supported scale before shipping a new screen
MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
  child: MyScreen(),
)
```

**What breaks under scaling** (check these specifically, they're the recurring failure points):
- Fixed-height containers that clip scaled text instead of growing.
- Multi-line text set to `maxLines: 1` with `overflow: ellipsis` where the truncated content is essential (a price, a critical label).
- Icon-and-text rows where the icon doesn't reflow/wrap with the now-taller text, causing overlap.

Test at the largest system font size the platform allows (Android: "Largest" in Settings → Accessibility → Font size; iOS: largest Dynamic Type / accessibility sizes), not just one step above default — accessibility-motivated users often use the largest setting, not a modest bump.
