# Run Model Pipeline

Executes the transformation pipeline on input data. Applies each
transformation step defined in the model steps file in sequence,
modifying the data accordingly.

## Usage

``` r
run_model_pipeline(mod, data)
```

## Arguments

- mod:

  A model object created by
  [`prepare_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md).

- data:

  Either a file path (character) to a CSV file containing the input
  data, or a data frame. The data must contain all columns specified as
  predictors in the variables file.

## Value

The model object with the transformed data added. The transformed data
is accessible via `mod$df`. This data frame contains:

- Original predictor columns from the input data

- New columns created by each transformation step (e.g., centered
  variables, dummy variables, interaction terms, spline terms)

- If a logistic step is included, a column named `logistic_N` (where N
  is a positive integer) containing the predicted probabilities

## See also

[`prepare_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md)
to prepare the model object

## Examples

``` r
if (FALSE) { # \dontrun{
# Prepare and run pipeline
mod <- prepare_model_pipeline("path/to/model-export.csv")
mod <- run_model_pipeline(mod, data = "path/to/input-data.csv")

# Access results
head(mod$df)

# Extract predictions from logistic step
predictions <- mod$df[, grep("^logistic_", names(mod$df))]

# Run on data frame
input_df <- read.csv("path/to/data.csv")
mod <- run_model_pipeline(mod, data = input_df)
} # }
```
