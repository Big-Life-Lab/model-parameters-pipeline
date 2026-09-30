# Expand and normalize a file path.

Symbolic links and ".." will be followed and expanded.

## Usage

``` r
.expand_and_normalize_path(p, add_trailing_slash = FALSE)
```

## Arguments

- p:

  Character. The path to expand and normalize.

- add_trailing_slash:

  Logical. If \`TRUE\`, a trailing slash is appended to the normalized
  path if it does not already have one. This is useful if the path is
  known to be a directory. Defaults to \`FALSE\`.

## Value

Character. The normalized path, or \`NULL\` if the path is invalid or
does not exist.
