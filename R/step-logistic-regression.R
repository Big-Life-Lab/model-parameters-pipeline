#' Run Logistic Regression Step
#'
#' Applies logistic regression by multiplying variables by
#' coefficients, summing, and applying the logistic function
#' (1 / (1 + exp(-x))). Implements the 'logistic' transformation step
#' from the Model Parameters pipeline.
#'
#' @param mod Model object
#' @param file Path to logistic step specification file
#' @return Updated model object with logistic prediction added to data
#' @keywords internal
.run_step_logistic_regression <- function(mod, file) {
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)
  .verify_columns(
    step_data,
    c("variable", "coefficient"),
    "logistic step file",
    file
  )

  # Create the initial logistic output (initialize to 0)
  logistic_col <- .get_unused_column(mod$data, "logistic_")
  logistic_data <- data.frame(rep(0, nrow(mod$data)))
  colnames(logistic_data) <- c(logistic_col)
  logistic_data[logistic_col] <- 0

  # Multiply all variables by all coefficients
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    variable <- info[["variable"]]
    coefficient <- info[["coefficient"]]

    if (variable == "Intercept") {
      logistic_data[logistic_col] <- logistic_data[logistic_col] + coefficient
    } else {
      logistic_data[logistic_col] <- logistic_data[logistic_col] +
        mod$data[variable] * coefficient
    }
  }

  # Apply the logistic function to the output
  logistic_data[logistic_col] <- 1 / (1 + exp(-logistic_data[logistic_col]))

  mod$output_columns <- c(logistic_col)

  mod$data <- cbind(mod$data, logistic_data)

  mod
}
