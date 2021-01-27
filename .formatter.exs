# Used by "mix format"
locals_without_parens = [
  activity: 1,
  activity: 2,
  ~>: 2,
  gateway: 2,
  gateway: 3
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
