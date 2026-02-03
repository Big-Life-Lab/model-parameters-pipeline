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

  Model object

- file:

  Path to RCS step specification file

## Value

Updated model object with RCS variables added to data
