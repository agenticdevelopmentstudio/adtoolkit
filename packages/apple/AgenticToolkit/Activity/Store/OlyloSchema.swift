// Guarded on the module rather than the platform: every store this schema
// covers is reachable wherever `BoundedDatabase` is, and the version space has
// to be identical on all of them (see below).
#if canImport(AgenticToolkitDatabase)
import Foundation
import AgenticToolkitDatabase

/// The one ordered registry of schema versions for the Olylo database.
///
/// Every store in this module — usage capture, context events, settings —
/// writes into the *same* SQLite file and shares one `schema_migrations`
/// table, so a version number is a property of the database, not of whichever
/// store happens to introduce it. Before this type existed each store declared
/// its own slice of the numbering and applied only that slice, which had two
/// consequences worth naming:
///
/// 1. **The applied set depended on which features were switched on.** The
///    usage migrations were reachable only from `UsageCollector.start()`, so a
///    daemon on which capture had never been enabled ran versions 2 and 3 and
///    skipped 1 and 4 — a legal state that no reader could distinguish from a
///    partially-failed upgrade, and one where "the highest applied version" is
///    not a fact about the schema at all.
/// 2. **Nothing owned the next free number.** Each store picked its own, by
///    comment ("version 2 — version 1 is the pre-existing usage schema"), and
///    the only thing standing between two stores and the same number was that
///    a human had read all of them.
///
/// So: one list, applied in full by whoever opens the database first. Every
/// store's `runMigrations()` is now a call to ``migrate(_:)`` and any single
/// one of them brings the whole database up to date. The migrations are listed
/// unconditionally — the usage tables are created on iOS too, where nothing
/// writes to them — because the alternative is a version space that means
/// different things on different platforms, which is the same defect as (1).
///
/// Adding a version: append to ``migrations``, never edit an existing entry.
/// A migration is frozen the moment it has run anywhere.
public enum OlyloSchema {

    /// Applies every migration this database is missing, in version order.
    ///
    /// Idempotent: ``SchemaMigrator`` skips versions already recorded, and
    /// each step runs in one transaction with its own bookkeeping row.
    public static func migrate(_ database: BoundedDatabase) throws {
        try SchemaMigrator(database: database).migrate(migrations)
    }

    /// The registry. Order in the array is irrelevant (the migrator sorts by
    /// version) but kept ascending so a reader can find the next free number.
    public static let migrations: [SchemaMigration] = [
        SchemaMigration(version: 1, sql: usageSchemaSQL),
        SchemaMigration(version: 2, sql: contextSchemaSQL),
        SchemaMigration(version: 3, sql: settingsSchemaSQL),
        SchemaMigration(version: 4, sql: captureSpanMachineSQL),
        SchemaMigration(version: 5, sql: contextEventSequenceIndexSQL),
        SchemaMigration(version: 6, sql: appLifecycleSchemaSQL),
        SchemaMigration(version: 7, sql: inputChangeSQL),
        SchemaMigration(version: 8, sql: appFocusURLSQL),
        SchemaMigration(version: 9, sql: inputSampleReplaySQL),
        SchemaMigration(version: 10, sql: locationMovementSQL),
    ]

    // MARK: - 1. Usage capture

    private static let usageSchemaSQL = """
        CREATE TABLE IF NOT EXISTS usage_focus_segments (
          id TEXT PRIMARY KEY, started_at TEXT NOT NULL, ended_at TEXT,
          duration_ms INTEGER, app_bundle_id TEXT NOT NULL, app_name TEXT NOT NULL,
          pid INTEGER NOT NULL, window_id INTEGER NOT NULL, window_title TEXT NOT NULL,
          document_path TEXT, end_reason TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS usage_window_events (
          id TEXT PRIMARY KEY, occurred_at TEXT NOT NULL, kind TEXT NOT NULL,
          app_bundle_id TEXT NOT NULL, app_name TEXT NOT NULL, pid INTEGER NOT NULL,
          window_id INTEGER NOT NULL, window_title TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS usage_capture_spans (
          id TEXT PRIMARY KEY, started_at TEXT NOT NULL, last_heartbeat_at TEXT NOT NULL,
          ended_at TEXT, end_reason TEXT);
        CREATE INDEX IF NOT EXISTS idx_seg_started ON usage_focus_segments(started_at);
        CREATE INDEX IF NOT EXISTS idx_seg_bundle ON usage_focus_segments(app_bundle_id);
        CREATE INDEX IF NOT EXISTS idx_winevt_occurred ON usage_window_events(occurred_at);
        """

