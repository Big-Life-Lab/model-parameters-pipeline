# Adding a New Transformation Step

This guide explains how to add support for a new transformation step to
the Model Parameters Pipeline, as defined by the [Model Parameters
repository](https://big-life-lab.github.io/model-parameters/).

## Overview

Adding a new transformation step requires three main tasks:

1.  **Update
    [run_model_pipeline](https://big-life-lab.github.io/model-parameters-pipeline/R/model_parameters_pipeline.R)** -
    Add a new conditional block to recognize the step
2.  **Create a new step source file** - Implement `.run_step_{stepname}`
    in `R/step-{stepname}.R` to execute the transformation
3.  **Add unit tests** - Create test files to verify correct behavior

## Step 1: Update `run_model_pipeline`

The
[run_model_pipeline](https://big-life-lab.github.io/model-parameters-pipeline/R/model_parameters_pipeline.R)
function in
[R/model_parameters_pipeline.R](https://big-life-lab.github.io/model-parameters-pipeline/R/model_parameters_pipeline.R)
processes each step defined in the model steps specification. You need
to add a new conditional block for your step.

### Location

Find the `if-else` chain in `run_model_pipeline`:

``` r
if (step_name == "center") {
  mod <- .run_step_center(mod, file_path)
} else if (step_name == "dummy") {
  mod <- .run_step_dummy(mod, file_path)
} else if (step_name == "interaction") {
  mod <- .run_step_interaction(mod, file_path)
} else if (step_name == "logistic") {
  mod <- .run_step_logistic(mod, file_path)
} else if (step_name == "rcs") {
  mod <- .run_step_rcs(mod, file_path)
} else {
  stop(paste0(
    "Unrecognized or unimplemented step type for step #",
    i,
    ": ",
    step_name
  ))
}
```

### Add Your Step

Add a new `else if` block for your step **before** the final `else`
clause:

``` r
} else if (step_name == "your-step-name") {
  mod <- .run_step_your_step_name(mod, file_path)
} else {
  stop(paste0(
    "Unrecognized or unimplemented step type for step #",
    i,
    ": ",
    step_name
  ))
}
```

**Important:** - Replace `"your-step-name"` with the exact step name as
it appears in the Model Parameters specification - Replace
`your_step_name` with an underscored version for the function name - The
step name must match what users will specify in their `model-steps.csv`
file

## Step 2: Create the Step Function

Create a new source file `R/step-{stepname}.R` containing a function
named `.run_step_{stepname}` that implements the transformation logic.

### Create the Source File

Create a new file at `R/step-{stepname}.R` (replace `{stepname}` with
your step name).

### Function Template

Use this template as a starting point:

``` r
#' Run {Step Name} Step
#'
#' {Brief description of what this step does and its purpose}.
#' Implements the '{stepname}' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object
#' @param file Path to {stepname} step specification file
#' @return Updated model object with {description of added data}
#' @keywords internal
.run_step_{stepname} <- function(mod, file) {
  # Load the step specification file
  mod <- .add_file(mod, file)
  step_df <- .get_file(mod, file)

  # Verify required columns exist in the specification file
  .verify_columns(
    step_df,
    c("column1", "column2", "column3"),
    "{stepname} step file",
    file
  )

  # Process each row in the step specification
  for (i in seq_len(nrow(step_df))) {
    info <- step_df[i, ]

    # Extract parameters from the specification
    param1 <- info[["column1"]]
    param2 <- info[["column2"]]
    param3 <- info[["column3"]]

    # Implement your transformation logic here
    # Example: mod$df[new_column] <- transformation(mod$df[existing_column])
  }

  # Return the updated model object
  mod
}
```

### Key Components Explained

1.  **File Location**:

    - Create your step function in `R/step-{stepname}.R`

2.  **Function Signature**:

    - Always takes `mod` (model object) and `file` (path to
      specification file)
    - Always returns the updated `mod` object
    - Function name is `.run_step_{stepname}` (no leading dot)

3.  **Load Specification File**:

    ``` r
    mod <- .add_file(mod, file)
    step_df <- .get_file(mod, file)
    ```

    These helper functions cache and retrieve the CSV specification
    file.

4.  **Verify Columns**:

    ``` r
    .verify_columns(step_df,
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

6.  **Access Data**:

    - Read data: `mod$df[column_name]` or `mod$df[[column_name]]`
    - Write data: `mod$df[new_column] <- transformed_values`

7.  **Return Updated Model**: Always return `mod` at the end so
    transformations can be chained.

### Example: Center Step

Here’s a real example from the existing codebase
([R/step-center.R](https://big-life-lab.github.io/model-parameters-pipeline/R/step-center.R)):

``` r
.run_step_center <- function(mod, file) {
  mod <- .add_file(mod, file)
  step_df <- .get_file(mod, file)
  .verify_columns(
    step_df,
    c("origVariable", "centerValue", "centeredVariable"),
    "center step file",
    file
  )

  for (i in seq_len(nrow(step_df))) {
    info <- step_df[i, ]
    orig_variable <- info[["origVariable"]]
    center_value <- info[["centerValue"]]
    centered_variable <- info[["centeredVariable"]]

    mod$df[centered_variable] <- mod$df[orig_variable] - center_value
  }

  mod
}
```

This function: - Is defined in its own source file `R/step-center.R` -
Loads the center specification file - Verifies it has the required
columns (`origVariable`, `centerValue`, `centeredVariable`) - For each
row, creates a new centered variable by subtracting `centerValue` from
the original variable - Returns the updated model with new columns added
to `mod$df`

## Step 3: Add Unit Tests

Unit tests ensure your transformation step works correctly. The testing
framework automatically discovers and runs tests based on directory
structure.

### Quick Reference

See the detailed guide at
[tests/testthat/testdata/step-tests/README.md](https://big-life-lab.github.io/model-parameters-pipeline/tests/testthat/testdata/step-tests/README.md)
for complete instructions.

### Summary

1.  **Create test directory**:
    `tests/testthat/testdata/step-tests/test-{stepname}/`

2.  **Create required files**:

    - `test-model-export.csv` - Points to variables and model steps
      files
    - `test-model-steps.csv` - Defines which step to test
    - `test-{stepname}.csv` - Contains step-specific parameters

3.  **Generate expected output**:

    ``` r
    source("tests/testthat/generate_step_tests_expected.R")
    generate_step_tests_expected(steps = "stepname")
    ```

4.  **Run tests**:

    ``` r
    devtools::test()
    ```

    Your test is automatically discovered and run!

### Test File Structure

    tests/testthat/testdata/step-tests/
    ├── test-data.csv              # Shared test data (already exists)
    ├── test-variables.csv         # Shared variables definition (already exists)
    └── test-{stepname}/           # Your new test directory
        ├── test-model-export.csv  # References to files
        ├── test-model-steps.csv   # Step definition
        ├── test-{stepname}.csv    # Step parameters
        └── test-expected.csv      # Auto-generated expected output

## Reference Documentation

For detailed information about Model Parameters transformation steps and
their required file formats, see:

- [Model Parameters Reference
  Documentation](https://big-life-lab.github.io/model-parameters/5-reference.html)
- [Step Tests
  README](https://big-life-lab.github.io/model-parameters-pipeline/tests/testthat/testdata/step-tests/README.md)

## Checklist

Use this checklist when adding a new transformation step:

Create new source file: `R/step-{stepname}.R`

Implement `.run_step_{stepname}` function with proper documentation in
the new source file

Add `else if` block in
[run_model_pipeline](https://big-life-lab.github.io/model-parameters-pipeline/R/model_parameters_pipeline.R)
for the new step name

Verify column names match the Model Parameters specification

Create test directory:
`tests/testthat/testdata/step-tests/test-{stepname}/`

Create `test-model-export.csv` in test directory

Create `test-model-steps.csv` in test directory

Create `test-{stepname}.csv` with test parameters in test directory

Generate expected output using `generate_step_tests_expected()`

Run [`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
to verify tests pass

Review and commit all changes including `test-expected.csv`

## Common Patterns

### Parsing Delimited Strings

Some steps use delimited strings (e.g., “var1;var2;var3”) in their
parameters file. Use the helper function:

``` r
parts <- .get_string_parts(info[["columnName"]])
```

### Working with Numeric Values

Convert string values to numeric when needed:

``` r
numeric_values <- as.double(.get_string_parts(info[["knots"]]))
```

### Creating New Columns Safely

To avoid column name conflicts:

``` r
new_col <- .get_unused_column(mod$df, "prefix_")
```

### Adding Multiple Columns

You can add multiple columns at once using data frame assignment:

``` r
# Create a data frame with new columns
new_cols <- data.frame(
  col1 = values1,
  col2 = values2
)
mod$df[c("col1", "col2")] <- new_cols
```

## Getting Help

- For Model Parameters specification questions, refer to the [Model
  Parameters
  documentation](https://big-life-lab.github.io/model-parameters/)
- For existing step implementation examples, see source files like
  [R/step-center.R](https://big-life-lab.github.io/model-parameters-pipeline/R/step-center.R),
  [R/step-dummy.R](https://big-life-lab.github.io/model-parameters-pipeline/R/step-dummy.R),
  etc.
- For testing questions, see
  [tests/testthat/testdata/step-tests/README.md](https://big-life-lab.github.io/model-parameters-pipeline/tests/testthat/testdata/step-tests/README.md)
