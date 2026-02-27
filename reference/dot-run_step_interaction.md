# Run Interaction Step

Creates interaction terms by multiplying specified variables together.
Implements the 'interaction' transformation step from the Model
Parameters pipeline.

## Usage

``` r
.run_step_interaction(mod, file)
```

## Arguments

- mod:

  Model object containing input data in `mod$data`

- file:

  Path to interaction step specification file

## Value

A list containing: `mod` (the updated model object with interaction
variables added to `mod$data`), and `output_columns` (character vector
of output columns of this step)
