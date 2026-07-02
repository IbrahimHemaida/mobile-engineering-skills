# Screen Reader Patterns — Extended Reference

## Testing setup

**Android (TalkBack)**: Settings → Accessibility → TalkBack. Navigate by swiping right/left to move between elements, double-tap to activate. Turn on "Speak passwords" and "Verbose" logging during testing so nothing is silently skipped.

**Flutter (VoiceOver on iOS / TalkBack on Android)**: Flutter renders its own semantics tree that gets bridged to the platform's native accessibility API — test on-device with the platform's real screen reader, not just widget tests, since the bridge can behave subtly differently from the semantics tree in isolation.

**Widget tests**: use `SemanticsTester` to assert on the semantics tree directly:

```dart
testWidgets('delete button has accessible label', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(MyDeleteButton());
  expect(
    tester.getSemantics(find.byType(IconButton)),
    matchesSemantics(label: 'Delete item', isButton: true),
  );
  handle.dispose();
});
```

## Semantic grouping: when to merge, when to keep separate

**Merge** when several elements form one conceptual, single-tap unit:

```dart
// A card that's entirely one tap target — merge title + subtitle + icon
// into a single announcement instead of three separate swipe-stops.
MergeSemantics(
  child: InkWell(
    onTap: onCardTap,
    child: Row(children: [icon, Column(children: [title, subtitle])]),
  ),
)
```

**Keep separate** when each element has its own independent action:

```dart
// A list row with both a tap-to-open action AND a separate delete button —
// merging these would hide the delete action behind the row's announcement.
Row(children: [
  Expanded(child: GestureDetector(onTap: openItem, child: itemContent)),
  IconButton(onPressed: deleteItem, icon: Icon(Icons.delete), tooltip: 'Delete'),
])
```

Android equivalent: group with a parent `View` that has `contentDescription` set and children marked `importantForAccessibility="no"` when they shouldn't be independently focusable, or leave children focusable when they have independent actions.

## Live regions and announcements

**Android**:

```kotlin
// Announce a validation error the moment it appears
errorTextView.text = "Email is invalid"
errorTextView.announceForAccessibility("Email is invalid")

// Or mark a container as a live region so any text change inside it
// is announced automatically
errorContainer.accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE
```

**Flutter**:

```dart
Semantics(
  liveRegion: true,
  child: errorText != null ? Text(errorText!) : const SizedBox.shrink(),
)
```

Use `ACCESSIBILITY_LIVE_REGION_POLITE`/default `liveRegion` priority for most updates (waits for current speech to finish); reserve assertive/interrupting announcements for errors that block the user from proceeding, since interrupting a screen reader user mid-sentence for a non-critical update is itself a bad experience.

## Custom widget semantics (when the built-in widget doesn't fit)

**Android** — implement `AccessibilityDelegate` or override `onInitializeAccessibilityNodeInfo` to set the correct class name (so TalkBack announces "button" not "view") and custom actions:

```kotlin
ViewCompat.setAccessibilityDelegate(customView, object : AccessibilityDelegateCompat() {
    override fun onInitializeAccessibilityNodeInfo(host: View, info: AccessibilityNodeInfoCompat) {
        super.onInitializeAccessibilityNodeInfo(host, info)
        info.className = Button::class.java.name
        info.isClickable = true
        info.contentDescription = "Add to favorites"
    }
})
```

**Flutter** — `Semantics` widget with explicit role flags rather than relying on visual mimicry:

```dart
Semantics(
  button: true,
  label: 'Add to favorites',
  onTap: toggleFavorite,
  child: CustomStarIcon(filled: isFavorite),
)
```

## Reading order fixes

If TalkBack/VoiceOver traversal order doesn't match visual order (common after a layout refactor that reordered widgets without reordering the visual `Row`/`Column`/`ConstraintLayout` structure):

- **Flutter**: wrap the relevant section in `Semantics(sortKey: OrdinalSortKey(n))` to force an explicit order independent of widget tree position.
- **Android (ConstraintLayout)**: set `android:accessibilityTraversalBefore`/`accessibilityTraversalAfter` on the affected views to override the default tree-order traversal.

Prefer fixing the underlying layout order first — traversal overrides are a fallback for cases where visual and structural order genuinely can't match (e.g. an overlapping/absolutely-positioned element).
