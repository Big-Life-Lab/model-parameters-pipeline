# Verify required columns exist in a dataframe

Checks that all required columns are present in the dataframe and stops
with an informative error message if any are missing.

## Usage

``` r
.verify_columns(df, columns, data_description, file = NULL)
```

## Arguments

- df:

  Data frame to validate

- columns:

  Character vector of required column names

- data_description:

  Description of the data being validated to include in the error
  message.

- file:

  Optional file path to include in error message (to indicate where the
  data originated from). For example: "model steps file" or "model steps
  data".
