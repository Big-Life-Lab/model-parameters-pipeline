# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
