# Run Center Step

Centers variables by subtracting a specified center value from original
variables. Implements the 'center' transformation step from the Model
Parameters pipeline.

## Usage

``` r
.run_step_center(mod, dat, file)
```

## Arguments

- mod:

  Model object

- dat:

  Data frame containing the input data to be transformed

- file:

  Path to center step specification file

## Value

A list containing: `mod` (the updated model object), `data` (the
transformed data frame with centered variables added), and
`output_columns` (character vector of new column names added by this
step)
