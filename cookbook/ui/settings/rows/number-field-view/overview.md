
The Number Field View is the settings row underlying every numeric text
field in the framework: a title label leading and a narrow, right-aligned
number field trailing, parsed and clamped through a number value contract
rather than being tied to one numeric type. Optional (rather than required)
bounds are the whole reason this exists: every other numeric row is built on
a range view model that requires both, and most numeric settings a caller
declares name neither — a number with no ceiling is still a number, not a
text box. The concept also defines the number value contract itself — the
interface a number type implements so a field can display it, read it back,
and compare it — with two built-in conformances, integer and floating-point,
each supplying its own locale-aware parsing and canonical text form. The
Integer Field View (`adtoolkit://cookbook/ui/settings/rows/integer-field-view`)
is a thin, forwarding wrapper around this component specialized for
integers; this recipe documents the field itself, including the parsing
contract that wrapper delegates to.

