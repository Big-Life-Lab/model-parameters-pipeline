# Run Restricted Cubic Spline Step

Creates restricted cubic spline (RCS) transformations using specified
knot positions. Implements the 'rcs' transformation step from the Model
Parameters pipeline.

## Usage

``` r
.run_step_rcs(mod, file)
```

## Arguments

- mod:

  Model object containing input data in `mod$data`

- file:

  Path to RCS step specification file

## Value

A list containing: `mod` (the updated model object with RCS variables
added to `mod$data`), and `output_columns` (character vector of output
columns of this step)
