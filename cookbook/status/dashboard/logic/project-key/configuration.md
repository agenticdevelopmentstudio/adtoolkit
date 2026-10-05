
| Option | Type | Default | Description |
|--------|------|---------|--------------|
| input to the key function | object with string `platform` and `projectName` fields | required | The project whose identity key is built |
| input to the de-duplication function | list of objects, each with string `platform` and `projectName` fields | required | Deploy-project entries to collapse to one per project |

The logic reads no environment variables, settings keys or injected dependencies. The key separator `|` is a hard-coded constant inside the key function.

