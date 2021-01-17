# Used by "mix format"
locals_without_parens = [defnode: 1, defnode: 2, deftransition: 2, deftransition: 3]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
