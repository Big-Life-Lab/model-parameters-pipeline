# Run Logistic Regression Step

Applies logistic regression by multiplying variables by coefficients,
summing, and applying the logistic function (1 / (1 + exp(-x))).
Implements the 'logistic-regression' transformation step from the Model
Parameters pipeline.

## Usage

``` r
.run_step_logistic_regression(mod, file)
```

## Arguments

- mod:

  Model object containing input data in `mod$data`

- file:

  Path to logistic step specification file

## Value

A list containing: `mod` (the updated model object with the logistic
prediction column added to `mod$data`), and `output_columns` (character
vector of output columns of this step)

## Errors

- `missing_variable`: Raised when a non-intercept variable specified in
  the step file does not exist in `mod$data`.

- `non_numeric_coefficient`: Raised when a `coefficient` in the step
  file cannot be parsed as a number.
