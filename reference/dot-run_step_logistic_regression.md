# Run Logistic Regression Step

Applies logistic regression by multiplying variables by coefficients,
summing, and applying the logistic function (1 / (1 + exp(-x))).
Implements the 'logistic' transformation step from the Model Parameters
pipeline.

## Usage

``` r
.run_step_logistic_regression(mod, dat, file)
```

## Arguments

- mod:

  Model object

- dat:

  Data frame containing the input data to be transformed

- file:

  Path to logistic step specification file

## Value

A list containing: `mod` (the updated model object), `data` (the
transformed data frame with the logistic prediction column added), and
`output_columns` (character vector of new column names added by this
step)
