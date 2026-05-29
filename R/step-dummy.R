#' Run Dummy Coding Step
#'
#' Creates dummy variables for categorical values, setting 1 when the
#' original variable equals the specified category value, 0 otherwise.
#' Implements the 'dummy' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object containing input data in \code{mod$data}
#' @param file Path to dummy step specification file
#' @return A list containing: \code{mod} (the updated model object with
#'   dummy variables added to \code{mod$data}), and \code{output_columns}
#'   (character vector of output columns of this step)
#'
#' @section Errors:
#' \itemize{
#'   \item \code{missing_variable}: Raised when a variable specified as
#'     \code{origVariable} in the step file does not exist in \code{mod$data}.
#' }
#'
#' @keywords internal
.run_step_dummy <- function(mod, file) {
  # Load the step specification file
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)

  # Verify required columns exist in the specification file
  .verify_columns(
    step_data,
    c("origVariable", "catValue", "dummyVariable"),
    "dummy step file",
    file
  )

  # Track which columns are produced by this step
  output_columns <- character(nrow(step_data))

  # Process each row in the step specification
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    orig_variable <- info[["origVariable"]]
    cat_value <- info[["catValue"]]
    dummy_variable <- info[["dummyVariable"]]

    # Make sure orig_variable exists in data
    if (!orig_variable %in% colnames(mod$data)) {
      stop(.make_error(
        error_class = "missing_variable",
        "Variable \"",
        orig_variable,
        "\" specified as origVariable does not exist in data ",
        "when performing dummy step in ",
        basename(file)
      ))
    }

    # Create the dummy variable. Index columns with [[ ]] so the comparison runs
    # on plain vectors rather than the much slower Ops.data.frame dispatch.
    mod$data[[dummy_variable]] <-
      as.integer(mod$data[[orig_variable]] == cat_value)
    output_columns[i] <- dummy_variable
  }

  # Return the updated model object and output column names
  list(
    mod = mod,
    output_columns = output_columns
  )
}
