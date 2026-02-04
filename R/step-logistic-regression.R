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
  step_df <- .get_file(mod, file)
  .verify_columns(
    step_df,
    c("variable", "coefficient"),
    "logistic step file",
    file
  )

  # Create the initial logistic output (initialize to 0)
  logistic_col <- .get_unused_column(mod$df, "logistic_")
  logistic_df <- data.frame(rep(0, nrow(mod$df)))
  colnames(logistic_df) <- c(logistic_col)
  logistic_df[logistic_col] <- 0

  # Multiple all variables by all coefficients
  for (i in seq_len(nrow(step_df))) {
    info <- step_df[i, ]
    variable <- info[["variable"]]
    coefficient <- info[["coefficient"]]

    if (variable == "Intercept") {
      logistic_df[logistic_col] <- logistic_df[logistic_col] + coefficient
    } else {
      logistic_df[logistic_col] <- logistic_df[logistic_col] +
        mod$df[variable] * coefficient
    }
  }

  # Apply the logistic function to the output
  logistic_df[logistic_col] <- 1 / (1 + exp(-logistic_df[logistic_col]))

  mod$df <- cbind(mod$df, logistic_df)

  mod
}
