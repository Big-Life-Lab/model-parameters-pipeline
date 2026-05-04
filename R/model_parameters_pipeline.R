#' Model Parameters Pipeline
#'
#' This module provides functions to prepare and run a model parameters
#' pipeline for applying sequential data transformations as defined by the
#' Model Parameters specification developed by Big Life Lab.
#'
#' @section Workflow:
#' The typical workflow involves two steps:
#' \enumerate{
#'   \item \code{prepare_model_pipeline()}: Load and validate model
#'     configuration
#'   \item \code{run_model_pipeline()}: Apply transformations to data
#'     and retrieve the output of the model pipeline. The output is the
#'     results of the last transformation step. Depending on the step,
#'     this may include multiple columns.
#' }
#'
#' @section Required Files:
#' The pipeline requires the following CSV files:
#' \describe{
#'   \item{Model Export}{Points to variables and model-steps files}
#'   \item{Variables}{Lists predictor variables}
#'   \item{Model Steps}{Defines transformation sequence}
#'   \item{Step Parameter Files}{Define parameters for each transformation step}
#' }
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' result <- run_model_pipeline(mod, x = "path/to/input-data.csv")
#'
#' # Processing multiple datasets with the same model
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' for (data_file in data_files) {
#'   result <- run_model_pipeline(mod, x = data_file)
#'   # Process result (a data frame)
#' }
#'
#' # Pass a data frame to run_model_pipeline
#' input_data <- read.csv("path/to/input-data.csv")
#' result <- run_model_pipeline(mod, x = input_data)
#' }
#'
#' @seealso
#' \itemize{
#'   \item \href{https://github.com/Big-Life-Lab/model-parameters}{Model
#'     Parameters Specification}
#'   \item
#'     \href{https://big-life-lab.github.io/model-parameters/5-reference.html}{
#'     Model Parameters Reference Documentation}
#' }
#'
#' @name model.parameters.pipeline
NULL

