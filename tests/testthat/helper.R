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

#' Run test data through model pipeline and validate output
#'
#' Executes the model pipeline with test data and compares the output
#' against expected validation data using testthat expectations.
#'
#' @param dir_name Character string specifying the test directory name
#'   within "data/tests/step-tests"
#' @param input_data_file Character string specifying the input data file name
#'   to be used for the test
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
run_test_data <- function(dir_name, input_data_file) {
  # Run the pipeline to get the output
  root_dir <- "testdata/step-tests"
  data_file <- testthat::test_path(root_dir, input_data_file)
  model_export_file <-
    testthat::test_path(root_dir, dir_name, "test-model-export.csv")
  mod <- prepare_model_pipeline(model_export_file)
  output_data <- run_model_pipeline(mod, data = data_file, mode = "full")

  # Compare the pipeline output to the expected output
  valid_data_file <-
    testthat::test_path(root_dir, dir_name, "test-expected.csv")
  valid_data <- utils::read.csv(valid_data_file)
  expect_equal(output_data,
    valid_data,
    info = paste("Failed on transformation step", dir_name)
  )
}
