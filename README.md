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
New Transformation Step](CONTRIBUTING.md#adding-a-new-transformation-step).

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

For usage details and examples, view the documentation at [Introduction to
Model Parameters
Pipeline](https://big-life-lab.github.io/model-parameters-pipeline/articles/introduction.html).

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

- [Model Parameters
  Repository](https://github.com/Big-Life-Lab/model-parameters)
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
