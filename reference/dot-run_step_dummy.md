# Run Dummy Coding Step

Creates dummy variables for categorical values, setting 1 when the
original variable equals the specified category value, 0 otherwise.
Implements the 'dummy' transformation step from the Model Parameters
pipeline.

## Usage

``` r
.run_step_dummy(mod, file)
```

## Arguments

- mod:

  Model object containing input data in `mod$data`

- file:

  Path to dummy step specification file

## Value

A list containing: `mod` (the updated model object with dummy variables
added to `mod$data`), and `output_columns` (character vector of output
columns of this step)
