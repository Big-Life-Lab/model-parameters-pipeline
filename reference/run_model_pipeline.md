# Run Model Pipeline

Executes the transformation pipeline on input data and retrieve the
output. Applies each transformation step defined in the model steps file
in sequence, modifying the data accordingly.

## Usage

``` r
run_model_pipeline(mod, x, mode = "output")
```

## Arguments

- mod:

  A model object created by
  [`prepare_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md).

- x:

  Either a file path (character) to a CSV file containing the input
  data, or a data frame. The data must contain all columns specified as
  predictors in the variables file.

- mode:

  A character string specifying what data to return. Can be one of:

  - "output": Only return the final output of the model. These are the
    values of all variables calculated in the final step found in the
    model steps file.

  - "full": Return all data, which includes the input data, all
    intermediate variables, and the final output of the model.

  Default is "output".

## Value

A model object created from a call to
[`prepare_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md).

## See also

[`prepare_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md)
to prepare the model object

## Examples

``` r
if (FALSE) { # \dontrun{
# Prepare and run pipeline
mod <- prepare_model_pipeline("path/to/model-export.csv")
output <- run_model_pipeline(mod, x = "path/to/input-data.csv")
head(output)

# Run on data frame
input_data <- read.csv("path/to/data.csv")
mod <- run_model_pipeline(mod, x = input_data)
} # }
```
