# Rename a set of columns in the data using a prefix and suffix pattern

Renames the columns so that they follow a consistent naming convention
based on the given prefix and suffix. Each output column is assigned a
unique name via \[.get_unused_column()\], avoiding collisions with
existing columns in the data.

## Usage

``` r
.rename_columns(dat, columns, prefix, suffix = "_#")
```

## Arguments

- dat:

  The data whose columns are to be renamed.

- columns:

  A character vector of column names in \`dat\` to rename.

- prefix:

  A string used as the base name (prefix) for the renamed columns.

- suffix:

  A string appended to \`prefix\` when a disambiguating number is
  needed. Must contain a \`#\` character, which is replaced by the
  sequence number. Defaults to \`"\_#"\`

## Value

A named list with two elements:

- \`dat\`:

  The data frame with the specified columns renamed.

- \`new_column_names\`:

  A character vector of the new column names, in the same order as
  \`columns\`.

## Details

For example, if \`prefix\` is \`"x"\` and suffix is \`"\_#"\`, then the
attempted column names will be \`"x"\`, \`"x_2"\`, \`"x_3"\`, etc.
