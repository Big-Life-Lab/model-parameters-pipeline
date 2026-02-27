# Get Model Output

Extracts a data frame from the model object returned by
[`run_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md).
If multiple calls to
[`run_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md)
have been made then only the results of the last call will be returned.

## Usage

``` r
get_pipeline_output(mod, mode = "output")
```

## Arguments

- mod:

  A model object returned by
  [`run_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md).

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

[`run_model_pipeline`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md)
to run the pipeline

## Examples

``` r
if (FALSE) { # \dontrun{
mod <- prepare_model_pipeline("path/to/model-export.csv")
mod <- run_model_pipeline(mod, dat = "path/to/input-data.csv")

# Default: only the final step's output columns
output <- get_pipeline_output(mod)

# Full: all columns including intermediate transformation variables
output_full <- get_pipeline_output(mod, mode = "full")
} # }
```
