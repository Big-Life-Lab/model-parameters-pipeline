# Generate a column name that does not already exist in a list of columns

Generates a unique column name by appending an integer to a prefix.

## Usage

``` r
.get_unused_column(existing_columns, column_prefix, column_suffix = "_#")
```

## Arguments

- existing_columns:

  Existing character vector/list of columns. We want a column name that
  does not already exist among these column names.

- column_prefix:

  Character prefix for the column name

- column_suffix:

  If a column named column_prefix already exists then column_suffix is
  appended to column_prefix, replacing "#" with an integer, to try to
  find an unused column name. For example, if column_prefix = "output"
  and column_suffix = "\_#", then "output" will be returned if such a
  column doesn't exist. If it does exist, then "output_2", "output_3",
  etc. will be tested until an unused column name is found.

## Value

Character string of an unused column name (e.g., "prefix_2", "prefix_3")
