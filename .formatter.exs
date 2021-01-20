# Used by "mix format"
locals_without_parens = [
  node: 1,
  node: 2,
  defstart: 1,
  defstart: 2,
  defend: 1,
  defend: 2,
  ~>: 2,
  transition: 2,
  transition: 3
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
