# Used by "mix format"
locals_without_parens = [
  event: 1,
  event: 2,
  ~>: 2,
  transition: 2,
  transition: 3
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
