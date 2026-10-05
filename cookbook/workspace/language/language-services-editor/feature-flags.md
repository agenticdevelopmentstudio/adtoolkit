
None of these twelve components is gated behind a feature flag; each capability (completion, hover, jump-to-definition, semantic highlighting) is instead gated per-document by the connected server's own declared capabilities, checked at the point of use (`declaresHoverProvider`, `declaresDefinitionProvider`, `fullRequestLegend`).