#' Prepare Model Pipeline
#'
#' Loads and validates model configuration files, preparing the pipeline for
#' execution. This function reads the model export file, variables file, and
#' model steps file, and preloads all transformation parameter files into
#' a cached model object.
#'
#' @param model_export A file path (character) to a model export CSV file.
#'   The model export must contain columns 'fileType' and 'filePath' that
#'   specify the locations of the variables and model-steps files. The
#'   directory containing the model export file is used as the root
#'   directory for resolving relative file paths found within the
#'   model-steps file.
#' @param sandbox_path Character or \code{NULL}. If specified, all file paths
#'   referenced in the model parameters configuration files (model export,
#'   variables, model steps, and step parameter files) must be descendants of
#'   this directory. If any file resolves outside of \code{sandbox_path}, an
#'   error is raised. This prevents access to files outside the expected
#'   directory structure, which is useful when running on a server or other
#'   public-facing system where increased security is required. Note that this
#'   restriction does not apply to data files passed to
#'   \code{\link{run_model_pipeline}}. Defaults to \code{NULL} (no restriction).
#'
#' @return A model object (list) that can be used to pass to
#'   \code{\link{run_model_pipeline}}.
#'
#' @section Errors:
#' \itemize{
#'   \item \code{inaccessible_file}: Raised when any of the model export,
#'     variables, model steps, or step parameter files does not exist or, if
#'     `sandbox_path` is set, is not a descendant of that directory.
#'   \item \code{invalid_file_format}: Raised when any of the model export,
#'     variables, model steps, or step parameter files exists but cannot be
#'     parsed as a CSV.
#'   \item \code{invalid_model_export}: Raised when the model export file does
#'     not have exactly one row where \code{fileType} equals \code{"variables"}
#'     or exactly one row where \code{fileType} equals \code{"model-steps"}.
#'   \item \code{missing_columns}: Raised when any of the Model Parameters
#'     files is missing a required column.
#'   \item \code{empty_step_file_path}: Raised when a row in the model steps
#'     file has an empty \code{filePath}.
#'   \item \code{file_not_added}: Raised indirectly via the step functions if
#'     a file was not successfully added to the model cache; should not occur
#'     in normal use.
#'   \item \code{error}: Any other error occurred that is not classified in
#'     the above errors.
#' }
#'
#' @examples
#' \dontrun{
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' }
#'
#' @seealso \code{\link{run_model_pipeline}} to execute the pipeline.
#' @export
prepare_model_pipeline <- function(
  model_export,
  sandbox_path = NULL
) {
  mod <- list()

  # Allow/disallow path traversals in .add_file
  mod$sandbox_path <- sandbox_path

  # Get the root dir from the model_export path
  mod$root_dir <- .expand_and_normalize_path(dirname(model_export))

  # Load and validate model export file
  mod <- .add_file(mod, model_export)
  mod$model_export <- .get_file(mod, model_export)
  .verify_columns(
    mod$model_export,
    c("fileType", "filePath"),
    "model export file",
    model_export
  )

  # Get the variables file from the model export
  variables_row <-
    mod$model_export[mod$model_export$fileType == "variables", ]
  if (nrow(variables_row) != 1) {
    stop(.make_error(
      error_class = "invalid_model_export",
      "Model export file must have exactly one row where ",
      "fileType equals \"variables\""
    ))
  }
  variables_file <- file.path(mod$root_dir, variables_row[["filePath"]])

  # Get the model-steps file from the model export
  model_steps_row <-
    mod$model_export[mod$model_export$fileType == "model-steps", ]
  if (nrow(model_steps_row) != 1) {
    stop(.make_error(
      error_class = "invalid_model_export",
      "Model export file must have exactly one row where ",
      "fileType equals \"model-steps\""
    ))
  }
  model_steps_file <- file.path(mod$root_dir, model_steps_row[["filePath"]])

  # Load and validate variables
  mod <- .add_file(mod, variables_file)
  mod$variables <- .get_file(mod, variables_file)
  .verify_columns(
    mod$variables,
    c("role", "variable"),
    "variables file",
    variables_file
  )

  # Load and validate model steps
  mod <- .add_file(mod, model_steps_file)
  mod$model_steps <- .get_file(mod, model_steps_file)
  .verify_columns(
    mod$model_steps,
    c("step", "filePath"),
    "model steps file",
    NULL
  )

  # Create a boolean filter to select rows where "Predictor" is found in the
  # role column
  # For each row:
  #   1) Split the role at commas
  #   2) Trim whitespace from each split value
  #   3) Make each value lowercase
  #   4) Find "predictor" within each row
  predictor_filt <- mod$variables$role |>
    lapply(function(x) .get_string_parts(x, split = ",")) |>
    lapply(stringr::str_to_lower) |>
    lapply(function(row_values) "predictor" %in% row_values) |>
    unlist()
  # Select the predictors
  mod$predictor_variables <- mod$variables[predictor_filt, "variable"]

  # Preload all files in the model steps
  for (i in seq_len(nrow(mod$model_steps))) {
    step <- mod$model_steps[i, ]

    file_path <- step$filePath
    if (is.null(file_path) || stringr::str_length(file_path) == 0) {
      stop(.make_error(
        error_class = "empty_step_file_path",
        "File path is empty for step #",
        i,
        ": ",
        step$step
      ))
    }
    file_path <- file.path(mod$root_dir, file_path)

    mod <- .add_file(mod, file_path)
  }

  mod
}

