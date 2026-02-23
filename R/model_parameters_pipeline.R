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
#' }
#'
#' @section Required Files:
#' The pipeline requires the following CSV files:
#' \describe{
#'   \item{Model Export}{Points to variables and model-steps files
#'     (columns: fileType, filePath)}
#'   \item{Variables}{Lists predictor variables (columns: variable, role)}
#'   \item{Model Steps}{Defines transformation sequence
#'     (columns: step, filePath)}
#'   \item{Step Parameter Files}{Define parameters for each transformation step}
#' }
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' result <- run_model_pipeline(mod, dat = "path/to/input-data.csv")
#'
#' # Processing multiple datasets with the same model
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' for (data_file in data_files) {
#'   result <- run_model_pipeline(mod, dat = data_file)
#'   # Process result (a data frame)
#' }
#'
#' # Pass a data frame to run_model_pipeline
#' input_data <- read.csv("path/to/input-data.csv")
#' result <- run_model_pipeline(mod, dat = input_data)
#'
#' # Extract logistic predictions (if model includes logistic-regression step)
#' # Use "full" mode to access all columns including intermediate variables
#' result_full <- run_model_pipeline(mod, dat = input_data, mode = "full")
#' predictions <- result_full[, grep("^logistic_", names(result_full))]
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
#'
#' @return A model object (list) containing:
#' \describe{
#'   \item{root_dir}{The root directory used for resolving file paths
#'     (derived from the model export file location)}
#'   \item{model_export}{The data from the model export file}
#'   \item{variables}{The data from the variables file}
#'   \item{model_steps}{The data from the model steps file}
#'   \item{predictor_variables}{Character vector of predictor variable names}
#'   \item{files}{Named list of cached file contents}
#' }
#'
#' @examples
#' \dontrun{
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' }
#'
#' @seealso \code{\link{run_model_pipeline}} to execute the pipeline
#' @export
prepare_model_pipeline <- function(model_export) {
  mod <- list()

  # Get the root dir from the model_export path
  mod$root_dir <- normalizePath(dirname(model_export))

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
#' # Prepare and run pipeline (returns a data frame)
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' result <- run_model_pipeline(mod, dat = "path/to/input-data.csv")
#'
#' # Access results
#' head(result)
#'
#' # Get all columns including intermediate transformation variables
#' result_full <- run_model_pipeline(mod, dat = "path/to/input-data.csv",
#'   mode = "full")
#'
#' # Extract predictions from logistic-regression step
#' predictions <- result_full[, grep("^logistic_", names(result_full))]
#'
#' # Run on data frame
#' input_data <- read.csv("path/to/data.csv")
#' result <- run_model_pipeline(mod, dat = input_data)
#' }
#'
#' @seealso \code{\link{prepare_model_pipeline}} to prepare the model object
#' @export
run_model_pipeline <- function(mod, dat, mode = "output") {
  # Load data if it is a file
  if (is.character(dat)) {
    mod <- .add_file(mod, dat)
    dat <- .get_file(mod, dat)
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
  dat <- dat[unlist(mod$predictor_variables)]

  output_columns <- c()

  for (i in seq_len(nrow(mod$model_steps))) {
    step <- mod$model_steps[i, ]
    step_name <- step$step

    file_path <- step$filePath
    if (is.null(file_path) || stringr::str_length(file_path) == 0) {
    }
    file_path <- file.path(mod$root_dir, file_path)

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

    mod <- res$mod
    dat <- res$data
    output_columns <- res$output_columns
  }

  if (mode == "output") {
    dat[output_columns]
  } else if (mode == "full") {
    dat
  } else {
    stop(paste0(
      "Unrecognized value for \"mode\" in run_model_pipeline. ",
      "Must be one of \"output\" or \"full\", instead found \"",
      mode,
      "\""
    ))
  }
}
