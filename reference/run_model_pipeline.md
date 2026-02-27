# Run Model Pipeline

Executes the transformation pipeline on input data. Applies each
transformation step defined in the model steps file in sequence,
modifying the data accordingly.

## Usage

``` r
run_model_pipeline(mod, dat)
```

## Arguments

- mod:

  A model object created by
  [`prepare_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md).

- dat:

  Either a file path (character) to a CSV file containing the input
  data, or a data frame. The data must contain all columns specified as
  predictors in the variables file.

## Value

A model object (list) with all transformation results stored in
`mod$data`. Pass the returned object to
[`get_pipeline_output`](https://big-life-lab.github.io/model-parameters-pipeline/reference/get_pipeline_output.md)
to extract a data frame.

## See also

[`prepare_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md)
to prepare the model object,
[`get_pipeline_output`](https://big-life-lab.github.io/model-parameters-pipeline/reference/get_pipeline_output.md)
to extract the output of the pipeline

## Examples

``` r
if (FALSE) { # \dontrun{
# Prepare and run pipeline
mod <- prepare_model_pipeline("path/to/model-export.csv")
mod <- run_model_pipeline(mod, dat = "path/to/input-data.csv")

# Extract final output columns as a data frame
output <- get_pipeline_output(mod, mode = "output")
head(output)

# Get all columns including intermediate transformation variables
output_full <- get_pipeline_output(mod, mode = "full")

# Run on data frame
input_data <- read.csv("path/to/data.csv")
mod <- run_model_pipeline(mod, dat = input_data)
} # }
```
