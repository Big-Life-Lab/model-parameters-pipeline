# Run Interaction Step

Creates interaction terms by multiplying specified variables together.
Implements the 'interaction' transformation step from the Model
Parameters pipeline.

## Usage

``` r
.run_step_interaction(mod, dat, file)
```

## Arguments

- mod:

  Model object

- dat:

  Data frame containing the input data to be transformed

- file:

  Path to interaction step specification file

## Value

A list containing: `mod` (the updated model object), `data` (the
transformed data frame with interaction variables added), and
`output_columns` (character vector of new column names added by this
step)
