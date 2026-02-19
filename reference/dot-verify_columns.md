# Verify required columns exist in the data

Checks that all required columns are present in the data and stops with
an informative error message if any are missing.

## Usage

``` r
.verify_columns(data, columns, data_description, file = NULL)
```

## Arguments

- data:

  Data to validate (eg. a dataframe)

- columns:

  Character vector of required column names

- data_description:

  Description of the data being validated to include in the error
  message.

- file:

  Optional file path to include in error message (to indicate where the
  data originated from). For example: "model steps file" or "model steps
  data".
