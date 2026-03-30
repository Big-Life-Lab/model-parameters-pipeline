# Introduction to Model Parameters Pipeline

## Overview

This vignette will walk you through:

1.  Running the transformation pipeline on your own data
2.  Running the transformation pipeline on the [Hypertension Population
    Risk Tool (HTNPoRT)](https://github.com/Big-Life-Lab/htnport)

## Basic Usage

### Setup

First, load the package:

``` r
library(model.parameters.pipeline)
```

### Simple Example

Let’s walk through a simple example. The package uses a two-step
workflow:

1.  [`prepare_model_pipeline()`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md) -
    Load and validate model configuration files
2.  [`run_model_pipeline()`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md) -
    Apply transformations to data

``` r
# Step 1: Prepare the model pipeline
mod <- prepare_model_pipeline("path/to/model-export.csv")

# Step 2: Run the pipeline on your data (returns the output)
result <- run_model_pipeline(mod, dat = "path/to/input-data.csv")

# View the first few rows
head(result)
```

## Using Data Frames for Input Data

You can pass a data frame instead of a file path for the input data:

``` r
# Prepare the model
mod <- prepare_model_pipeline("path/to/model-export.csv")

# Load and preprocess your data
input_data <- read.csv("path/to/input-data.csv")

# Run pipeline with data frame (returns the output)
result <- run_model_pipeline(mod, dat = input_data)
```

This is useful when your data is already loaded or needs preprocessing.

## Processing Multiple Datasets

If you need to apply the same model to multiple datasets (e.g.,
processing batches), reuse the prepared model object for better
performance:

``` r
# Prepare the model once - configuration files are loaded and cached
mod <- prepare_model_pipeline("path/to/model-export.csv")

# Run on multiple datasets and extract output from each
result1 <- run_model_pipeline(mod, dat = "batch1_data.csv")
result2 <- run_model_pipeline(mod, dat = "batch2_data.csv")
result3 <- run_model_pipeline(mod, dat = "batch3_data.csv")
```

This avoids re-reading and parsing the configuration files for each
batch.

## Restricting File Access with `sandbox_path`

When running on a server or any public-facing system, the model
configuration files can reference arbitrary paths on the filesystem. Use
the `sandbox_path` parameter to restrict which files the pipeline is
allowed to read.

``` r
mod <- prepare_model_pipeline(
  "path/to/model-files/model-export.csv",
  sandbox_path = "path/to/model-files/"
)
```

When `sandbox_path` is set, every file referenced inside the model
configuration (the model export, variables file, model-steps file, and
any step parameter files) must be located within that directory. If any
path resolves outside of it,
[`prepare_model_pipeline()`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md)
stops with an error.

This restriction applies only to the **model configuration files** — it
does not affect data files passed to
[`run_model_pipeline()`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md).
It does, however, affect the model export file passed to
[`prepare_model_pipeline()`](https://big-life-lab.github.io/model-parameters-pipeline/reference/prepare_model_pipeline.md).

**When to use it:**

- You expose the pipeline as a web service or API and the model export
  path (or paths inside it) could be influenced by user input.
- You want to enforce that a model package stays self-contained within a
  specific directory and never reads files from elsewhere on the
  filesystem.

**When you can omit it:**

- You are running the pipeline locally in a trusted environment where
  all model files are under your control and path traversal is not a
  concern. The default (`sandbox_path = NULL`) imposes no restriction.

## Working with Results

[`run_model_pipeline()`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md)
applies the pipeline’s transformations and returns the results. The
`mode` argument of
[`run_model_pipeline()`](https://big-life-lab.github.io/model-parameters-pipeline/reference/run_model_pipeline.md)
(default `"output"`) controls what columns are returned:

- `"output"`: only the columns produced by the final transformation step
- `"full"`: all columns — original predictors plus every intermediate
  and output column

``` r
# Default mode: only the final step's output columns
output <- run_model_pipeline(mod, dat = "path/to/input-data.csv")

# Full mode: all columns including intermediate transformation variables
output_full <- run_model_pipeline(
  mod,
  dat = "path/to/input-data.csv",
  mode = "full"
)

# View column names to see what transformations were created
colnames(output_full)
```

## Real-World Example: HTNPoRT Model

The HTNPoRT (Hypertension Population Risk Tool) is a validated
predictive model for hypertension risk. Here’s how to use this package
with HTNPoRT:

``` r
# Clone the HTNPoRT repository to get model parameters and validation data
# In your terminal:
# git clone https://github.com/Big-Life-Lab/htnport.git

library(model.parameters.pipeline)

# Set path to cloned HTNPoRT repository
htnport_dir <- "/path/to/htnport"

# Load validation data
data_file <- file.path(
  htnport_dir,
  "output/validation-data/HTNPoRT-female-validation-data.csv"
)
data <- read.csv(data_file)

# View the input data structure
head(data)

# Path to model export file
model_export_file <- file.path(
  htnport_dir,
  "output/logistic-model-export/female/HTNPoRT-female-model-export.csv"
)

# Prepare the model pipeline
mod <- prepare_model_pipeline(model_export_file)

# Run the pipeline
predictions <- run_model_pipeline(mod, dat = data)

# View the logistic predictions (hypertension risk probabilities)
head(predictions)

# Summary statistics of predictions
summary(predictions)
```

## Next Steps

- For detailed information about the Model Parameters specification, see
  the [Model Parameters Reference
  Documentation](https://big-life-lab.github.io/model-parameters/5-reference.html)
- To add new transformation steps, see the [Adding a New Transformation
  Step](https://big-life-lab.github.io/model-parameters-pipeline/CONTRIBUTING.html#adding-a-new-transformation-step)
  guide
- To report issues or request features, visit the [issue
  tracker](https://github.com/Big-Life-Lab/model-parameters-pipeline/issues)

## Additional Resources

- [Big Life Lab GitHub](https://github.com/Big-Life-Lab)
- [Model Parameters
  Specification](https://github.com/Big-Life-Lab/model-parameters)
- [HTNPoRT Model](https://github.com/Big-Life-Lab/htnport)
- [Predictive Algorithms
  Repository](https://github.com/Big-Life-Lab/predictive-algorithms)
