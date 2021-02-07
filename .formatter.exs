# Used by "mix format"
locals_without_parens = [
  state: 1,
  state: 2,
  state: 3,
  ~>: 2,
  event: 2,
  event: 3,
  event: 4
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
