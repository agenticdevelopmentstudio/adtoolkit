
This settings-card vocabulary is the declarative-framework counterpart to
the same panel chrome a native-framework component vocabulary draws
elsewhere in this cookbook: a caption above a rounded, elevated card (the
group container), the rounded card itself, one row's padding inside the
card, the hairline between two rows, a live-filtering search field
wrapping a genuine native search control, and a panel-level padding
operation. All six read the same shared layout metrics the sibling group
view component uses, so a panel composed either way lands on the same
grid. Rows are composed by the caller rather than collected by the
container, so a card can hold a run of uniform rows, an action row, and an
empty state without the container needing to know which is which.