    // MARK: - 2. Context events

    private static let contextSchemaSQL = """
        CREATE TABLE IF NOT EXISTS machine (
          id             TEXT PRIMARY KEY,
          platform       TEXT NOT NULL,
          native_id      TEXT,
          native_id_kind TEXT,
          hostname       TEXT,
          model          TEXT,
          os_version     TEXT,
          first_seen_at  TEXT NOT NULL,
          last_seen_at   TEXT NOT NULL);

        CREATE TABLE IF NOT EXISTS machine_link (
          machine_id        TEXT NOT NULL REFERENCES machine(id),
          linked_machine_id TEXT NOT NULL REFERENCES machine(id),
          linked_at         TEXT NOT NULL,
          note              TEXT,
          PRIMARY KEY (machine_id, linked_machine_id));

        CREATE INDEX IF NOT EXISTS idx_machine_link_linked ON machine_link(linked_machine_id);

        CREATE TABLE IF NOT EXISTS context_event (
          id              TEXT PRIMARY KEY,
          machine_id      TEXT NOT NULL REFERENCES machine(id),
          occurred_at     TEXT NOT NULL,
          kind            TEXT NOT NULL,
          capture_span_id TEXT);

        CREATE INDEX IF NOT EXISTS idx_ctx_evt_occurred ON context_event(occurred_at);
        CREATE INDEX IF NOT EXISTS idx_ctx_evt_kind     ON context_event(kind, occurred_at);
        CREATE INDEX IF NOT EXISTS idx_ctx_evt_machine  ON context_event(machine_id, occurred_at);

        CREATE TABLE IF NOT EXISTS context_event_app_focus (
          event_id             TEXT PRIMARY KEY REFERENCES context_event(id),
          bundle_id            TEXT NOT NULL,
          app_name             TEXT NOT NULL,
          pid                  INTEGER NOT NULL,
          executable_path      TEXT,
          window_id            INTEGER,
          window_title         TEXT,
          document_path        TEXT,
          document_size        INTEGER,
          document_modified_at TEXT,
          document_type        TEXT);

        CREATE INDEX IF NOT EXISTS idx_ctx_focus_bundle ON context_event_app_focus(bundle_id);

        CREATE TABLE IF NOT EXISTS context_event_window (
          event_id     TEXT PRIMARY KEY REFERENCES context_event(id),
          change       TEXT NOT NULL,
          bundle_id    TEXT NOT NULL,
          app_name     TEXT NOT NULL,
          pid          INTEGER NOT NULL,
          window_id    INTEGER NOT NULL,
          window_title TEXT);

        CREATE TABLE IF NOT EXISTS context_event_network (
          event_id       TEXT PRIMARY KEY REFERENCES context_event(id),
          interface_type TEXT NOT NULL,
          is_satisfied   INTEGER NOT NULL,
          ssid           TEXT,
          bssid          TEXT,
          is_expensive   INTEGER,
          is_constrained INTEGER);

        CREATE INDEX IF NOT EXISTS idx_ctx_net_ssid ON context_event_network(ssid);

        CREATE TABLE IF NOT EXISTS context_event_location (
          event_id            TEXT PRIMARY KEY REFERENCES context_event(id),
          latitude            REAL NOT NULL,
          longitude           REAL NOT NULL,
          horizontal_accuracy REAL,
          altitude            REAL,
          vertical_accuracy   REAL,
          speed               REAL,
          course              REAL);

        CREATE TABLE IF NOT EXISTS context_event_input (
          event_id                 TEXT PRIMARY KEY REFERENCES context_event(id),
          seconds_since_key        REAL,
          seconds_since_mouse_move REAL,
          seconds_since_click      REAL,
          seconds_since_scroll     REAL,
          key_count_delta          INTEGER,
          mouse_count_delta        INTEGER,
          interval_ms              INTEGER);

        CREATE TABLE IF NOT EXISTS context_event_session (
          event_id TEXT PRIMARY KEY REFERENCES context_event(id),
          change   TEXT NOT NULL);

        CREATE TABLE IF NOT EXISTS context_event_power (
          event_id    TEXT PRIMARY KEY REFERENCES context_event(id),
          source      TEXT NOT NULL,
          percent     INTEGER,
          is_charging INTEGER);
        """

    // MARK: - 3. Settings

    private static let settingsSchemaSQL = """
        CREATE TABLE IF NOT EXISTS settings (
          key   TEXT PRIMARY KEY,
          value TEXT NOT NULL);
        """

