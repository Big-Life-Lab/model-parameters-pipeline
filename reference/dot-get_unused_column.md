# Find an unused column name in a dataframe

Generates a unique column name by appending an integer to a prefix.
Iteratively checks for column_prefix1, column_prefix2, etc. until
finding a name that doesn't exist in the dataframe.

## Usage

``` r
.get_unused_column(df, column_prefix)
```

## Arguments

- df:

  Data frame to check for existing column names

- column_prefix:

  Character prefix for the column name

## Value

Character string of an unused column name (e.g., "prefix1", "prefix2")
