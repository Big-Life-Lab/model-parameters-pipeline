# Find an unused column name in the data

Generates a unique column name by appending an integer to a prefix.
Iteratively checks for column_prefix1, column_prefix2, etc. until
finding a name that doesn't exist in the data (eg. a dataframe).

## Usage

``` r
.get_unused_column(data, column_prefix)
```

## Arguments

- data:

  Data to check for existing column names.

- column_prefix:

  Character prefix for the column name

## Value

Character string of an unused column name (e.g., "prefix1", "prefix2")
