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

A data frame containing the pipeline output (when \`mode = "output"\`)
or all data including intermediate columns (when \`mode = "full"\`).

## Errors

- `inaccessible_file`: Raised if a step specification file does not
  exist or, if \`mod\$sandbox_path\` is set, is not a descendant of that
  directory.

- `invalid_file_format`: Raised if a step specification file cannot be
  parsed as a CSV.

- `missing_columns`: Raised when a step specification file is missing
  required columns.

- `missing_data_columns`: Raised when predictor variable columns listed
  in the variables file are absent from the input data.

- `empty_step_file_path`: Raised when a row in the model steps file has
  an empty `filePath`.

- `unknown_step`: Raised when a step name in the model steps file is not
  a recognized transformation type.

- `invalid_mode`: Raised when the `mode` argument is not one of
  `"output"` or `"full"`.

- `file_not_added`: Raised indirectly via the step functions if a file
  was not successfully added to the model cache; should not occur in
  normal use.

- `error`: Any other error occurred that is not classified in the above
  errors.

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
