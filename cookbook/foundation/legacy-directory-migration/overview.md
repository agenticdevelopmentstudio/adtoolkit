
Moves an app's data directory from a legacy location to its new one exactly once, at launch, after a rename of the app or its support folder. The only operations it uses are an atomic rename on the same volume that refuses to replace an existing destination, and removal of an empty directory. It never copies, merges or deletes data. When both directories hold data, it touches neither and tells the caller, because merging two live stores is not something a launch-time migration may guess at.

A fresh launch can create the new directory before the migration runs. The caller can name **markers**, files whose presence at the top level of the new directory proves it holds real data. A new directory with none of them is a placeholder: an empty one is removed, and a non-empty one is renamed aside so the legacy directory can take its place.

