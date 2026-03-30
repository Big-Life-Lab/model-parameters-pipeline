library(testthat)

#' Get HTNPoRT file paths
#'
#' Constructs file paths for HTNPoRT model files based on sex.
#'
#' @param sex Character string indicating sex ("male" or "female")
#'
#' @return A list containing:
#'   \item{root_dir}{Root directory path for model export files}
#'   \item{data_file}{Path to validation data CSV file}
#'   \item{model_steps_file}{Path to model steps CSV file}
#'   \item{variables_file}{Path to variables CSV file}
#'   \item{model_export_file}{Path to model export CSV file}
#'
#' @keywords internal
get_htnport_paths <- function(sex) {
  root_dir <- "testdata/htnport"
  data_file <-
    testthat::test_path(
      root_dir,
      paste0("HTNPoRT-", sex, "-validation-data.csv")
    )
  model_steps_file <-
    testthat::test_path(
      root_dir,
      paste0("HTNPoRT-", sex, "-model-steps.csv")
    )
  variables_file <-
    testthat::test_path(
      root_dir,
      paste0("HTNPoRT-", sex, "-variables.csv")
    )
  model_export_file <-
    testthat::test_path(
      root_dir,
      paste0("HTNPoRT-", sex, "-model-export.csv")
    )

  list(
    root_dir = dirname(model_export_file),
    data_file = data_file,
    model_steps_file = model_steps_file,
    variables_file = variables_file,
    model_export_file = model_export_file
  )
}

#' Run test input data (found on disk) through a model pipeline for a Model
#' Parameters step and validate the output.
#'
#' @param step Character string specifying the step name to test. There must
#'   be a directory with the same name as the step, within
#'   "tests/testthat/testdata/steps". See the CONTRIBUTING.md document for
#'   instructions on how to set up this directory with the required files.
#'
#' @return NULL (invisibly). Function is called for side effect of
#'   running testthat expectations.
#'
#' @details This function:
#'   \itemize{
#'     \item Runs the model pipeline with test data
#'     \item Loads expected validation data
#'     \item Compares pipeline output to expected output using expect_equal
#'   }
#'
#' @keywords internal
run_step_on_test_data <- function(step) {
  # Run the pipeline to get the output
  root_dir <- "testdata/steps"
  data_file <- testthat::test_path(root_dir, "data.csv")
  model_export_file <-
    testthat::test_path(root_dir, step, "model-export.csv")
  mod <- prepare_model_pipeline(model_export_file)
  output_data <- run_model_pipeline(mod, dat = data_file, mode = "full")

  # Compare the pipeline output to the expected output
  valid_data_file <-
    testthat::test_path(root_dir, step, "expected.csv")
  valid_data <- utils::read.csv(valid_data_file)
  expect_equal(
    output_data,
    valid_data,
    info = paste("Failed on transformation step", step)
  )
}
