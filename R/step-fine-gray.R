#' Run Fine and Gray Step
#'
#' Applies Fine and Gray competing risk prediction by multiplying variables by
#' coefficients, summing to form a linear predictor, and applying the cumulative
#' incidence function: \code{F(t) = 1 - exp(-H0(t))^exp(LP)}, where
#' \code{H0(t)} is the baseline cumulative subdistribution hazard at the
#' prediction horizon. Implements the 'fine-and-gray' transformation step from
#' the Model Parameters pipeline.
#'
#' @param mod Model object containing input data in \code{mod$data}
#' @param file Path to Fine and Gray step specification file. The file must
#'   contain columns \code{variable} and \code{coefficient}. One row must have
#'   \code{variable} equal to \code{"baseline_cumulative_hazard"}, whose
#'   \code{coefficient} value is \code{H0(t)} at the prediction horizon.
#' @return A list containing: \code{mod} (the updated model object with the
#'   cumulative incidence column added to \code{mod$data}), and
#'   \code{output_columns} (character vector of output columns of this step)
#'
#' @section Errors:
#' \itemize{
#'   \item \code{missing_variable}: Raised when a variable specified in the
#'     step file does not exist in \code{mod$data}.
#'   \item \code{non_numeric_coefficient}: Raised when a \code{coefficient} in
#'     the step file cannot be parsed as a number.
#'   \item \code{missing_baseline_hazard}: Raised when no row with
#'     \code{variable == "baseline_cumulative_hazard"} is found in the step
#'     file.
#' }
#'
#' @keywords internal
.run_step_fine_gray <- function(mod, file) {
  # Load the step specification file
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)

  # Verify required columns exist in the specification file
  .verify_columns(
    step_data,
    c("variable", "coefficient"),
    "fine-and-gray step file",
    file
  )

  # Extract baseline cumulative hazard H0(t)
  h0_row <- step_data[step_data$variable == "baseline_cumulative_hazard", ]
  if (nrow(h0_row) == 0) {
    stop(.make_error(
      error_class = "missing_baseline_hazard",
      "The fine-and-gray step file must contain a row with ",
      "variable \"baseline_cumulative_hazard\" in ",
      basename(file)
    ))
  }
  h0 <- suppressWarnings(as.double(h0_row[["coefficient"]][1]))
  if (is.na(h0)) {
    stop(.make_error(
      error_class = "non_numeric_coefficient",
      "The baseline_cumulative_hazard value in the fine-and-gray step in ",
      basename(file),
      " must be numeric: ",
      h0_row[["coefficient"]][1]
    ))
  }

  # Determine the output column name and accumulate the linear predictor
  fg_col <- .get_unused_column(colnames(mod$data), "fine_gray")
  linear_predictor <- numeric(nrow(mod$data))

  # Process each coefficient row (skip baseline_cumulative_hazard)
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    variable <- info[["variable"]]

    # Skip the baseline hazard row
    if (variable == "baseline_cumulative_hazard") next

    coefficient <- suppressWarnings(as.double(info[["coefficient"]]))

    # Make sure the coefficient parsed to a number
    if (is.na(coefficient)) {
      stop(.make_error(
        error_class = "non_numeric_coefficient",
        "The coefficient for variable \"",
        variable,
        "\" in the fine-and-gray step in ",
        basename(file),
        " must be numeric: ",
        info[["coefficient"]]
      ))
    }

    if (variable == "Intercept") {
      linear_predictor <- linear_predictor + coefficient
    } else {
      # Make sure variable exists in data
      if (!variable %in% colnames(mod$data)) {
        stop(.make_error(
          error_class = "missing_variable",
          "Variable \"",
          variable,
          "\" does not exist in data when performing ",
          "fine-and-gray step in ",
          basename(file)
        ))
      }

      linear_predictor <- linear_predictor +
        mod$data[[variable]] * coefficient
    }
  }

  # Apply the Fine and Gray cumulative incidence function:
  # F(t) = 1 - exp(-H0(t))^exp(LP)
  #       = 1 - exp(-H0(t) * exp(LP))
  mod$data[[fg_col]] <- 1 - exp(-h0 * exp(linear_predictor))

  output_columns <- c(fg_col)

  # Return the updated model object and output column names
  list(
    mod = mod,
    output_columns = output_columns
  )
}
