# Model Parameters Pipeline

This module provides functions to prepare and run a model parameters
pipeline for applying sequential data transformations as defined by the
Model Parameters specification developed by Big Life Lab.

## Workflow

The typical workflow involves three steps:

1.  [`prepare_model_pipeline()`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md):
    Load and validate model configuration

2.  [`run_model_pipeline()`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md):
    Apply transformations to data

3.  [`get_pipeline_output()`](https://big-life-lab.github.io/model-parameters-pipeline/reference/get_pipeline_output.md):
    Retrieve the output of the model pipeline. The output is the results
    of the last transformation step. Depending on the step, this may
    include multiple columns.

## Required Files

The pipeline requires the following CSV files:

- Model Export:

  Points to variables and model-steps files

- Variables:

  Lists predictor variables

- Model Steps:

  Defines transformation sequence

- Step Parameter Files:

  Define parameters for each transformation step

## See also

- [Model Parameters
  Specification](https://github.com/Big-Life-Lab/model-parameters)

- [Model Parameters Reference
  Documentation](https://big-life-lab.github.io/model-parameters/5-reference.html)

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage
mod <- prepare_model_pipeline("path/to/model-export.csv")
mod <- run_model_pipeline(mod, dat = "path/to/input-data.csv")
result <- get_pipeline_output(mod, mode = "output")

# Processing multiple datasets with the same model
mod <- prepare_model_pipeline("path/to/model-export.csv")
for (data_file in data_files) {
  mod <- run_model_pipeline(mod, dat = data_file)
  result <- get_pipeline_output(mod, mode = "output")
  # Process result (a data frame)
}

# Pass a data frame to run_model_pipeline
input_data <- read.csv("path/to/input-data.csv")
mod <- run_model_pipeline(mod, dat = input_data)
} # }
```
