
This is the shared foundation for every transient chooser panel in the app —
the command palette and the quick-pick / input-box panels an extension can
ask for. It owns everything those choosers have in common: a floating,
titleless panel hosting an extending component's content as a genuine child
in the content hierarchy, pointer-relative positioning near the top of the
screen, activation-before-show, dismissal when the panel loses key status,
and a reentrancy guard around the single dismissal path. An extending
component decides exactly three things: the panel's size (via the
`contentRect` value passed at construction), whether losing focus dismisses
the panel (`dismissesOnFocusLoss`), and what happens on the way in and out
(the initial-focus hook and the pre-close hook). This recipe documents only
what this shared foundation itself does; an extending component's own
sizing, content, and focus/dismissal behavior belongs to that component's
own recipe.

