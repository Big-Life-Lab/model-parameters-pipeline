# Prepare Model Pipeline

Loads and validates model configuration files, preparing the pipeline
for execution. This function reads the model export file, variables
file, and model steps file, and preloads all transformation parameter
files into a cached model object.

## Usage

``` r
prepare_model_pipeline(model_export, sandbox_path = NULL)
```

## Arguments

- model_export:

  A file path (character) to a model export CSV file. The model export
  must contain columns 'fileType' and 'filePath' that specify the
  locations of the variables and model-steps files. The directory
  containing the model export file is used as the root directory for
  resolving relative file paths found within the model-steps file.

- sandbox_path:

  Character or `NULL`. If specified, all file paths referenced in the
  model parameters configuration files (model export, variables, model
  steps, and step parameter files) must be descendants of this
  directory. If any file resolves outside of `sandbox_path`, an error is
  raised. This prevents access to files outside the expected directory
  structure, which is useful when running on a server or other
  public-facing system where increased security is required. Note that
  this restriction does not apply to data files passed to
  [`run_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md).
  Defaults to `NULL` (no restriction).

## Value

A model object (list) that can be used to pass to
[`run_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md).

## Errors

- `inaccessible_file`: Raised when any of the model export, variables,
  model steps, or step parameter files does not exist or, if
  \`sandbox_path\` is set, is not a descendant of that directory.

- `invalid_file_format`: Raised when any of the model export, variables,
  model steps, or step parameter files exists but cannot be parsed as a
  CSV.

- `missing_columns`: Raised when any of the Model Parameters files is
  missing a required column.

- `file_not_added`: Raised indirectly via the step functions if a file
  was not successfully added to the model cache; should not occur in
  normal use.

- `error`: Any other error occurred that is not classified in the above
  errors.

## See also

[`run_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md)
to execute the pipeline.

## Examples

``` r
if (FALSE) { # \dontrun{
mod <- prepare_model_pipeline("path/to/model-export.csv")
} # }
```
