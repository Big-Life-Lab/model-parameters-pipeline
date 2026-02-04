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
transformed_data <- mod$df

# View the first few rows
head(transformed_data)
```

### Understanding the File Structure

The pipeline uses four main types of files:

#### 1. Model Export File (`model-export.csv`)

This file points to the locations of the variables and model steps
files:

    fileType,filePath
    variables,variables.csv
    model-steps,model-steps.csv

#### 2. Variables File (`variables.csv`)

Lists which variables serve as predictors in the model:

    variable,role
    age,Predictor
    sex,Predictor
    bmi,Predictor
    smoking,Predictor

#### 3. Model Steps File (`model-steps.csv`)

Defines the sequence of transformation steps:

    step,filePath
    center,center-params.csv
    dummy,dummy-params.csv
    interaction,interaction-params.csv
    rcs,rcs-params.csv
    logistic-regression,logistic-regression-params.csv

Steps are executed in the order specified in this file.

#### 4. Transformation Parameter Files

Each transformation step has its own parameter file. Here are examples:

**Center** (`center-params.csv`): Specifies centering values

    origVariable,centerValue,centeredVariable
    age,50,age_centered
    bmi,25,bmi_centered

**Dummy** (`dummy-params.csv`): Defines categorical encodings

    origVariable,catValue,dummyVariable
    sex,male,sex_male
    sex,female,sex_female
    smoking,current,smoking_current
    smoking,former,smoking_former
    smoking,never,smoking_never

**Interaction** (`interaction-params.csv`): Creates interaction terms

    interactingVariables,interactionVariable
    age_centered;smoking_current,age_smoking_interaction

Note: Variables in `interactingVariables` are separated by semicolons.

**RCS** (`rcs-params.csv`): Defines spline transformations

    variable,rcsVariables,knots
    age,age_rcs1;age_rcs2;age_rcs3,20;40;60;80

**Logistic Regression** (`logistic-regression-params.csv`): Applies
logistic regression

    variable,coefficient
    Intercept,-2.5
    age_centered,0.05
    sex_male,0.3
    smoking_current,0.8
    age_smoking_interaction,0.02

## Using Data Frames for Input Data

You can pass a data frame instead of a file path for the input data:

``` r
# Prepare the model
mod <- prepare_model_pipeline("path/to/model-export.csv")

# Load and preprocess your data
data_df <- read.csv("path/to/input-data.csv")

# Run pipeline with data frame
mod <- run_model_pipeline(mod, data = data_df)
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
`$df` component:

``` r
# Access transformed data
result_data <- mod$df

# If the model includes a logistic-regression step, extract predictions
# Logistic predictions are stored in columns starting with "logistic_"
predictions <- mod$df[, grep("^logistic_", names(mod$df))]

# View column names to see what transformations were created
colnames(mod$df)
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
head(mod$df)

# Extract logistic predictions (hypertension risk probabilities)
predictions <- mod$df[, grep("^logistic_", names(mod$df))]
head(predictions)

# Summary statistics of predictions
summary(predictions)
```

## Understanding the Transformation Flow

Let’s trace what happens to data as it flows through the pipeline:

1.  **Input**: Raw data with predictor variables (age, sex, BMI, etc.)
2.  **Center**: Continuous variables are centered (e.g.,
    `age_centered = age - 50`)
3.  **Dummy**: Categorical variables become binary indicators (e.g.,
    `sex_male = 1` if male, 0 otherwise)
4.  **Interaction**: Combinations of variables are multiplied (e.g.,
    `age_sex = age_centered * sex_male`)
5.  **RCS**: Non-linear relationships are captured with splines
6.  **Logistic Regression**: Final prediction is calculated using
    coefficients

Each step adds new columns to the data frame while preserving the
original columns. This allows you to inspect intermediate
transformations and understand how the model works.

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