    // MARK: - 4. Capture spans carry a machine

    private static let captureSpanMachineSQL = """
        -- The spec's "capture_span carries machine_id". Added by ALTER rather
        -- than by editing migration 1: migration 1 is frozen the moment it has
        -- ever run anywhere.
        ALTER TABLE usage_capture_spans ADD COLUMN machine_id TEXT;
        CREATE INDEX IF NOT EXISTS idx_span_machine
          ON usage_capture_spans(machine_id, started_at);
        """

    // MARK: - 5. The log reader's own index

    /// `ContextStore.events(_:)` pages the log with
    /// `WHERE kind IN (…) ORDER BY rowid`, and no version-2 index serves it:
    /// `idx_ctx_evt_kind` is `(kind, occurred_at)`, whose entries are ordered
    /// by timestamp within a kind, so the planner had to materialise every
    /// matching row and sort it. A plain `(kind)` index carries SQLite's
    /// implicit trailing rowid, which is exactly the order the reader wants.
    ///
    /// Measured on this query (three kinds, limit 500) against synthetic
    /// tables: without the index 2.7 ms at 20k rows and 50 ms at 400k, rising
    /// with the table; with it, 0.42 ms flat from 20k to 2M rows.
    private static let contextEventSequenceIndexSQL = """
        CREATE INDEX IF NOT EXISTS idx_ctx_evt_kind_seq ON context_event(kind);
        """

    // MARK: - 6. App lifecycle

    private static let appLifecycleSchemaSQL = """
        CREATE TABLE IF NOT EXISTS context_event_app_lifecycle (
          event_id  TEXT PRIMARY KEY REFERENCES context_event(id),
          change    TEXT NOT NULL,
          bundle_id TEXT NOT NULL,
          app_name  TEXT NOT NULL,
          pid       INTEGER NOT NULL);
        CREATE INDEX IF NOT EXISTS idx_ctx_lifecycle_bundle
          ON context_event_app_lifecycle(bundle_id);
        """

    // MARK: - 7. Input events became transitions

    /// `context_event_input` used to hold one row per thirty-second poll,
    /// whether or not anything had happened. It now holds two rows per idle
    /// period: the moment input stopped and the moment it resumed. `change`
    /// says which, and `idle_seconds` carries the measured length of the
    /// absence on the row that ends one.
    ///
    /// `ALTER` rather than an edit to migration 2, which is frozen the moment
    /// it has ever run anywhere — the precedent migration 4 set.
    ///
    /// The backfill is the load-bearing half. Every existing row *is* a
    /// periodic sample, and `sample` is the ``InputChange`` case that says so;
    /// leaving them NULL would make them indistinguishable from a transition
    /// whose kind was lost, and the reader would have to guess. `DEFAULT` on
    /// the new column would have done the same job for these rows, but it
    /// would also silently supply `sample` to a future insert that forgot to
    /// name the column — so the value is placed once, here, and every insert
    /// from now on states its own.
    private static let inputChangeSQL = """
        ALTER TABLE context_event_input ADD COLUMN change TEXT;
        ALTER TABLE context_event_input ADD COLUMN idle_seconds REAL;
        UPDATE context_event_input SET change = 'sample' WHERE change IS NULL;
        """

    // MARK: - 8. A browser's address is not a document path

    /// `document_path` was written from `kAXDocumentAttribute`, which document
    /// apps answer with a file and Chromium browsers answer with the page URL.
    /// Both landed in the one column, so "which files did I work on" answered
    /// with a list of web pages — on this machine the great majority of the
    /// column's rows were Brave and Chrome URLs, not files.
    ///
    /// The backfill moves them, using the same test ``WindowAddress`` applies
    /// going forward: a scheme marks a URL. `file://` needs no case here — the
    /// adapter unwrapped those to plain paths before they ever reached the
    /// column — and a real path containing `://` is not a thing this schema
    /// has to defend against.
    ///
    /// No index on `url`: nothing queries by it yet, and one is an `ALTER`
    /// away when something does.
    private static let appFocusURLSQL = """
        ALTER TABLE context_event_app_focus ADD COLUMN url TEXT;
        UPDATE context_event_app_focus
           SET url = document_path, document_path = NULL
         WHERE document_path LIKE '%://%';
        """

    // MARK: - 9. The periodic input samples become the transitions they imply

