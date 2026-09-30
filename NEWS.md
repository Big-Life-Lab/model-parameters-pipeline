# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Input validation**: The pipeline now raises classified errors instead of
  failing cryptically (or producing silent `NaN`s) on malformed model
  configuration files:
  - `empty_pipeline`: raised by `run_model_pipeline()` when the model steps
    file defines no transformation steps.
  - `rcs_variable_count_mismatch`: raised by the `rcs` step when the number of
    `rcsVariables` does not equal the number of knots minus one.
  - `non_numeric_knots`: raised by the `rcs` step when a knot value cannot be
    parsed as a number (previously propagated silently to `NaN` output).
  - `non_numeric_center_value`: raised by the `center` step when a
    `centerValue` cannot be parsed as a number.
  - `non_numeric_coefficient`: raised by the `logistic-regression` step when a
    `coefficient` cannot be parsed as a number.

### Changed

- Clarified the `run_model_pipeline()` documentation for `mode = "full"` to
  note that it returns predictor and derived columns only; input columns not
  listed as predictors in the variables file are not included.
- Removed the unreachable `file_not_added` error from the `run_model_pipeline()`
  documentation.

## [0.2.4] - 2026-04-01

### Added

- **Core Pipeline Functionality**: Sequential data transformation pipeline
  supporting multiple transformation steps
- **Transformation Steps**:
  - `center`: Centers variables by subtracting a specified value
  - `dummy`: Creates dummy variables for categorical values
  - `interaction`: Creates interaction terms by multiplying variables
  - `rcs`: Applies restricted cubic spline transformations
  - `logistic-regression`: Applies logistic regression with coefficients
- **Security**: Allow sandbox paths to prevent Model Parameters configuration
  files from referencing files outside of the sandbox path
