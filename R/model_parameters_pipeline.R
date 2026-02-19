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
#' mod <- run_model_pipeline(mod, data = "path/to/input-data.csv")
#'
#' # Access transformed data
#' transformed_data <- mod$data
#'
#' # Processing multiple datasets with the same model
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' for (data_file in data_files) {
#'   result <- run_model_pipeline(mod, data = data_file)
#'   # Process result$data
#' }
#'
#' # Pass a data frame to run_model_pipeline
#' input_data <- read.csv("path/to/input-data.csv")
#' mod <- run_model_pipeline(mod, data = input_data)
#'
#' # Extract logistic predictions (if model includes logistic-regression step)
#' predictions <- mod$data[, grep("^logistic_", names(mod$data))]
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
#' @param data Either a file path (character) to a CSV file containing the
#'   input data, or a data frame. The data must contain all columns specified
#'   as predictors in the variables file.
#'
#' @return The model object with the transformed data added. The transformed
#'   data is accessible via \code{mod$data}. This data contains:
#' \itemize{
#'   \item Original predictor columns from the input data
#'   \item New columns created by each transformation step (e.g., centered
#'     variables, dummy variables, interaction terms, spline terms)
#'   \item If a logistic-regression step is included, a column named
#'     \code{logistic_N} (where N is a positive integer) containing the
#'     predicted probabilities
#' }
#'
#' @examples
#' \dontrun{
#' # Prepare and run pipeline
#' mod <- prepare_model_pipeline("path/to/model-export.csv")
#' mod <- run_model_pipeline(mod, data = "path/to/input-data.csv")
#'
#' # Access results
#' head(mod$data)
#'
#' # Extract predictions from logistic-regression step
#' predictions <- mod$data[, grep("^logistic_", names(mod$data))]
#'
#' # Run on data frame
#' input_data <- read.csv("path/to/data.csv")
#' mod <- run_model_pipeline(mod, data = input_data)
#' }
#'
#' @seealso \code{\link{prepare_model_pipeline}} to prepare the model object
#' @export
run_model_pipeline <- function(mod, data) {
  # Load data if it is a file
  if (is.character(data)) {
    mod <- .add_file(mod, data)
    data <- .get_file(mod, data)
  }

  # Stop if there are predictors that do not exist in the data
  missing_variable_columns <-
    mod$predictor_variables[!(mod$predictor_variables %in% colnames(data))]
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
  data <- data[unlist(mod$predictor_variables)]

  # Each step will modify the data at mod$data
  mod$data <- data

  for (i in seq_len(nrow(mod$model_steps))) {
    step <- mod$model_steps[i, ]
    step_name <- step$step

    file_path <- step$filePath
    if (is.null(file_path) || stringr::str_length(file_path) == 0) {
      next
    }
    file_path <- file.path(mod$root_dir, file_path)

    if (step_name == "center") {
      mod <- .run_step_center(mod, file_path)
    } else if (step_name == "dummy") {
      mod <- .run_step_dummy(mod, file_path)
    } else if (step_name == "interaction") {
      mod <- .run_step_interaction(mod, file_path)
    } else if (step_name == "logistic-regression") {
      mod <- .run_step_logistic_regression(mod, file_path)
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
  }

  mod
}