    /// Migration 7 gave the old per-tick rows a name (`sample`) so they would
    /// not be mistaken for transitions. It left them in place, and on this
    /// machine that was 14,653 of the 14,654 input rows — five days in which
    /// every timeline and event log was almost entirely one row per thirty
    /// seconds saying nothing had changed.
    ///
    /// This converts them instead of deleting them, because they are not
    /// noise: each one records seconds-since-last-key/move/click/scroll, which
    /// is exactly the input ``InputActivityTrigger`` consumes. Replaying that
    /// series through the trigger's own rule reconstructs precisely the rows
    /// the current trigger would have written, so no absence is lost — 14,653
    /// samples become 115 transitions describing the same five days.
    ///
    /// **The replay is the trigger's rule, restated in SQL.** `silence` is the
    /// most recent of the four readings (a missing reading is not evidence of
    /// absence, so it is ignored rather than counted as quiet); the user is
    /// active while `silence` is under the threshold; and a tick emits only
    /// when that verdict differs from the previous tick's. `wasActive` in the
    /// trigger is always the previous tick's verdict — it is assigned on every
    /// tick that sets it at all — which is what lets a `LAG` stand in for the
    /// trigger's running state and keeps this a windowed query rather than a
    /// recursive one.
    ///
    /// **Run boundaries come from `interval_ms IS NULL`.** The trigger clears
    /// `lastEmitted` in `start()`, so the first row of every run has no
    /// interval and every later row has one. That marker is complete for
    /// sample rows, because back then every tick emitted; there is no need to
    /// guess a run boundary from a time gap, and this database's seven NULLs
    /// against zero intervals over 60s say the marker found them all.
    ///
    /// **Rows are updated, not recreated.** A transition corresponds to a tick
    /// that really happened, so the tick's own row becomes it: the event id,
    /// machine, and capture span survive, and SQLite is never asked to mint a
    /// UUID. `occurred_at` moves to the backdated instant the trigger would
    /// have used — `at - silence`, the moment input actually stopped or
    /// resumed — except on a run's first row, which is dated where it was for
    /// the reason the trigger does the same: the silence may predate the run
    /// by hours, and a row placed before the trigger started would claim to
    /// have watched something nobody watched.
    ///
    /// **The counters telescope.** A sample's `key_count_delta` is its
    /// difference from the previous *tick*; a transition's is its difference
    /// from the previous *emitted row*. Summing the samples between two
    /// emissions gives exactly that, because consecutive differences telescope
    /// — which is why the deltas are recovered rather than dropped.
    ///
    /// The threshold is this machine's own setting, not a constant: the
    /// reconstruction has to agree with how the trigger is recording *now*, or
    /// history and new data would describe presence by two different rules.
    /// `180` is ``InactivityThreshold/defaultSeconds`` for a database whose
    /// user has never set one.
    private static let inputSampleReplaySQL = """
        CREATE TEMP TABLE input_replay AS
        WITH threshold(seconds) AS (
          SELECT CAST(COALESCE((SELECT value FROM settings
                                 WHERE key = 'trigger.input.inactivity_seconds'),
                               '180') AS REAL)
        ),
        sample AS (
          SELECT e.id                            AS event_id,
                 e.machine_id                    AS machine_id,
                 e.occurred_at                   AS at_text,
                 julianday(e.occurred_at)        AS at_jd,
                 i.interval_ms                   AS interval_ms,
                 COALESCE(i.key_count_delta, 0)  AS key_delta,
                 COALESCE(i.mouse_count_delta, 0) AS mouse_delta,
                 CASE WHEN i.seconds_since_key IS NULL
                       AND i.seconds_since_mouse_move IS NULL
                       AND i.seconds_since_click IS NULL
                       AND i.seconds_since_scroll IS NULL
                      THEN NULL
                      ELSE MIN(COALESCE(i.seconds_since_key,        1e18),
                               COALESCE(i.seconds_since_mouse_move, 1e18),
                               COALESCE(i.seconds_since_click,      1e18),
                               COALESCE(i.seconds_since_scroll,     1e18))
                 END                             AS silence
            FROM context_event e
            JOIN context_event_input i ON i.event_id = e.id
           WHERE i.change = 'sample'
        ),
        ordered AS (
          SELECT s.*, ROW_NUMBER() OVER (PARTITION BY s.machine_id
                                             ORDER BY s.at_text, s.event_id) AS n
            FROM sample s
        ),
        runs AS (
          SELECT o.*,
                 SUM(CASE WHEN o.interval_ms IS NULL THEN 1 ELSE 0 END)
                     OVER (PARTITION BY o.machine_id ORDER BY o.n
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS run
            FROM ordered o
        ),
        state AS (
          SELECT r.*,
                 CASE WHEN COALESCE(r.silence, 1e18) < (SELECT seconds FROM threshold)
                      THEN 1 ELSE 0 END AS active,
                 SUM(r.key_delta)   OVER (PARTITION BY r.machine_id, r.run ORDER BY r.n
                                          ROWS BETWEEN UNBOUNDED PRECEDING
                                                   AND CURRENT ROW) AS key_total,
                 SUM(r.mouse_delta) OVER (PARTITION BY r.machine_id, r.run ORDER BY r.n
                                          ROWS BETWEEN UNBOUNDED PRECEDING
                                                   AND CURRENT ROW) AS mouse_total
            FROM runs r
        ),
        witnessed AS (
          SELECT s.*, LAG(s.active) OVER (PARTITION BY s.machine_id, s.run
                                              ORDER BY s.n) AS was_active
            FROM state s
        ),
        transitions AS (
          SELECT w.*, (w.was_active IS NULL) AS first_of_run
            FROM witnessed w
           WHERE w.was_active IS NULL OR w.was_active <> w.active
        ),
        timed AS (
          SELECT t.*,
                 CASE WHEN t.was_active IS NULL OR t.silence IS NULL
                      THEN t.at_jd
                      ELSE t.at_jd - t.silence / 86400.0
                 END AS new_jd
            FROM transitions t
        )
        SELECT t.event_id,
               CASE WHEN t.active THEN 'active' ELSE 'inactive' END AS change,
               strftime('%Y-%m-%dT%H:%M:%fZ', t.new_jd) AS new_at,
               CASE
                 WHEN t.first_of_run AND t.active = 0 THEN t.silence
                 WHEN NOT t.first_of_run AND t.active = 1
                   THEN MAX(0.0, (t.new_jd - LAG(t.new_jd) OVER w) * 86400.0)
                 ELSE NULL
               END AS idle_seconds,
               CASE WHEN t.first_of_run THEN NULL
                    ELSE t.key_total - LAG(t.key_total) OVER w END AS key_count_delta,
               CASE WHEN t.first_of_run THEN NULL
                    ELSE t.mouse_total - LAG(t.mouse_total) OVER w END AS mouse_count_delta,
               CASE WHEN t.first_of_run THEN NULL
                    ELSE CAST(ROUND((t.new_jd - LAG(t.new_jd) OVER w) * 86400000.0) AS INTEGER)
               END AS interval_ms
          FROM timed t
        WINDOW w AS (PARTITION BY t.machine_id, t.run ORDER BY t.n);

        UPDATE context_event_input
           SET change            = (SELECT r.change FROM input_replay r
                                     WHERE r.event_id = context_event_input.event_id),
               idle_seconds      = (SELECT r.idle_seconds FROM input_replay r
                                     WHERE r.event_id = context_event_input.event_id),
               key_count_delta   = (SELECT r.key_count_delta FROM input_replay r
                                     WHERE r.event_id = context_event_input.event_id),
               mouse_count_delta = (SELECT r.mouse_count_delta FROM input_replay r
                                     WHERE r.event_id = context_event_input.event_id),
               interval_ms       = (SELECT r.interval_ms FROM input_replay r
                                     WHERE r.event_id = context_event_input.event_id)
         WHERE event_id IN (SELECT event_id FROM input_replay);

        UPDATE context_event
           SET occurred_at = (SELECT r.new_at FROM input_replay r
                               WHERE r.event_id = context_event.id)
         WHERE id IN (SELECT event_id FROM input_replay);

        CREATE TEMP TABLE input_dropped AS
          SELECT event_id FROM context_event_input
           WHERE change = 'sample'
             AND event_id NOT IN (SELECT event_id FROM input_replay);

        DELETE FROM context_event_input WHERE event_id IN (SELECT event_id FROM input_dropped);
        DELETE FROM context_event       WHERE id       IN (SELECT event_id FROM input_dropped);

        DROP TABLE input_replay;
        DROP TABLE input_dropped;
        """

