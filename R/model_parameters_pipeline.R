#' Model Parameters Pipeline
#'
#' This module provides functions to prepare and run a model parameters
#' pipeline for applying sequential data transformations as defined by the
#' Model Parameters specification developed by Big Life Lab.
#'
#' @section Workflow:
#' The typical workflow involves three steps:
#' \enumerate{
#'   \item \code{prepare_model_pipeline()}: Load and validate model
#'     configuration
#'   \item \code{run_model_pipeline()}: Apply transformations to data
#'   \item \code{get_pipeline_output()}: Retrieve the output of the
#'     model pipeline. The output is the results of the last
#'     transformation step. Depending on the step, this may include
#'     multiple columns.
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
#' mod <- run_model_pipeline(mod, dat = "path/to/input-data.csv")
#' result <- get_pipeline_output(mod, mode = "output")
#'
#' # Processing multiple datasets with the same model
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' for (data_file in data_files) {
#'   mod <- run_model_pipeline(mod, dat = data_file)
#'   result <- get_pipeline_output(mod, mode = "output")
#'   # Process result (a data frame)
#' }
#'
#' # Pass a data frame to run_model_pipeline
#' input_data <- read.csv("path/to/input-data.csv")
#' mod <- run_model_pipeline(mod, dat = input_data)
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
#'   \code{\link{run_model_pipeline}} and \code{\link{get_pipeline_output}}.
#'
#' @examples
#' \dontrun{
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' }
#'
#' @seealso \code{\link{run_model_pipeline}} to execute the pipeline and
#'   \code{\link{get_pipeline_output}} to retrieve the output of the pipeline.
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

  # Get the variables and model_steps files from the model export
  variables_file <-
    mod$model_export[mod$model_export$fileType == "variables", ][["filePath"]]
  variables_file <- file.path(mod$root_dir, variables_file)
  model_steps_file <-
    mod$model_export[mod$model_export$fileType == "model-steps", ][["filePath"]]
  model_steps_file <- file.path(mod$root_dir, model_steps_file)

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

  # Get predictors variables
  mod$predictor_variables <- mod$variables[
    mod$variables$role == "Predictor", "variable"
  ]

  # Preload all files in the model steps
  for (i in seq_len(nrow(mod$model_steps))) {
    step <- mod$model_steps[i, ]

    file_path <- step$filePath
    if (is.null(file_path) || stringr::str_length(file_path) == 0) {
      next
    }
    file_path <- file.path(mod$root_dir, file_path)

    mod <- .add_file(mod, file_path)
  }

  mod
}

#' Run Model Pipeline
#'
#' Executes the transformation pipeline on input data. Applies each
#' transformation step defined in the model steps file in sequence,
#' modifying the data accordingly.
#'
#' @param mod A model object created by \code{\link{prepare_model_pipeline}}.
#' @param dat Either a file path (character) to a CSV file containing the
#'   input data, or a data frame. The data must contain all columns specified
#'   as predictors in the variables file.
#'
#' @return A model object (list) with all transformation results stored in
#'   \code{mod$data}. Pass the returned object to
#'   \code{\link{get_pipeline_output}} to extract a data frame.
#'
#' @examples
#' \dontrun{
#' # Prepare and run pipeline
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' mod <- run_model_pipeline(mod, dat = "path/to/input-data.csv")
#'
#' # Extract final output columns as a data frame
#' output <- get_pipeline_output(mod, mode = "output")
#' head(output)
#'
#' # Get all columns including intermediate transformation variables
#' output_full <- get_pipeline_output(mod, mode = "full")
#'
#' # Run on data frame
#' input_data <- read.csv("path/to/data.csv")
#' mod <- run_model_pipeline(mod, dat = input_data)
#' }
#'
#' @seealso \code{\link{prepare_model_pipeline}} to prepare the model object,
#'   \code{\link{get_pipeline_output}} to extract the output of the pipeline
#' @export
run_model_pipeline <- function(mod, dat) {
  # Load data if it is a file
  if (is.character(dat)) {
    dat <- normalizePath(dat, mustWork = TRUE)
    dat <- utils::read.csv(dat)
  }

  # Stop if there are predictors that do not exist in the data
  missing_variable_columns <-
    mod$predictor_variables[!(mod$predictor_variables %in% colnames(dat))]
  if (length(missing_variable_columns)) {
    missing_variable_columns <- paste0("'", missing_variable_columns, "'",
      collapse = ", "
    )
    stop(
      paste(
        "The following columns specified in the",
        "variables file are missing in the data:",
        missing_variable_columns
      )
    )
  }
  mod$data <- dat[mod$predictor_variables]

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
      stop(paste0(
        "File path is empty for step #",
        i,
        ": ",
        step_name
      ))
    }
    file_path <- file.path(mod$root_dir, file_path)

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

    mod <- res$mod

    # Save the step info
    mod$steps_info[[length(mod$steps_info) + 1]] <- list(
      step_name = step_name,
      output_columns = res$output_columns
    )
  }

  # Rename the output columns to "output"/"output_#"
  # If we decide we want to rename the output columns, then the code below
  # will do that. If we only want to rename the output columns when
  # get_pipeline_output is called with mode = "output", then we can
  # move this code to get_pipeline_output
  # nolint start
  # res <- .rename_columns(
  #   mod$data,
  #   mod$steps_info[[length(mod$steps_info)]]$output_columns,
  #   prefix = "output",
  #   suffix = "_#"
  # )
  # mod$data <- res$dat
  # mod$steps_info[[length(mod$steps_info)]]$output_columns <-
  #   res$new_column_names
  # nolint end

  mod
}

#' Get Model Output
#'
#' Extracts a data frame from the model object returned by
#' \code{\link{run_model_pipeline}}. If multiple calls to
#' \code{\link{run_model_pipeline}} have been made then only the results
#' of the last call will be returned.
#'
#' @param mod A model object returned by \code{\link{run_model_pipeline}}.
#' @param mode A character string specifying what data to return. Can be one
#'   of:
#'      "output": Only return the final output of the model. These are the
#'        values of all variables calculated in the final step found in the
#'        model export file.
#'      "full": Return all data, which includes the input data, all intermediate
#'        variables, and the final output of the model.
#'   Default is "output".
#'
#' @return A data frame containing the transformed data. Its contents depend
#'   on \code{mode}:
#' \itemize{
#'   \item \code{"output"}: Only the output columns produced by the final
#'     transformation step (e.g., the logistic prediction column when the
#'     last step is logistic-regression)
#'   \item \code{"full"}: All columns — the original predictor columns plus
#'     every new column created by each transformation step (centered
#'     variables, dummy variables, interaction terms, spline terms, etc.)
#' }
#'
#' @examples
#' \dontrun{
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' mod <- run_model_pipeline(mod, dat = "path/to/input-data.csv")
#'
#' # Default: only the final step's output columns
#' output <- get_pipeline_output(mod)
#'
#' # Full: all columns including intermediate transformation variables
#' output_full <- get_pipeline_output(mod, mode = "full")
#' }
#'
#' @seealso \code{\link{run_model_pipeline}} to run the pipeline
#' @export
get_pipeline_output <- function(mod, mode = "output") {
  if (mode == "output") {
    output_columns <- mod$steps_info[[length(mod$steps_info)]]$output_columns
    mod$data[output_columns]
  } else if (mode == "full") {
    mod$data
  } else {
    stop(paste0(
      "Unrecognized value for \"mode\" in get_pipeline_output. ",
      "Must be one of \"output\" or \"full\", instead found \"",
      mode,
      "\""
    ))
  }
}
