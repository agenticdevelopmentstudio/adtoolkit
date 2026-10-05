
Setting observing is the contract a settings view binds to instead of a concrete store. It exposes one current value that can be read and written, and an optional change callback that is told after a write has landed. A persisted-settings observer and a closure-backed observer both satisfy it, so a view can be driven by user defaults or by plain getter and setter closures without knowing which.

