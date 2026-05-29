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

## Errors

- `missing_variable`: Raised when a variable specified in the step file
  does not exist in `mod$data`.

- `rcs_variable_count_mismatch`: Raised when the number of
  `rcsVariables` for a row does not equal the number of knots minus one
  (the number of restricted cubic spline basis terms).

- `non_numeric_knots`: Raised when one or more `knots` for a row cannot
  be parsed as a number.

- `insufficient_knots`: Raised (via
  [`.get_rcs`](https://big-life-lab.github.io/model-parameters-pipeline/reference/dot-get_rcs.md))
  when fewer than 3 knots are provided for a row.
