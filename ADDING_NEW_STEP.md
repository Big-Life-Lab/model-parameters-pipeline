# Adding a New Transformation Step

This guide explains how to add support for a new transformation step to the
Model Parameters Pipeline, as defined by the [Model Parameters
repository](https://big-life-lab.github.io/model-parameters/).

## Overview

Adding a new transformation step requires three main tasks:

1. **Update [run_model_pipeline](R/model_parameters_pipeline.R)** - Add a
   new conditional block to recognize the step
2. **Create a new step source file** - Implement `.run_step_{stepname}` in
   `R/step-{stepname}.R` to execute the transformation
3. **Add unit tests** - Create test files to verify correct behavior

## Step 1: Update `run_model_pipeline`

The [run_model_pipeline](R/model_parameters_pipeline.R) function in
[R/model_parameters_pipeline.R](R/model_parameters_pipeline.R) processes each
step defined in the model steps specification. You need to add a new
conditional block for your step.

### Location

Find the `if-else` chain in `run_model_pipeline`:

```r
if (step_name == "center") {
  res <- .run_step_center(mod, dat, file_path)
} else if (step_name == "dummy") {
  res <- .run_step_dummy(mod, dat, file_path)
} else if (step_name == "interaction") {
  res <- .run_step_interaction(mod, dat, file_path)
} else if (step_name == "logistic-regression") {
  res <- .run_step_logistic_regression(mod, dat, file_path)
} else if (step_name == "rcs") {
  res <- .run_step_rcs(mod, dat, file_path)
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

```r
mod <- res$mod
dat <- res$data
output_columns <- res$output_columns
```

### Add Your Step

Add a new `else if` block for your step **before** the final `else` clause:

```r
} else if (step_name == "your-step-name") {
  res <- .run_step_your_step_name(mod, dat, file_path)
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

- Replace `"your-step-name"` with the exact step name as it appears in the
  Model Parameters specification
- Replace `your_step_name` with an underscored version for the function name
- The step name must match what users will specify in their `model-steps.csv`
  file

## Step 2: Create the Step Function

Create a new source file `R/step-{stepname}.R` containing a function
named `.run_step_{stepname}` that implements the transformation logic.

### Create the Source File

Create a new file at `R/step-{stepname}.R` (replace `{stepname}` with
your step name).

### Function Template

Use this template as a starting point:

```r
#' Run {Step Name} Step
#'
#' {Brief description of what this step does and its purpose}.
#' Implements the '{stepname}' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object
#' @param dat Data frame containing the input data to be transformed
#' @param file Path to {stepname} step specification file
#' @return A list containing: \code{mod} (the updated model object),
#'   \code{data} (the transformed data frame with {description of added data}),
#'   and \code{output_columns} (character vector of new column names added
#'   by this step)
#' @keywords internal
.run_step_{stepname} <- function(mod, dat, file) {
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
    # Example: dat[new_column] <- transformation(dat[existing_column])
    output_columns <- c(output_columns, new_column)
  }

  # Return the updated model object, transformed data, and output column names
  list(
    mod = mod,
    data = dat,
    output_columns = output_columns
  )
}
```

### Key Components Explained

1. **File Location**:
   - Create your step function in `R/step-{stepname}.R`

2. **Function Signature**:
   - Always takes `mod` (model object), `dat` (input data frame), and `file`
     (path to specification file)
   - Always returns a named list with `mod`, `data`, and `output_columns`
   - Function name is `.run_step_{stepname}` (with leading dot, making it
     internal)

3. **Load Specification File**:

   ```r
   mod <- .add_file(mod, file)
   step_data <- .get_file(mod, file)
   ```

   These helper functions cache and retrieve the CSV specification file.

4. **Verify Columns**:

   ```r
   .verify_columns(step_data,
                   c("column1", "column2", "column3"),
                   "{stepname} step file",
                   file)
   ```

   Validates that the specification file contains all required columns. Update
   the column list to match your step's requirements from the Model Parameters
   documentation.

5. **Process Each Row**: The `for` loop processes each row in the specification
   file. Each row typically defines one transformation to apply.

6. **Access and Write Data**:
   - Read data: `dat[column_name]` or `dat[[column_name]]`
   - Write data: `dat[new_column] <- transformed_values`

7. **Track Output Columns**: Append each new column name to `output_columns`
   so the pipeline knows which columns this step produced.

8. **Return a List**: Always return a named list with `mod`, `data`, and
   `output_columns` so the pipeline can chain steps together.

### Example: Center Step

Here's a real example from the existing codebase
([R/step-center.R](R/step-center.R)):

```r
.run_step_center <- function(mod, dat, file) {
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)
  .verify_columns(
    step_data,
    c("origVariable", "centerValue", "centeredVariable"),
    "center step file",
    file
  )

  output_columns <- c()
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    orig_variable <- info[["origVariable"]]
    center_value <- info[["centerValue"]]
    centered_variable <- info[["centeredVariable"]]

    dat[centered_variable] <- dat[orig_variable] - center_value
    output_columns <- c(output_columns, centered_variable)
  }

  list(
    mod = mod,
    data = dat,
    output_columns = output_columns
  )
}
```

This function:

- Is defined in its own source file `R/step-center.R`
- Accepts `mod`, `dat` (the data to transform), and `file`
- Loads the center specification file
- Verifies it has the required columns (`origVariable`, `centerValue`,
  `centeredVariable`)
- For each row, creates a new centered variable by subtracting `centerValue`
  from the original variable in `dat`
- Returns a list with the updated model object, the modified data frame, and
  the names of the new columns

## Step 3: Add Unit Tests

Unit tests ensure your transformation step works correctly. The testing
framework automatically discovers and runs tests based on directory structure.

### Quick Reference

See the detailed guide at
[tests/testthat/testdata/step-tests/README.md](tests/testthat/testdata/step-tests/README.md)
for complete instructions.

### Summary

1. **Create test directory**:
   `tests/testthat/testdata/step-tests/test-{stepname}/`

2. **Create required files**:
   - `test-model-export.csv` - Points to variables and model steps files
   - `test-model-steps.csv` - Defines which step to test
   - `test-{stepname}.csv` - Contains step-specific parameters

3. **Generate expected output**:

   ```r
   source("tests/testthat/generate_step_tests_expected.R")
   generate_step_tests_expected(steps = "stepname")
   ```

4. **Run tests**:

   ```r
   devtools::test()
   ```

   Your test is automatically discovered and run!

### Test File Structure

```text
tests/testthat/testdata/step-tests/
├── test-data.csv              # Shared test data (already exists)
├── test-variables.csv         # Shared variables definition (already exists)
└── test-{stepname}/           # Your new test directory
    ├── test-model-export.csv  # References to files
    ├── test-model-steps.csv   # Step definition
    ├── test-{stepname}.csv    # Step parameters
    └── test-expected.csv      # Auto-generated expected output
```

## Reference Documentation

For detailed information about Model Parameters transformation steps and their
required file formats, see:

- [Model Parameters Reference
  Documentation](https://big-life-lab.github.io/model-parameters/5-reference.html)
- [Step Tests README](tests/testthat/testdata/step-tests/README.md)

## Checklist

Use this checklist when adding a new transformation step:

- [ ] Create new source file: `R/step-{stepname}.R`
- [ ] Implement `.run_step_{stepname}` function with proper documentation in the
  new source file
- [ ] Add `else if` block in
  [run_model_pipeline](R/model_parameters_pipeline.R) for the new step
  name
- [ ] Verify column names match the Model Parameters specification
- [ ] Create test directory:
  `tests/testthat/testdata/step-tests/test-{stepname}/`
- [ ] Create `test-model-export.csv` in test directory
- [ ] Create `test-model-steps.csv` in test directory
- [ ] Create `test-{stepname}.csv` with test parameters in test directory
- [ ] Generate expected output using `generate_step_tests_expected()`
- [ ] Run `devtools::test()` to verify tests pass
- [ ] Review and commit all changes including `test-expected.csv`

## Common Patterns

### Parsing Delimited Strings

Some steps use delimited strings (e.g., "var1;var2;var3") in their parameters
file. Use the helper function:

```r
parts <- .get_string_parts(info[["columnName"]])
```

### Working with Numeric Values

Convert string values to numeric when needed:

```r
numeric_values <- as.double(.get_string_parts(info[["knots"]]))
```

### Creating New Columns Safely

To avoid column name conflicts:

```r
new_col <- .get_unused_column(dat, "prefix_")
```

### Adding Multiple Columns

You can add multiple columns at once using data frame assignment:

```r
# Create a data frame with new columns
new_cols <- data.frame(
  col1 = values1,
  col2 = values2
)
dat[c("col1", "col2")] <- new_cols
```

## Getting Help

- For Model Parameters specification questions, refer to the [Model Parameters
  documentation](https://big-life-lab.github.io/model-parameters/)
- For existing step implementation examples, see source files like
  [R/step-center.R](R/step-center.R),
  [R/step-dummy.R](R/step-dummy.R), etc.
- For testing questions, see
  [tests/testthat/testdata/step-tests/README.md](tests/testthat/testdata/step-tests/README.md)
