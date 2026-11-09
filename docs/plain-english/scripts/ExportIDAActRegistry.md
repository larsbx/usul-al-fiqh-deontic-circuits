# Act-registry comparison exporter

Companion to [ExportIDAActRegistry](../../../formal/lean/scripts/ExportIDAActRegistry.lean).

The executable prints `family,x,y,z,code,baseIssue` followed by the actual
resolver/admission outputs. Registry cases are ordered by registry variant then
description variant. Bound cases are ordered by description, binding, then
source environment.

There are 4,824 data rows and 9,648 compared output cells. The source issue is
zero unless the bound gate reaches and rejects the actual source evaluator.
Expected test values are not used to generate this export.

The runner rejects truncated, duplicated, reordered, malformed, or disagreeing
outputs and compares the complete table with the independent Quint export.
