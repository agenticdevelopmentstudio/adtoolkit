
Not applicable — this is the integrations data-access client, not a visual component; any loading, error,
or empty visual state is owned by the presentation layer that consumes this client. The only runtime
state machine this component defines is the OAuth `state` freshness window, specified under Behavioral
Requirements (`state-freshness-window`), not here.

