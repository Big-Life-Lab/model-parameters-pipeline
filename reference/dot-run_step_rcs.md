# Run Restricted Cubic Spline Step

Creates restricted cubic spline (RCS) transformations using specified
knot positions. Implements the 'rcs' transformation step from the Model
Parameters pipeline.

## Usage

``` r
.run_step_rcs(mod, dat, file)
```

## Arguments

- mod:

  Model object

- dat:

  Data frame containing the input data to be transformed

- file:

  Path to RCS step specification file

## Value

A list containing: `mod` (the updated model object), `data` (the
transformed data frame with RCS variables added), and `output_columns`
(character vector of new column names added by this step)