    // MARK: - 10. Location rows that describe one spot become one row

    /// `SystemLocationSource` asked CoreLocation for every fix
    /// (`kCLDistanceFilterNone`) until it was given a 100m
    /// `distanceFilter`. The rows written before that are still here: 1,387 of
    /// them on this machine, all inside a single accuracy radius, describing
    /// one desk.
    ///
    /// `LocationTrigger` records 1,187 for the same pile, and both are right:
    /// that is the count that argued for the filter, taken the day the filter
    /// was written, and this is the count this migration actually faces. The
    /// installed daemon went on writing unfiltered rows until it was replaced,
    /// so the pile kept growing for a day after the fix existed. Whatever the
    /// number is when this runs elsewhere, the backfill counts nothing — it
    /// replays the filter over whatever it finds.
    ///
    /// This replays the filter CoreLocation now applies. `distanceFilter`
    /// measures from the last fix *delivered*, not from the previous fix, so
    /// the reconstruction has to walk the series carrying that reference
    /// forward — which is why this is a recursive CTE and not a window
    /// function. A fix 100m or more from the reference is kept and becomes the
    /// new reference; anything nearer is a fix CoreLocation would never have
    /// delivered, and it goes.
    ///
    /// **100 is written here rather than read from
    /// `SystemLocationSource.movementThresholdMetres`.** A migration's SQL is
    /// frozen once it has run anywhere, and interpolating a constant would
    /// make a later tuning of the threshold silently change what this
    /// migration did to databases that had not run it yet. The number is a
    /// snapshot of the rule on the day it was applied, and it is allowed to
    /// drift from the live constant.
    ///
    /// Distance is the equirectangular approximation, which is exact enough by
    /// several orders of magnitude at 100m. The `cos` term is why the
    /// comparison is against squared metres: no square root is needed to ask
    /// whether something is at least 100m away.
    ///
    /// The walk joins on `machine_id` as well as position, so a database
    /// holding two machines' events (what `machine_link` exists for) walks
    /// each machine's series separately instead of reading a colleague's
    /// office as a 3,000km journey.
    private static let locationMovementSQL = """
        CREATE TEMP TABLE location_walk AS
        WITH RECURSIVE ordered AS (
          SELECT e.machine_id AS machine_id,
                 ROW_NUMBER() OVER (PARTITION BY e.machine_id
                                        ORDER BY e.occurred_at, e.id) AS n,
                 e.id         AS event_id,
                 l.latitude   AS lat,
                 l.longitude  AS lon
            FROM context_event e
            JOIN context_event_location l ON l.event_id = e.id
        ),
        walk(machine_id, n, event_id, keep, ref_lat, ref_lon) AS (
          SELECT machine_id, n, event_id, 1, lat, lon FROM ordered WHERE n = 1
          UNION ALL
          SELECT o.machine_id, o.n, o.event_id,
                 CASE WHEN ((o.lat - w.ref_lat) * 110574.0)
                         * ((o.lat - w.ref_lat) * 110574.0)
                         + ((o.lon - w.ref_lon) * 111320.0
                            * cos(w.ref_lat * 0.017453292519943295))
                         * ((o.lon - w.ref_lon) * 111320.0
                            * cos(w.ref_lat * 0.017453292519943295))
                         >= 10000.0 THEN 1 ELSE 0 END,
                 CASE WHEN ((o.lat - w.ref_lat) * 110574.0)
                         * ((o.lat - w.ref_lat) * 110574.0)
                         + ((o.lon - w.ref_lon) * 111320.0
                            * cos(w.ref_lat * 0.017453292519943295))
                         * ((o.lon - w.ref_lon) * 111320.0
                            * cos(w.ref_lat * 0.017453292519943295))
                         >= 10000.0 THEN o.lat ELSE w.ref_lat END,
                 CASE WHEN ((o.lat - w.ref_lat) * 110574.0)
                         * ((o.lat - w.ref_lat) * 110574.0)
                         + ((o.lon - w.ref_lon) * 111320.0
                            * cos(w.ref_lat * 0.017453292519943295))
                         * ((o.lon - w.ref_lon) * 111320.0
                            * cos(w.ref_lat * 0.017453292519943295))
                         >= 10000.0 THEN o.lon ELSE w.ref_lon END
            FROM walk w
            JOIN ordered o ON o.machine_id = w.machine_id AND o.n = w.n + 1
        )
        SELECT event_id, keep FROM walk;

        CREATE TEMP TABLE location_dropped AS
          SELECT event_id FROM location_walk WHERE keep = 0;

        DELETE FROM context_event_location WHERE event_id IN (SELECT event_id FROM location_dropped);
        DELETE FROM context_event          WHERE id       IN (SELECT event_id FROM location_dropped);

        DROP TABLE location_walk;
        DROP TABLE location_dropped;
        """
}
#endif
