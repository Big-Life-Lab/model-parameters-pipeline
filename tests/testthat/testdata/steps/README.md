# Model Parameters Step Tests

This directory contains unit tests for Model Parameters transformation steps.
Each subdirectory represents a test case for a specific transformation step.
The root directory is at tests/testthat/testdata/steps.

## Directory Structure

```
steps/
├── README.md              # This file
├── data.csv               # Shared test data used by all step tests
├── variables.csv          # Shared variables definition file
└── {stepname}/            # Test directory for a specific step
    ├── model-export.csv   # Model export file defining files for transformation
    ├── model-steps.csv    # Model steps file defining transformation steps
    ├── {stepname}.csv     # Step-specific parameters file
    └── expected.csv       # Expected output (auto-generated)
```

## Adding a New Unit Test

To add a unit test for a Model Parameters transformation step:

### 1. Create Test Directory

Create a new subdirectory named `{stepname}` where `{stepname}` is the
name of the transformation step you want to test.

### 2. Create Required Files

Each test directory must contain the following files:

#### `model-export.csv`

This file defines the files used for the transformation. It generally has the
same structure for each unit test:

```csv
fileType,filePath
variables,../variables.csv
model-steps,./model-steps.csv
```

The file references:

- `variables.csv` - The shared variables definition file (located in the
  parent directory)
- `model-steps.csv` - The model steps file (located in the test directory)

#### `model-steps.csv`

This file defines the transformation steps to execute. The structure is:

```csv
step,fileType,filePath,notes
{stepname},N/A,./{stepname}.csv,
```

Replace `{stepname}` with your step name. If the step doesn't require a
separate file, use `N/A` for `fileType` and `filePath`.

#### `{stepname}.csv`

This file contains step-specific parameters. The structure depends on the
transformation step being tested. For example, a logistic regression step would
have the coefficients for each variable and the intercept. Refer to the [Model
Parameters
documentation](https://big-life-lab.github.io/model-parameters/5-reference.html)
for details on each step's required parameters.

### 3. Generate Expected Output

After creating your test files, generate the expected output by running:

```r
devtools::load_all()
source("tests/testthat/generate_step_tests_expected.R")

# Generate expected output for all tests
generate_step_tests_expected()

# Or generate for only your new test
generate_step_tests_expected(steps = "stepname")
```

This function will:

1. Read the shared test data from `data.csv`
2. Iterate through each subdirectory in the steps folder (or only
   specified steps)
3. Run the model pipeline using each `model-export.csv` file
4. Save the pipeline output as `expected.csv` in each subdirectory

The generated `expected.csv` file will be used by the unit tests to verify
correct transformation behavior.

### 4. Run Tests Automatically

Once you've created your test directory and generated the expected output, your
new unit test will be **automatically discovered and run** when the test suite
executes. No additional registration or configuration is needed.

The test automation is implemented in
[test-model_parameters_pipeline.R](../../test-model_parameters_pipeline.R),
which:

1. Scans all subdirectories in the `steps/` folder
2. Automatically runs each test it finds
3. Compares the pipeline output against the `expected.csv` file

To run all tests, execute:

```r
# Run all tests
devtools::load_all()
testthat::test_dir("tests/testthat")

# Or run tests in RStudio
devtools::test()
```

Your new step test will be included automatically alongside all existing step
tests.

## Model Parameters Steps Reference

For detailed information about available transformation steps and their
parameters, see the [Model Parameters Reference
Documentation](https://big-life-lab.github.io/model-parameters/5-reference.html).

## Regenerating Expected Output

If you need to update the expected output after fixing a bug or updating
transformation logic, follow the same process as described in section "3.
Generate Expected Output" above. The `generate_step_tests_expected()` function
can regenerate output for all tests or specific tests using the `steps`
parameter.

After regenerating, review the changes to ensure the new output is correct, then
commit the updated `expected.csv` files.
