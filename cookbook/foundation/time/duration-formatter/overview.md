
Integer seconds rendered three ways: hours and minutes for reading, decimal hours for transcribing into a client's billing tool, and a clock for a running timer. It also parses a typed duration back into seconds. It exists because the billing path must never route a duration through a floating-point number, so every conversion is integer arithmetic with half-up rounding. It does not converge the repository's other duration formatters; that is separate work.

