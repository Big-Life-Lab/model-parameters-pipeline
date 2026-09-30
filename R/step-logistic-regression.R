#' Run Logistic Regression Step
#'
#' Applies logistic regression by multiplying variables by
#' coefficients, summing, and applying the logistic function
#' (1 / (1 + exp(-x))). Implements the 'logistic-regression' transformation
#' step from the Model Parameters pipeline.
#'
#' @param mod Model object containing input data in \code{mod$data}
#' @param file Path to logistic step specification file
#' @return A list containing: \code{mod} (the updated model object with the
#'   logistic prediction column added to \code{mod$data}), and
#'   \code{output_columns} (character vector of output columns of this step)
#'
#' @section Errors:
#' \itemize{
#'   \item \code{missing_variable}: Raised when a non-intercept variable
#'     specified in the step file does not exist in \code{mod$data}.
#'   \item \code{non_numeric_coefficient}: Raised when a \code{coefficient} in
#'     the step file cannot be parsed as a number.
#' }
#'
#' @keywords internal
.run_step_logistic_regression <- function(mod, file) {
  # Load the step specification file
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)

  # Verify required columns exist in the specification file
  .verify_columns(
    step_data,
    c("variable", "coefficient"),
    "logistic step file",
    file
  )

  # Create the initial logistic output (initialize to 0)
  logistic_col <- .get_unused_column(colnames(mod$data), "logistic")
  logistic_data <- data.frame(rep(0, nrow(mod$data)))
  colnames(logistic_data) <- c(logistic_col)

  # Process each row in the step specification
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    variable <- info[["variable"]]
    coefficient <- suppressWarnings(as.double(info[["coefficient"]]))

    # Make sure the coefficient parsed to a number
    if (is.na(coefficient)) {
      stop(.make_error(
        error_class = "non_numeric_coefficient",
        "The coefficient for variable \"",
        variable,
        "\" in the logistic-regression step in ",
        basename(file),
        " must be numeric: ",
        info[["coefficient"]]
      ))
    }

    if (variable == "Intercept") {
      # Intercepts get added to the output
      logistic_data[logistic_col] <- logistic_data[logistic_col] + coefficient
    } else {
      # Make sure variable exists in data
      if (!variable %in% colnames(mod$data)) {
        stop(.make_error(
          error_class = "missing_variable",
          "Variable \"",
          variable,
          "\" does not exist in data when performing ",
          "logistic-regression step in ",
          basename(file)
        ))
      }

      # Coefficients get multiplied by the variable then added to the output
      logistic_data[logistic_col] <- logistic_data[logistic_col] +
        mod$data[variable] * coefficient
    }
  }

  # Apply the logistic function to the output
  logistic_data[logistic_col] <- 1 / (1 + exp(-logistic_data[logistic_col]))

  output_columns <- c(logistic_col)

  # Add the new logistic_data column to mod$data
  mod$data <- cbind(mod$data, logistic_data)

  # Return the updated model object and output column names
  list(
    mod = mod,
    output_columns = output_columns
  )
}
