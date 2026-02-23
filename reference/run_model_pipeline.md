# Run Model Pipeline

Executes the transformation pipeline on input data. Applies each
transformation step defined in the model steps file in sequence,
modifying the data accordingly.

## Usage

``` r
run_model_pipeline(mod, dat, mode = "output")
```

## Arguments

- mod:

  A model object created by
  [`prepare_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md).

- dat:

  Either a file path (character) to a CSV file containing the input
  data, or a data frame. The data must contain all columns specified as
  predictors in the variables file.

- mode:

  A character string specifying what data to return. Can be one of:
  "output": Only return the final output of the model. These are the
  values of all variables calculated in the final step found in the
  model export file. "full": Return all data, which includes the input
  data, all intermediate variables, and the final output of the model.
  Default is "output".

## Value

A data frame containing the transformed data. Its contents depend on
`mode`:

- `"output"`: Only the output columns produced by the final
  transformation step (e.g., the logistic prediction column when the
  last step is logistic-regression)

- `"full"`: All columns — the original predictor columns plus every new
  column created by each transformation step (centered variables, dummy
  variables, interaction terms, spline terms, etc.)

## See also

[`prepare_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md)
to prepare the model object

## Examples

``` r
if (FALSE) { # \dontrun{
# Prepare and run pipeline (returns a data frame)
mod <- prepare_model_pipeline("path/to/model-export.csv")
result <- run_model_pipeline(mod, dat = "path/to/input-data.csv")

# Access results
head(result)

# Get all columns including intermediate transformation variables
result_full <- run_model_pipeline(mod, dat = "path/to/input-data.csv",
  mode = "full")

# Extract predictions from logistic-regression step
predictions <- result_full[, grep("^logistic_", names(result_full))]

# Run on data frame
input_data <- read.csv("path/to/data.csv")
result <- run_model_pipeline(mod, dat = input_data)
} # }
```
