# Run Logistic Regression Step

Applies logistic regression by multiplying variables by coefficients,
summing, and applying the logistic function (1 / (1 + exp(-x))).
Implements the 'logistic' transformation step from the Model Parameters
pipeline.

## Usage

``` r
.run_step_logistic(mod, file)
```

## Arguments

- mod:

  Model object

- file:

  Path to logistic step specification file

## Value

Updated model object with logistic prediction added to data
