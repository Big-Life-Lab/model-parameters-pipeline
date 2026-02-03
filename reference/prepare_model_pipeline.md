# Prepare Model Pipeline

Loads and validates model configuration files, preparing the pipeline
for execution. This function reads the model export file, variables
file, and model steps file, and preloads all transformation parameter
files into a cached model object.

## Usage

``` r
prepare_model_pipeline(model_export)
```

## Arguments

- model_export:

  A file path (character) to a model export CSV file. The model export
  must contain columns 'fileType' and 'filePath' that specify the
  locations of the variables and model-steps files. The directory
  containing the model export file is used as the root directory for
  resolving relative file paths found within the model-steps file.

## Value

A model object (list) containing:

- root_dir:

  The root directory used for resolving file paths (derived from the
  model export file location)

- model_export:

  The model export data frame

- variables:

  The variables data frame

- model_steps:

  The model steps data frame

- predictor_variables:

  Character vector of predictor variable names

- files:

  Named list of cached file contents

## See also

[`run_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md)
to execute the pipeline

## Examples

``` r
if (FALSE) { # \dontrun{
mod <- prepare_model_pipeline("path/to/model-export.csv")
} # }
```
