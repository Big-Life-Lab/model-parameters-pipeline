# Changelog

## model.parameters.pipeline 0.1.0

### Initial Release (2026-01-08)

This is the first release of the Model Parameters Pipeline package,
implementing transformations according to the Model Parameters
specification developed by Big Life Lab.

#### Features

- **Core Pipeline Functionality**: Sequential data transformation
  pipeline supporting multiple transformation steps
- **Transformation Steps**:
  - `center`: Centers variables by subtracting a specified value
  - `dummy`: Creates dummy variables for categorical values
  - `interaction`: Creates interaction terms by multiplying variables
  - `rcs`: Applies restricted cubic spline transformations
  - `logistic-regression`: Applies logistic regression with coefficients
- **Flexible Input**: Support for both file paths and data frames as
  inputs
- **Performance Optimization**: Ability to reuse model objects for
  repeated transformations with different data
- **Model Parameters Specification**: Full compatibility with Big Life
  Lab’s Model Parameters specification used by HTNPoRT, DemPoRT,
  CVDPoRT, and MPoRT models

#### Documentation

- Comprehensive README with usage examples and file structure
  documentation
- Function documentation for all exported functions
- HTNPoRT model example demonstrating real-world usage
- Guide for adding new transformation steps (ADDING_NEW_STEP.md)

#### Testing

- Test suite using testthat framework
- Tests for all transformation steps
- Integration tests for complete pipeline execution
