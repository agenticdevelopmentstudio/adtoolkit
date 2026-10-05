
The progress window owns a small floating panel shown while a project scan
runs. It presents a headline label and an indeterminate progress indicator,
and nothing else: no counts, no scanned path, no cancel control. Presenting
it shows the panel and starts the indicator animating; finishing it switches
the indicator to a completed determinate state, updates the headline, and
closes the panel itself one second later. The projects coordinator
constructs one instance per scan, presents it before starting the scan,
finishes it when the scan completes, and drops its own reference to the
instance immediately after finishing it.

