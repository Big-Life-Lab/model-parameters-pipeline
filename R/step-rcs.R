#' Run Restricted Cubic Spline Step
#'
#' Creates restricted cubic spline (RCS) transformations using
#' specified knot positions. Implements the 'rcs' transformation step
#' from the Model Parameters pipeline.
#'
#' @param mod Model object containing input data in \code{mod$data}
#' @param file Path to RCS step specification file
#' @return A list containing: \code{mod} (the updated model object with
#'   RCS variables added to \code{mod$data}), and \code{output_columns}
#'   (character vector of output columns of this step)
#'
#' @section Errors:
#' \itemize{
#'   \item \code{missing_variable}: Raised when a variable specified in the
#'     step file does not exist in \code{mod$data}.
#'   \item \code{rcs_variable_count_mismatch}: Raised when the number of
#'     \code{rcsVariables} for a row does not equal the number of knots minus
#'     one (the number of restricted cubic spline basis terms).
#'   \item \code{non_numeric_knots}: Raised when one or more \code{knots} for a
#'     row cannot be parsed as a number.
#'   \item \code{insufficient_knots}: Raised (via \code{\link{.get_rcs}}) when
#'     fewer than 3 knots are provided for a row.
#' }
#'
#' @keywords internal
.run_step_rcs <- function(mod, file) {
  # Load the step specification file
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)

  # Verify required columns exist in the specification file
  .verify_columns(
    step_data,
    c("variable", "rcsVariables", "knots"),
    "rcs step file",
    file
  )

  # Track which columns are produced by this step
  output_columns <- c()

  # Process each row in the step specification
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    variable <- info[["variable"]]
    rcs_variables <- .get_string_parts(info[["rcsVariables"]])
    knots <- suppressWarnings(as.double(.get_string_parts(info[["knots"]])))

    # Make sure all knots parsed to numbers. as.double() turns a non-numeric
    # value into NA, which would otherwise silently propagate to NaN outputs.
    if (any(is.na(knots))) {
      stop(.make_error(
        error_class = "non_numeric_knots",
        "The knots for variable \"",
        variable,
        "\" in the rcs step in ",
        basename(file),
        " must all be numeric: ",
        info[["knots"]]
      ))
    }

    # Make sure the variable exists in the data
    if (!variable %in% colnames(mod$data)) {
      stop(.make_error(
        error_class = "missing_variable",
        "RCS variable \"",
        variable,
        "\" does not exist in data when performing rcs step in ",
        basename(file)
      ))
    }

    # The number of RCS output columns must equal the number of spline basis
    # terms, which is (number of knots - 1). We only check this once there are
    # enough knots; .get_rcs raises insufficient_knots for fewer than 3.
    if (length(knots) >= 3 && length(rcs_variables) != length(knots) - 1) {
      stop(.make_error(
        error_class = "rcs_variable_count_mismatch",
        "The rcs step in ",
        basename(file),
        " specifies ",
        length(rcs_variables),
        " rcsVariables for variable \"",
        variable,
        "\" but ",
        length(knots),
        " knots require ",
        length(knots) - 1,
        " rcsVariables."
      ))
    }

    # Calculate and create the new RCS variable
    vals <- .get_rcs(mod$data[[variable]], knots)
    mod$data[rcs_variables] <- vals
    output_columns <- c(output_columns, rcs_variables)
  }

  # Return the updated model object and output column names
  list(
    mod = mod,
    output_columns = output_columns
  )
}

#' Calculate restricted cubic spline basis functions
#'
#' Computes restricted cubic spline (RCS) basis functions for a given vector
#' and knot positions. This implementation follows the algorithm from
#' Hmisc::rcspline.eval.
#'
#' @param x Numeric vector of values to transform
#' @param knots Numeric vector of knot positions
#' @return Matrix with RCS basis functions as columns
#'
#' @section Errors:
#' \itemize{
#'   \item \code{insufficient_knots}: Raised when fewer than 3 knots are
#'     provided; at least 3 are required for RCS calculations.
#' }
#'
#' @keywords internal
.get_rcs <- function(x, knots) {
  k <- length(knots)
  if (k < 3) {
    stop(.make_error(
      error_class = "insufficient_knots",
      "At least 3 knots are required for an RCS step, instead ",
      k,
      " were given: ",
      paste0(knots, collapse = ", ")
    ))
  }

  res <- data.frame(rcs.1 = x)

  for (j in 1:(k - 2)) {
    kd <- (knots[k] - knots[1])^(2 / 3) # (knot_k-knot_1)^(2/3) # nolint

    vec1 <- x - knots[j] # X-knot_j

    val2 <- knots[k - 1] - knots[j] # knot_{k-1}-knot_j
    vec2 <- x - knots[k] # X-knot_k

    val3 <- knots[k] - knots[j] # knot_k-knot_j
    vec3 <- x - knots[k - 1] # X-knot_{k-1}
    val4 <- knots[k] - knots[k - 1] # knot_k-knot_{k-1}

    # View(Hmisc::rcspline.eval): line 111-114
    # vec_j <- pmax((x - knots[j])/kd, 0)^3 +
    #   ((knots[k-1] - knots[j]) * pmax((x - knots[k])/kd, 0)^3 -
    #      (knots[k] - knots[j]) * (pmax((x - knots[k-1])/kd, 0)^power))/(knots[k] - knots[k-1]) # nolint

    vec_j <- pmax(vec1 / kd, 0)^3 +
      (val2 * pmax(vec2 / kd, 0)^3) / val4 -
      (val3 * pmax(vec3 / kd, 0)^3) / val4

    res[paste0("rcs.", j + 1)] <- vec_j
  }
  res <- as.matrix(res)

  res
}
