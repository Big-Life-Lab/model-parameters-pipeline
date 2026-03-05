# Contributing to Model Parameters Pipeline

Thank you for your interest in contributing to the Model Parameters
Pipeline! This document outlines the guidelines for contributing to this
project.

## Code of Conduct

Please be respectful and constructive in all interactions. We aim to
maintain a welcoming environment for contributors of all backgrounds and
experience levels.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue on
[GitHub](https://github.com/Big-Life-Lab/model-parameters-pipeline/issues)
with:

- A clear description of the problem
- A minimal reproducible example
- Your R version and package version
  (`packageVersion("model.parameters.pipeline")`)

### Suggesting Features

Feature requests are welcome. Open an issue describing:

- The use case you are trying to address
- How the proposed feature would work
- Any relevant references to the [Model Parameters
  specification](https://big-life-lab.github.io/model-parameters/)

### Submitting Changes

1.  Fork the repository and create a branch from `main`
2.  Make your changes, following the code style guidelines below
3.  Add or update tests as needed
4.  Run
    [`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
    to ensure all tests pass
5.  Run
    [`devtools::check()`](https://devtools.r-lib.org/reference/check.html)
    to ensure the package passes R CMD check
6.  Submit a pull request with a clear description of your changes

## Code Style

This project uses [`lintr`](https://lintr.r-lib.org/) to enforce
consistent code style. Before submitting a pull request, check your code
with:

``` r
lintr::lint_package()
```

Key style conventions:

- Use `snake_case` for variable and function names
- Internal (non-exported) functions are prefixed with `.` (e.g.,
  `.run_step_center`)
- Keep lines to a maximum of 80 characters where practical
- Document all exported functions using
  [roxygen2](https://roxygen2.r-lib.org/) comments

## Running Tests

``` r
devtools::test()
```

To regenerate expected test outputs after changing a step’s behaviour:

``` r
source("tests/testthat/generate_step_tests_expected.R")
generate_step_tests_expected()
```

## Package Structure

- `R/` - Source files. One file per transformation step
  (`step-{stepname}.R`), plus core pipeline files
- `tests/testthat/` - Unit tests and test data
- `man/` - Auto-generated documentation (do not edit directly;
  regenerate with
  [`devtools::document()`](https://devtools.r-lib.org/reference/document.html))
- `vignettes/` - Long-form documentation

------------------------------------------------------------------------

## Adding a New Transformation Step

This guide explains how to add support for a new transformation step to
the Model Parameters Pipeline, as defined by the [Model Parameters
repository](https://big-life-lab.github.io/model-parameters/).

### Overview

Adding a new transformation step requires three main tasks:

1.  **Update `run_model_pipeline` in `R/model_parameters_pipeline.R`** -
    Add a new conditional block to recognize the step
2.  **Create a new step source file** - Implement `.run_step_{stepname}`
    in `R/step-{stepname}.R` to execute the transformation
3.  **Add unit tests** - Create test files to verify correct behavior

### Step 1: Update `run_model_pipeline`

The `run_model_pipeline` function in `R/model_parameters_pipeline.R`
processes each step defined in the model steps specification. You need
to add a new conditional block for your step.

#### Location

Find the `if-else` chain in `run_model_pipeline`:

``` r
if (step_name == "center") {
  res <- .run_step_center(mod, file_path)
} else if (step_name == "dummy") {
  res <- .run_step_dummy(mod, file_path)
} else if (step_name == "interaction") {
  res <- .run_step_interaction(mod, file_path)
} else if (step_name == "logistic-regression") {
  res <- .run_step_logistic_regression(mod, file_path)
} else if (step_name == "rcs") {
  res <- .run_step_rcs(mod, file_path)
} else {
  stop(paste0(
    "Unrecognized or unimplemented step type for step #",
    i,
    ": ",
    step_name
  ))
}
```

After each step call, the pipeline extracts the results:

``` r
mod <- res$mod
output_columns <- res$output_columns
```

#### Add Your Step

Add a new `else if` block for your step **before** the final `else`
clause:

``` r
} else if (step_name == "your-step-name") {
  res <- .run_step_your_step_name(mod, file_path)
} else {
  stop(paste0(
    "Unrecognized or unimplemented step type for step #",
    i,
    ": ",
    step_name
  ))
}
```

**Important:**

- Replace `"your-step-name"` with the exact step name as it appears in
  the Model Parameters specification
- Replace `your_step_name` with an underscored version for the function
  name
- The step name must match what users will specify in their
  `model-steps.csv` file

### Step 2: Create the Step Function

Create a new source file `R/step-{stepname}.R` containing a function
named `.run_step_{stepname}` that implements the transformation logic.

#### Create the Source File

Create a new file at `R/step-{stepname}.R` (replace `{stepname}` with
your step name).

#### Function Template

Use this template as a starting point:

``` r
#' Run {Step Name} Step
#'
#' {Brief description of what this step does and its purpose}.
#' Implements the '{stepname}' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object containing input data in \code{mod$data}
#' @param file Path to {stepname} step specification file
#' @return A list containing: \code{mod} (the updated model object with
#'   {description of added data} added to \code{mod$data}), and
#'   \code{output_columns} (character vector of output columns
#'   of this step)
#' @keywords internal
.run_step_{stepname} <- function(mod, file) {
  # Load the step specification file
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)

  # Verify required columns exist in the specification file
  .verify_columns(
    step_data,
    c("column1", "column2", "column3"),
    "{stepname} step file",
    file
  )

  # Track which columns are produced by this step
  output_columns <- c()

  # Process each row in the step specification
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]

    # Extract parameters from the specification
    param1 <- info[["column1"]]
    param2 <- info[["column2"]]
    param3 <- info[["column3"]]

    # Implement your transformation logic here
    # Example: mod$data[new_column] <- transformation(mod$data[existing_column])
    output_columns <- c(output_columns, new_column)
  }

  # Return the updated model object and output column names
  list(
    mod = mod,
    output_columns = output_columns
  )
}
```

#### Key Components Explained

1.  **File Location**:

    - Create your step function in `R/step-{stepname}.R`

2.  **Function Signature**:

    - Always takes `mod` (model object) and `file` (path to
      specification file)
    - Input data is accessed and modified via `mod$data`
    - Always returns a named list with `mod` and `output_columns`
    - Function name is `.run_step_{stepname}` (with leading dot, making
      it internal)

3.  **Load Specification File**:

    ``` r
    mod <- .add_file(mod, file)
    step_data <- .get_file(mod, file)
    ```

    Always use these helper functions to load files — never read files
    directly (e.g. with `read.csv`). `.add_file` and `.get_file` ensure
    that any file path is validated against the sandbox path, if one was
    specified via `prepare_model_pipeline`. This prevents steps from
    reading files outside the permitted directory.

4.  **Verify Columns**:

    ``` r
    .verify_columns(step_data,
                    c("column1", "column2", "column3"),
                    "{stepname} step file",
                    file)
    ```

    Validates that the specification file contains all required columns.
    Update the column list to match your step’s requirements from the
    Model Parameters documentation.

5.  **Process Each Row**: The `for` loop processes each row in the
    specification file. Each row typically defines one transformation to
    apply.

6.  **Access and Write Data**:

    - Read data: `mod$data[column_name]` or `mod$data[[column_name]]`
    - Write data: `mod$data[new_column] <- transformed_values`

7.  **Track Output Columns**: Append each new column name to
    `output_columns` so the pipeline knows which columns this step
    produced. This might include columns that already existed in the
    data (eg. an existing column has been overwritten).

8.  **Return a List**: Always return a named list with `mod` and
    `output_columns` so the pipeline can chain steps together.

#### Example: Center Step

Here’s a real example from the existing codebase (`R/step-center.R`):

``` r
.run_step_center <- function(mod, file) {
  # Load the step specification file
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)

  # Verify required columns exist in the specification file
  .verify_columns(
    step_data,
    c("origVariable", "centerValue", "centeredVariable"),
    "center step file",
    file
  )

  # Track which columns are produced by this step
  output_columns <- c()

  # Process each row in the step specification
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    orig_variable <- info[["origVariable"]]
    center_value <- info[["centerValue"]]
    centered_variable <- info[["centeredVariable"]]

    # Center the variable
    mod$data[centered_variable] <- mod$data[orig_variable] - center_value
    output_columns <- c(output_columns, centered_variable)
  }

  # Return the updated model object and output column names
  list(
    mod = mod,
    output_columns = output_columns
  )
}
```

This function:

- Is defined in its own source file `R/step-center.R`
- Accepts `mod` and `file`; data is accessed via `mod$data`
- Loads the center specification file
- Verifies it has the required columns (`origVariable`, `centerValue`,
  `centeredVariable`)
- For each row, creates a new centered variable by subtracting
  `centerValue` from the original variable in `mod$data`
- Returns a list with the updated model object and the names of the new
  columns

### Step 3: Add Unit Tests

Unit tests ensure your transformation step works correctly. The testing
framework automatically discovers and runs tests based on directory
structure.

#### Quick Reference

See the detailed guide [Model Parameters Step
Tests](https://big-life-lab.github.io/model-parameters-pipeline/tests/testthat/testdata/steps/README.md)
for complete instructions.

### Reference Documentation

For detailed information about Model Parameters transformation steps and
their required file formats, see:

- [Model Parameters Reference
  Documentation](https://big-life-lab.github.io/model-parameters/5-reference.html)
- [Step Tests
  README](https://big-life-lab.github.io/model-parameters-pipeline/tests/testthat/testdata/steps/README.md)

### Checklist

Use this checklist when adding a new transformation step:

Create new source file: `R/step-{stepname}.R`

Implement `.run_step_{stepname}` function with proper documentation in
the new source file

Add `else if` block in
[run_model_pipeline](https://big-life-lab.github.io/model-parameters-pipeline/R/model_parameters_pipeline.R)
for the new step name

Verify column names match the Model Parameters specification

Create test directory: `tests/testthat/testdata/steps/{stepname}/`

Create `model-export.csv` in test directory

Create `model-steps.csv` in test directory

Create `{stepname}.csv` with test parameters in test directory

Generate expected output using `generate_step_tests_expected()`

Run [`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
to verify tests pass

Review and commit all changes including `expected.csv`

### Common Patterns

#### Parsing Delimited Strings

Some steps use delimited strings (e.g., “var1;var2;var3”) in their
parameters file. Use the helper function:

``` r
parts <- .get_string_parts(info[["columnName"]])
```

#### Working with Numeric Values

Convert string values to numeric when needed:

``` r
numeric_values <- as.double(.get_string_parts(info[["knots"]]))
```

#### Creating New Columns Safely

To avoid column name conflicts:

``` r
new_col <- .get_unused_column(colnames(mod$data), "prefix")
```

#### Adding Multiple Columns

You can add multiple columns at once using data frame assignment:

``` r
# Create a data frame with new columns
new_cols <- data.frame(
  col1 = values1,
  col2 = values2
)
mod$data[c("col1", "col2")] <- new_cols
```

### Getting Help

- For Model Parameters specification questions, refer to the [Model
  Parameters
  documentation](https://big-life-lab.github.io/model-parameters/)
- For existing step implementation examples, see source files like
  `R/step-center.R`, `R/step-dummy.R`, etc.
- For testing questions, see
  [tests/testthat/testdata/steps/README.md](https://big-life-lab.github.io/model-parameters-pipeline/tests/testthat/testdata/steps/README.md)
