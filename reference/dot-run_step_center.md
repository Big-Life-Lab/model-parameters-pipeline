# Run Center Step

Centers variables by subtracting a specified center value from original
variables. Implements the 'center' transformation step from the Model
Parameters pipeline.

## Usage

``` r
.run_step_center(mod, file)
```

## Arguments

- mod:

  Model object containing input data in `mod$data`

- file:

  Path to center step specification file

## Value

A list containing: `mod` (the updated model object with centered
variables added to `mod$data`), and `output_columns` (character vector
of output columns of this step)

## Errors

- `missing_variable`: Raised when a variable specified as `origVariable`
  in the step file does not exist in `mod$data`.
