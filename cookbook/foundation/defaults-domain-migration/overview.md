
Carries an app's saved settings across a bundle-identifier change. The standard preferences domain is the bundle identifier, so renaming the bundle silently starts the app on an empty domain and every setting the user made is gone. The migration copies the legacy domain into the new one exactly once: only while the new domain holds nothing, so a user who has already changed a setting under the new identifier is never overwritten. The legacy domain is left in place, because it costs a small file and deleting it would make a downgrade lose everything instead.