#' Run Model Pipeline
#'
#' Executes the transformation pipeline on input data and retrieve the output.
#' Applies each transformation step defined in the model steps file in
#' sequence, modifying the data accordingly.
#'
#' @param mod A model object created by \code{\link{prepare_model_pipeline}}.
#' @param x Either a file path (character) to a CSV file containing the
#'   input data, or a data frame. The data must contain all columns specified
#'   as predictors in the variables file.
#' @param mode A character string specifying what data to return. Can be one
#'   of:
#'   \itemize{
#'      \item "output": Only return the final output of the model. These are the
#'        values of all variables calculated in the final step found in the
#'        model steps file.
#'      \item "full": Return all data, which includes the input data, all
#'        intermediate variables, and the final output of the model.
#'   }
#'   Default is "output".
#'
#' @return A data frame containing the pipeline output (when `mode = "output"`)
#'   or all data including intermediate columns (when `mode = "full"`).
#'
#' @section Errors:
#' \itemize{
#'   \item \code{inaccessible_file}: Raised if a step specification file does
#'     not exist or, if `mod$sandbox_path` is set, is not a descendant of that
#'     directory.
#'   \item \code{invalid_file_format}: Raised if a step specification file
#'     cannot be parsed as a CSV.
#'   \item \code{missing_columns}: Raised when a step specification file is
#'     missing required columns.
#'   \item \code{missing_data_columns}: Raised when predictor variable columns
#'     listed in the variables file are absent from the input data.
#'   \item \code{empty_step_file_path}: Raised when a row in the model steps
#'     file has an empty \code{filePath}.
#'   \item \code{unknown_step}: Raised when a step name in the model steps file
#'     is not a recognized transformation type.
#'   \item \code{invalid_mode}: Raised when the \code{mode} argument is not one
#'     of \code{"output"} or \code{"full"}.
#'   \item \code{file_not_added}: Raised indirectly via the step functions if
#'     a file was not successfully added to the model cache; should not occur
#'     in normal use.
#'   \item \code{error}: Any other error occurred that is not classified in
#'     the above errors.
#' }
#'
#' @examples
#' \dontrun{
#' # Prepare and run pipeline
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' output <- run_model_pipeline(mod, x = "path/to/input-data.csv")
#' head(output)
#'
#' # Run on data frame
#' input_data <- read.csv("path/to/data.csv")
#' mod <- run_model_pipeline(mod, x = input_data)
#' }
#'
#' @seealso \code{\link{prepare_model_pipeline}} to prepare the model object
#' @export
run_model_pipeline <- function(mod, x, mode = "output") {
  # Load data if it is a file
  if (is.character(x)) {
    x <- .expand_and_normalize_path(x)
    x <- utils::read.csv(x)
  }

  # Stop if there are predictors that do not exist in the data
  missing_variable_columns <-
    mod$predictor_variables[!(mod$predictor_variables %in% colnames(x))]
  if (length(missing_variable_columns)) {
    missing_variable_columns <- paste0("'", missing_variable_columns, "'",
      collapse = ", "
    )
    stop(.make_error(
      error_class = "missing_data_columns",
      "The following columns specified in the",
      " variables file are missing in the data: ",
      missing_variable_columns
    ))
  }
  mod$data <- x[mod$predictor_variables]

  # We will store information from each step as a named list in mod$steps_info,
  # for example:
  # nolint start
  #   mod$steps_info <- list(
  #     list(
  #       step_name = "rcs",
  #       output_columns = c("clc_age_rcs_1", "clc_age_rcs_2", "clc_age_rcs_3")
  #     ),
  #     list(...)
  #   )
  # }
  # nolint end
  mod$steps_info <- list()

  # Run each step in the model steps file
  for (i in seq_len(nrow(mod$model_steps))) {
    step <- mod$model_steps[i, ]
    step_name <- step$step

    file_path <- step$filePath
    if (is.null(file_path) || stringr::str_length(file_path) == 0) {
      stop(.make_error(
        error_class = "empty_step_file_path",
        "File path is empty for step #",
        i,
        ": ",
        step_name
      ))
    }
    file_path <- file.path(mod$root_dir, file_path)

    # Call the appropriate step function
    # Keep the [add-step-here] tag in the comments, as it is referenced
    # in the documentation and allows contributors to easily find where
    # to add a call to their new step function.
    # [add-step-here]
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
      # Handle unknown step name
      stop(.make_error(
        error_class = "unknown_step",
        "Unrecognized or unimplemented step type for step #",
        i,
        ": ",
        step_name
      ))
    }

    mod <- res$mod

    # Save the step info
    mod$steps_info[[length(mod$steps_info) + 1]] <- list(
      step_name = step_name,
      output_columns = res$output_columns
    )
  }

  if (mode == "output") {
    output_columns <- mod$steps_info[[length(mod$steps_info)]]$output_columns
    mod$data[output_columns]
  } else if (mode == "full") {
    mod$data
  } else {
    stop(.make_error(
      error_class = "invalid_mode",
      "Unrecognized value for \"mode\" in run_model_pipeline. ",
      "Must be one of \"output\" or \"full\", instead found \"",
      mode,
      "\""
    ))
  }
}
