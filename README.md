# Model Parameters Pipeline

<!-- badges: start -->
[![R-CMD-check.yaml](https://github.com/Big-Life-Lab/model-parameters-pipeline/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Big-Life-Lab/model-parameters-pipeline/actions/workflows/R-CMD-check.yaml)
[![lint.yaml](https://github.com/Big-Life-Lab/model-parameters-pipeline/actions/workflows/lint.yaml/badge.svg)](https://github.com/Big-Life-Lab/model-parameters-pipeline/actions/workflows/lint.yaml)
<!-- badges: end -->

The Model Parameters Pipeline is an R package for applying transformations to
data according to the [Model
Parameters](https://github.com/Big-Life-Lab/model-parameters) specification
developed by Big Life Lab. This package implements a pipeline for sequential
data transformations including centering, dummy coding, interactions,
restricted cubic splines (RCS), and logistic regression.

## Overview

This package provides tools to transform input data using model parameters
exported from predictive algorithms. It follows the Model Parameters
specification used by Big Life Lab's predictive models such as HTNPoRT
(Hypertension Population Risk Tool), DemPoRT (Dementia Population Risk Tool),
CVDPoRT (Cardiovascular Disease Population Risk Tool), and MPoRT (Mortality
Population Risk Tool).

### Supported Transformations

The pipeline supports the following transformation steps:

- **Center**: Centers variables by subtracting a specified value
- **Dummy**: Creates dummy variables for categorical values
- **Interaction**: Creates interaction terms by multiplying variables
- **RCS**: Applies restricted cubic spline transformations
- **Logistic Regression**: Applies logistic regression with coefficients

### Adding New Transformation Steps

For instructions on implementing additional transformation steps, see [Adding a
New Transformation Step](ADDING_NEW_STEP.md).

## Installation

### Prerequisites

- R (>= 4.1)
- Required packages: `stringr` (>= 1.6.0)
- Suggested packages: `testthat` (>= 3.0.0), `devtools` (>= 2.4.5)

### Install from Source

```r
# Install devtools if not already installed
install.packages("devtools")

# Install from local source
devtools::install_local("/path/to/model-parameters-pipeline")

# Or install from GitHub (if published)
# devtools::install_github("Big-Life-Lab/model-parameters-pipeline")
```

### Install Required Dependencies

```r
install.packages(c("stringr"))
```

## Usage

### Basic Usage

The package uses a two-step workflow:

1. `prepare_model_pipeline()` - Load and validate model configuration files
2. `run_model_pipeline()` - Apply transformations to data

```r
library(model.parameters.pipeline)

# Step 1: Prepare the model pipeline
mod <- prepare_model_pipeline("path/to/model-export.csv")

# Step 2: Run the pipeline on your data
mod <- run_model_pipeline(mod, data = "path/to/input-data.csv")

# Access the transformed data
transformed_data <- mod$df

# If model-export.csv contains a logistic step, then extract
# logistic predictions
predictions <- mod$df[, grep("^logistic_", names(mod$df))]
```

### Using Data Frames for Input Data

You can pass a data frame instead of a file path for the input data:

```r
# Prepare the model
mod <- prepare_model_pipeline("path/to/model-export.csv")

# Load and preprocess your data
data_df <- read.csv("path/to/input-data.csv")

# Run pipeline with data frame
mod <- run_model_pipeline(mod, data = data_df)
```

### Processing Multiple Datasets

For repeated transformations with the same model but different data (e.g.,
processing multiple batches), reuse the prepared model object for better
performance:

```r
# Prepare the model once
mod <- prepare_model_pipeline("path/to/model-export.csv")

# Run on multiple datasets
result1 <- run_model_pipeline(mod, data = "data1.csv")
result2 <- run_model_pipeline(mod, data = "data2.csv")
result3 <- run_model_pipeline(mod, data = "data3.csv")
```

## File Structure

The pipeline uses four main types of files to configure and execute model
transformations:

- **Model Export File**: Points to the locations of the variables and model
  steps files
- **Variables File**: Lists which variables serve as predictors in the model
- **Model Steps File**: Defines the sequence of transformation steps and their
  parameter files
- **Transformation Parameter Files**: Contain step-specific parameters (e.g.,
  center values, dummy encodings, coefficients)

A brief overfiew of these files is specified below. More detailed information
is available in the [Model Parameters Reference
Documentation](https://big-life-lab.github.io/model-parameters/5-reference.html).

### Model Export File

The model export file (eg. `model-export.csv`) specifies which files contain
the variables and transformation steps:

```csv
fileType,filePath
variables,variables.csv
model-steps,model-steps.csv
```

### Variables File

The [variables
file](https://big-life-lab.github.io/model-parameters/5-reference.html#variables)
specifies which variables are predictors in your model:

```csv
variable,role
age,Predictor
sex,Predictor
bmi,Predictor
```

### Model Steps File

The [model steps](https://big-life-lab.github.io/model-parameters/5-reference.html#model-steps) file specifies the transformation steps to apply in order:

```csv
step,filePath
center,center-params.csv
dummy,dummy-params.csv
interaction,interaction-params.csv
rcs,rcs-params.csv
logistic-regression,logistic-regression-params.csv
```

### Transformation Parameter Files

Each transformation step references its own parameter file:

**Center** (`center-params.csv`):

```csv
origVariable,centerValue,centeredVariable
age,50,age_centered
bmi,25,bmi_centered
```

See
[center](https://big-life-lab.github.io/model-parameters/5-reference.html#center)
in the Model Parameters documentation.

**Dummy** (`dummy-params.csv`):

```csv
origVariable,catValue,dummyVariable
sex,male,sex_male
sex,female,sex_female
```

See
[dummy](https://big-life-lab.github.io/model-parameters/5-reference.html#dummy)
in the Model Parameters documentation.

**Interaction** (`interaction-params.csv`):

```csv
interactingVariables,interactionVariable
age_centered;sex_male,age_sex_interaction
```

See
[interaction](https://big-life-lab.github.io/model-parameters/5-reference.html#interaction)
in the Model Parameters documentation.

**RCS** (`rcs-params.csv`):

```csv
variable,rcsVariables,knots
age,age_rcs1;age_rcs2;age_rcs3,20;40;60;80
```

See
[rcs](https://big-life-lab.github.io/model-parameters/5-reference.html#rcs)
in the Model Parameters documentation.

**Logistic-regression** (`logistic-regression-params.csv`):

```csv
variable,coefficient
Intercept,-2.5
age_centered,0.05
sex_male,0.3
```

See
[logistic-regression](https://big-life-lab.github.io/model-parameters/5-reference.html#logistic-regression)
in the Model Parameters documentation.

## Example: HTNPoRT Model

Here's a complete example using the HTNPoRT (Hypertension Population Risk Tool)
female model.

First clone the HTNPoRT repository to get the model parameters files and
validation data:

```console
git clone git@github.com:Big-Life-Lab/htnport.git
```

Replacing `htnport_dir` below with the path to the cloned HTNPoRT repository:

```r
library(model.parameters.pipeline)

htnport_dir <- "/path/to/htnport"  # Replace with path to local HTNPoRT repo

# Load validation data
data_file <- file.path(
  htnport_dir,
  "output/validation-data/HTNPoRT-female-validation-data.csv"
)
data <- read.csv(data_file)

# Path to model export file
model_export_file <- file.path(
  htnport_dir,
  "output/logistic-model-export/female/HTNPoRT-female-model-export.csv"
)

# Prepare the model pipeline
mod <- prepare_model_pipeline(model_export_file)

# Run the pipeline
mod <- run_model_pipeline(mod, data = data)

# View results
head(mod$df)

# Extract logistic predictions
predictions <- mod$df[, grep("^logistic_", names(mod$df))]
```

## Testing

Run the test suite to verify the package is working correctly:

```r
# Install test dependencies
install.packages("testthat")

# Run tests
devtools::test()
```

## Model Parameters Specification

This package implements transformations according to the Model Parameters
specification used by Big Life Lab. The specification defines how predictive
algorithms store and apply parameter transformations in a standardized CSV
format, enabling:

- Transparent algorithm reporting
- Easy deployment across platforms
- Reproducible transformations
- Language-agnostic implementation

For more information about the Model Parameters specification and Big Life
Lab's predictive models, visit:

- [Big Life Lab GitHub](https://github.com/Big-Life-Lab)
- [Big Life Lab Flow (BLLFlow)](https://github.com/Big-Life-Lab/bllflow)
- [Predictive Algorithms
  Repository](https://github.com/Big-Life-Lab/predictive-algorithms)

## Contributing

Bug reports and feature requests can be submitted to the [issue
tracker](https://github.com/Big-Life-Lab/model-parameters-pipeline/issues).

## License

This package is developed by Big Life Lab for use with their predictive health
models.

## Authors

Martin Wellman (<mwellman@ohri.ca>)

## Version

0.1.0 (2026-01-08)
