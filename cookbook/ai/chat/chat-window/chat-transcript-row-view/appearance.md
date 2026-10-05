
- **Corner radius**: 8pt (the row's own background, clipping the hover fill and selection border)
- **Padding**: 8pt horizontal inset from the row's outer edge to the header/bubble/timestamp content edge on the speaker's side; 6pt vertical inset from the row's top to the header (plus 3pt extra, so 9pt total) and from the row's bottom to the timestamp
- **Font**: Caption font (theme palette `.caption`) for the timestamp and the failure label
- **Background**: Hover fill only — theme `.selection` color at 18% alpha when hovered and pressable; fully transparent otherwise. The row has no default fill.
- **Foreground/Text**: Timestamp uses the theme's `.timestampText` color; failure label uses the theme's `.danger` color
- **Border**: 2pt solid, theme `.selection` color, drawn only when `isSelected` is `true`; no border otherwise
- **Shadow**: None (not set in source)
- **Min/Max size**: Bubble width capped at the max-bubble-width calculation, `max(rowWidth - 88, 80)`; app icon is a fixed 28×28pt with an 8pt gap to the bubble column

