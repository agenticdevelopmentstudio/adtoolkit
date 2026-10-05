
The window-context global shortcut scheme. It has two parts:

- **The shortcut scheme** — fourteen named global shortcuts, each defaulting to the scheme's own modifier pair plus a distinct key, plus two ordered lists: the nine switch-by-index names, and all fourteen names together.
- **The shortcut manager** — a component that, on construction, registers a key-down handler for every one of those names, dispatches each to a window-contexts model action, and reserves the chords with the app's key-command registry so the app's own key-command settings refuse them.

Use it once per app that hosts window contexts: the host constructs one manager at feature start and retains it for the app's lifetime. The model's behavior behind each action belongs to [Window Matching System Windows Contexts](adtoolkit://cookbook/system/system-windows/window-contexts); this recipe covers only the scheme and the dispatch.

