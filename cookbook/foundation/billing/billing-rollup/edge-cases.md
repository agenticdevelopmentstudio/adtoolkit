
- Segments with no project are skipped by the roll and stay unassigned.
- Parallel overlapping sessions can make a later-starting segment end earlier; the entry end is the maximum end, not the last segment's end.
- A `setStatus` to the same status is a no-op and writes no audit row.
- `assignRepository` assigns and promotes in separate calls, so a failure in promotion leaves segments assigned but not yet rolled; the next pass rolls them.
- An overview with no entries reports zero buckets in `USD`.

