# Introduction to Model Parameters Pipeline

## Overview

The Model Parameters Pipeline is an R package for applying
transformations to data according to the [Model
Parameters](https://github.com/Big-Life-Lab/model-parameters)
specification developed by Big Life Lab. This package implements a
pipeline for sequential data transformations that are commonly used in
predictive health models.

This vignette will walk you through:

1.  Understanding the Model Parameters specification
2.  Setting up your model configuration files
3.  Running the transformation pipeline
4.  Working with the results

## What is the Model Parameters Specification?

The Model Parameters specification is a standardized way to define and
apply data transformations used in predictive algorithms. It was
developed by Big Life Lab for their predictive health models such as:

- **HTNPoRT**: Hypertension Population Risk Tool
- **DemPoRT**: Dementia Population Risk Tool
- **CVDPoRT**: Cardiovascular Disease Population Risk Tool
- **MPoRT**: Mortality Population Risk Tool

The specification uses CSV files to define transformations, making
algorithms:

- **Transparent**: All parameters and transformations are documented in
  human-readable files
- **Portable**: The same model can be deployed across different
  platforms and programming languages
- **Reproducible**: Transformations are applied consistently

## Supported Transformations

The pipeline supports five types of transformations:

1.  **Center**: Subtracts a constant value from variables (e.g., age -
    50)
2.  **Dummy**: Creates binary indicator variables for categorical values
3.  **Interaction**: Multiplies variables together to create interaction
    terms
4.  **RCS**: Applies restricted cubic spline transformations for
    non-linear relationships
5.  **Logistic Regression**: Applies logistic regression to generate
    predictions

## Installation

``` r
# Install from GitHub (if published)
devtools::install_github("Big-Life-Lab/model-parameters-pipeline")

# Or install from local source
devtools::install_local("/path/to/model-parameters-pipeline")
```

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

# Step 2: Run the pipeline on your data
mod <- run_model_pipeline(mod, data = "path/to/input-data.csv")

# Access the transformed data
transformed_data <- mod$data

# View the first few rows
head(transformed_data)
```

## Using Data Frames for Input Data

You can pass a data frame instead of a file path for the input data:

``` r
# Prepare the model
mod <- prepare_model_pipeline("path/to/model-export.csv")

# Load and preprocess your data
input_data <- read.csv("path/to/input-data.csv")

# Run pipeline with data frame
mod <- run_model_pipeline(mod, data = input_data)
```

This is useful when your data is already loaded or needs preprocessing.

## Processing Multiple Datasets

If you need to apply the same model to multiple datasets (e.g.,
processing batches), reuse the prepared model object for better
performance:

``` r
# Prepare the model once - configuration files are loaded and cached
mod <- prepare_model_pipeline("path/to/model-export.csv")

# Run on multiple datasets
result1 <- run_model_pipeline(mod, data = "batch1_data.csv")
result2 <- run_model_pipeline(mod, data = "batch2_data.csv")
result3 <- run_model_pipeline(mod, data = "batch3_data.csv")
```

This avoids re-reading and parsing the configuration files for each
batch.

## Working with Results

The pipeline returns a model object with the transformed data in the
`$data` component:

``` r
# Access transformed data
result_data <- mod$data

# If the model includes a logistic-regression step, extract predictions
# Logistic predictions are stored in columns starting with "logistic_"
predictions <- mod$data[, grep("^logistic_", names(mod$data))]

# View column names to see what transformations were created
colnames(mod$data)
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
mod <- run_model_pipeline(mod, data = data)

# View the transformed data with all intermediate steps
head(mod$data)

# Extract logistic predictions (hypertension risk probabilities)
predictions <- mod$data[, grep("^logistic_", names(mod$data))]
head(predictions)

# Summary statistics of predictions
summary(predictions)
```

## Next Steps

- For detailed information about the Model Parameters specification, see
  the [Model Parameters Reference
  Documentation](https://big-life-lab.github.io/model-parameters/5-reference.html)
- To add new transformation steps, see the `ADDING_NEW_STEP.md` guide in
  the package
- To report issues or request features, visit the [issue
  tracker](https://github.com/Big-Life-Lab/model-parameters-pipeline/issues)

## Additional Resources

- [Big Life Lab GitHub](https://github.com/Big-Life-Lab)
- [Model Parameters
  Specification](https://github.com/Big-Life-Lab/model-parameters)
- [HTNPoRT Model](https://github.com/Big-Life-Lab/htnport)
- [Predictive Algorithms
  Repository](https://github.com/Big-Life-Lab/predictive-algorithms)
