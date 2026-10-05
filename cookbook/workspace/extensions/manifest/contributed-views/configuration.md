
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| contributions (to building views) | the manifest's decoded contributions | none — required | The already-decoded `views`/`viewsContainers` dictionaries this call reads; an empty contributions value supplies no entries for either when the manifest declares no `contributes` key at all |
| manifest (to building views) | the extension manifest | none — required | Supplies the manifest's identifier (`publisher.name`, case-folded), used to build every `extensionIdentifier` field and every `registryID` |
| the codicon-to-symbol table (internal) | a fixed mapping | fixed at build time | Not caller-configurable; the same table answers every call, for every extension |

