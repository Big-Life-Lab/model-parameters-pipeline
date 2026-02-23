# Run Dummy Coding Step

Creates dummy variables for categorical values, setting 1 when the
original variable equals the specified category value, 0 otherwise.
Implements the 'dummy' transformation step from the Model Parameters
pipeline.

## Usage

``` r
.run_step_dummy(mod, dat, file)
```

## Arguments

- mod:

  Model object

- dat:

  Data frame containing the input data to be transformed

- file:

  Path to dummy step specification file

## Value

A list containing: `mod` (the updated model object), `data` (the
transformed data frame with dummy variables added), and `output_columns`
(character vector of new column names added by this step)
