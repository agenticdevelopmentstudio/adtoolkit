
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `day` | Date value | required, no default | Any instant on the day to announce; normalized internally to the start of that day (see **day-normalized-to-start-of-day**) |
| `calendar` | Calendar configuration | current calendar | Determines the day boundary (time zone, calendar system) used to normalize `day` and to decide which side of midnight an instant falls on |

