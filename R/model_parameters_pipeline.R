#' @title Model Parameters Pipeline
#'
#' @description
#' This file implements a pipeline for applying model parameter
#' transformations to data. The pipeline supports multiple
#' transformation steps including centering, dummy coding, interactions,
#' restricted cubic splines (RCS), and logistic regression, as defined
#' in the Model Parameters repository.
#'
#' Transformation step functions are defined in separate source files
#' in the R/ directory and are automatically loaded.
#'
#' @examples
#' \dontrun{
#' # Using a model export file that specifies all required files
#' mod <- run_model_pipeline(
#'   root_dir = "path/to/model/directory",
#'   data = "path/to/input-data.csv",
#'   model_export = "path/to/model-export.csv"
#' )
#'
#' # Using individual specification files
#' mod <- run_model_pipeline(
#'   root_dir = "path/to/model/directory",
#'   data = "path/to/input-data.csv",
#'   variables = "path/to/variables.csv",
#'   model_steps = "path/to/model-steps.csv"
#' )
#'
#' # Using data frames instead of file paths
#' mod <- run_model_pipeline(
#'   root_dir = "path/to/model/directory",
#'   data = data_df,
#'   model_export = model_export_df
#' )
#'
#' # Reusing an existing model object for better performance
#' mod <- run_model_pipeline(
#'   root_dir = "path/to/model/directory",
#'   data = new_data,
#'   model_export = "path/to/model-export.csv",
#'   existing_mod = mod
#' )
#'
#' # Access transformed data
#' transformed_data <- mod$df
#' }
#' @noRd
#' @name model_parameters_pipeline
NULL

library(stringr)

#' Run Model Parameters Pipeline
#'
#' Executes the complete model parameters transformation pipeline, applying
#' sequential steps (center, dummy, interaction, rcs, logistic) to input
#' data.
#'
#' @param root_dir Root directory for model parameter files. This is only
#'   used when loading the step files found in the model steps specification.
#'   The other parameters to this function must include the full path
#'   location (ie. data, model_export, variables, and model_steps)
#' @param data Input data (file path or data frame)
#' @param model_export Model export specification (file path or data frame)
#' @param variables Variables specification (file path or data frame)
#' @param model_steps Model steps specification (file path or data frame)
#' @param existing_mod Existing model object to reuse (for performance
#'   optimization)
#' @return Model object with transformed data in `$df` component
#' @export
run_model_pipeline <- function(root_dir = NULL,
                               data = NULL,
                               model_export = NULL,
                               variables = NULL,
                               model_steps = NULL,
                               existing_mod = NULL) {
  mod <- .prepare_pipeline(
    root_dir = root_dir,
    data = data,
    model_export = model_export,
    variables = variables,
    model_steps = model_steps,
    existing_mod = existing_mod
  )
  mod <- .run_pipeline_steps(mod)

  mod
}

#' Prepare Model Pipeline
#'
#' Internal function that initializes the model object, loads required files,
#' and prepares data by selecting predictor variables.
#'
#' @param root_dir Root directory for model parameter files
#' @param data Input data (file path or data frame)
#' @param model_export Model export specification (file path or data frame)
#' @param variables Variables specification (file path or data frame)
#' @param model_steps Model steps specification (file path or data frame)
#' @param existing_mod Existing model object to reuse
#' @return Initialized model object with data and model steps
#' @keywords internal
.prepare_pipeline <- function(root_dir,
                              data,
                              model_export,
                              variables = NULL,
                              model_steps = NULL,
                              existing_mod = NULL) {
  # These are the file names to load, if the parameters are not dataframes
  model_export_file <- if (is.character(model_export)) model_export
  variables_file <- if (is.character(variables)) variables
  model_steps_file <- if (is.character(model_steps)) model_steps

  root_dir <- normalizePath(root_dir)

  if (is.null(existing_mod)) {
    mod <- list(
      files = list() # File cache
    )
  } else {
    mod <- existing_mod
  }
  mod$root_dir <- root_dir

  # Load files if required
  if (is.character(model_export_file)) {
    mod <- .add_file(mod, model_export_file)
    model_export <- .get_file(mod, model_export_file)
  }
  if (is.character(data)) {
    mod <- .add_file(mod, data)
    data <- .get_file(mod, data)
  }
  if (is.character(variables_file)) {
    mod <- .add_file(mod, variables_file)
    variables <- .get_file(mod, variables_file)
  }
  if (is.character(model_steps_file)) {
    mod <- .add_file(mod, model_steps_file)
    model_steps <- .get_file(mod, model_steps_file)
  }

  # Load all data files specified in the model export file (ie. variables
  # and model_steps)
  if (!is.null(model_export)) {
    .verify_columns(
      model_export,
      c("fileType", "filePath"),
      "model export file",
      model_export_file
    )

    # Get the variables and model_steps paths
    variables_file <-
      model_export[model_export$fileType == "variables", ][["filePath"]]
    variables_file <- file.path(mod$root_dir, variables_file)
    model_steps_file <-
      model_export[model_export$fileType == "model-steps", ][["filePath"]]
    model_steps_file <- file.path(mod$root_dir, model_steps_file)

    # Load variables and model_steps
    mod <- .add_file(mod, variables_file)
    variables <- .get_file(mod, variables_file)
    mod <- .add_file(mod, model_steps_file)
    model_steps <- .get_file(mod, model_steps_file)
  }

  # Prepare the data by selecting only the Predictors
  .verify_columns(
    variables,
    c("role", "variable"),
    "variables file",
    variables_file
  )
  predictor_variables <- variables[variables$role == "Predictor", "variable"]

  # Stop if there are predictors that do not exist in the data
  missing_variable_columns <-
    predictor_variables[!(predictor_variables %in% colnames(data))]
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
  data <- data[unlist(predictor_variables)]

  mod$df <- data
  mod$model_steps <- model_steps

  mod
}

#' Run All Pipeline Steps
#'
#' Executes all transformation steps sequentially based on the
#' model_steps specification. Supports center, dummy, interaction, rcs,
#' and logistic steps. Each step is implemented by a corresponding
#' .run_step_[stepname] function defined in R/step-[stepname].R.
#' This should only be called after .prepare_pipeline is called.
#'
#' @param mod Model object containing data and model_steps
#' @return Updated model object with all transformations applied
#' @keywords internal
.run_pipeline_steps <- function(mod) {
  .verify_columns(
    mod$model_steps,
    c("step", "filePath"),
    "model steps file",
    NULL
  )

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
  }

  mod
}
