
- **Corner radius**: None set by this file.
- **Padding**: `0` stack spacing between the breadcrumb and the hosted content; no other padding is set directly by this file. The breadcrumb's own internal padding belongs to the breadcrumb component (out of scope; see its own recipe).
- **Font**: None set directly by this file. The gear-popover toggle rows' and reset button's fonts are their controls' own default fonts (out of scope).
- **Background**: The hosted content paints the theme's window-background role, via the shared theming root's default background-painting behavior — a semantic theme token, not a literal color.
- **Foreground/Text**: The hosted content inherits the theme's primary-text color role from the shared theming root. The reset button and toggle titles use their controls' default colors.
- **Border**: None set by this file.
- **Shadow**: None set by this file.
- **Min/Max size**: None set by this file beyond the initial `520`×`424` root-view frame (see **root-view-initial-frame**); layout constraints, not a min/max size, govern the view thereafter.

