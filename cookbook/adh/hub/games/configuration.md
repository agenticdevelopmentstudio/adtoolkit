
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ecosystemId` | `string \| undefined` (`gamesApi.list`/`forEcosystem`) | `undefined` | Column-filters the catalog to one ecosystem; omitted, the call returns every game the caller can see |
| `gameId` | `string` (`childApi(...).list`/`create`) | none — required | The parent game every child-collection call is scoped to; sent as a query filter on `list`, a body field on `create` |
| `GAMES` (`/api/game/games`) | internal constant | fixed | Base route for every generic-CRUD `gamesApi` call |
| `DEFINITIONS` (`/api/game/definitions`) | internal constant | fixed | Base route for `gameDefinitionsApi` |
| `EFFECTS` (`/api/game/effects`) | internal constant | fixed | Base route for `gameEffectsApi` |
| `MAPPINGS` (`/api/game/mappings`) | internal constant | fixed | Base route for `gameMappingsApi` |
| `ENGINE_CONFIG_EMPTY` (`{}`) | internal constant | fixed | The JSON value `engineConfig`'s empty box crosses to/from, matching `games.engine_config`'s `NOT NULL DEFAULT '{}'` |
| `DEFINITION_DATA_EMPTY` (`null`) | internal constant | fixed | The JSON value `data`'s empty box crosses to/from, matching `definitions.data`'s nullable column |

