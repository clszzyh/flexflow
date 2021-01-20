# Used by "mix format"
locals_without_parens = [
  intermediate_node: 1,
  intermediate_node: 2,
  start_node: 1,
  start_node: 2,
  end_node: 1,
  end_node: 2,
  ~>: 2,
  transition: 2,
  transition: 3
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
