#' Generate Expected Output for Model Parameters Step Tests
#'
#' @description
#' This function generates expected output files for unit tests of the model
#' parameters pipeline steps. It iterates through subdirectories in the
#' tests/testthat/testdata/steps folder, runs the model pipeline on each
#' test case in the folder, and saves the results as expected output files
#' for comparison in testthat unit tests.
#'
#' @param steps Character vector of step names to generate expected output for.
#'   If NULL (default), generates output for all steps. Step names correspond
#'   to directory names (e.g., "dummy", "center", "rcs").
#'
#' @details
#' The function performs the following operations:
#' \itemize{
#'   \item Reads the shared test data from `data.csv`
#'   \item Iterates through subdirectories in the steps folder (or only
#'         specified steps if `steps` parameter is provided)
#'   \item For each subdirectory, runs the model pipeline using the
#'         corresponding `model-export.csv` file
#'   \item Saves the pipeline output as `expected.csv` in each subdirectory
#' }
#'
#' This is a utility function intended to be run manually when test expectations
#' need to be updated or regenerated, not as part of the regular test suite.
#'
#' @return NULL (invisibly). The function is called for its side effects of
#'   creating/updating `expected.csv` files in each step directory.
#'
#' @seealso [run_model_pipeline()] for the pipeline function being tested
#'
#' @examples
#' \dontrun{
#' # Regenerate all expected test outputs
#' generate_step_tests_expected()
#'
#' # Regenerate expected output for specific steps only
#' generate_step_tests_expected(steps = "dummy")
#' generate_step_tests_expected(steps = c("center", "rcs"))
#' }
#'
#' @keywords internal
#' @noRd
generate_step_tests_expected <- function(steps = NULL) {
  root_dir <- testthat::test_path("testdata/steps")
  data <- utils::read.csv(file.path(root_dir, "data.csv"))

  if (!is.null(steps)) {
    if (is.character(steps)) {
      steps <- c(steps)
    }
  }

  for (cur_dir in list.dirs(root_dir, recursive = FALSE)) {
    if (!is.null(steps) && !(basename(cur_dir) %in% steps)) {
      next
    }

    # Run the pipeline on the current directory
    model_export_file <- file.path(cur_dir, "model-export.csv")
    mod <- prepare_model_pipeline(model_export_file)
    output_data <- get_pipeline_output(
      run_model_pipeline(mod, dat = data),
      mode = "full"
    )

    # Save the results as the expected output
    cat("Saving expected output for", basename(cur_dir), "\n")
    output_file <- file.path(cur_dir, "expected.csv")
    write.csv(output_data, output_file, row.names = FALSE)
  }
}
