#' Run Restricted Cubic Spline Step
#'
#' Creates restricted cubic spline (RCS) transformations using
#' specified knot positions. Implements the 'rcs' transformation step
#' from the Model Parameters pipeline.
#'
#' @param mod Model object
#' @param dat Data frame containing the input data to be transformed
#' @param file Path to RCS step specification file
#' @return A list containing: \code{mod} (the updated model object),
#'   \code{data} (the transformed data frame with RCS variables added),
#'   and \code{output_columns} (character vector of new column names added
#'   by this step)
#' @keywords internal
.run_step_rcs <- function(mod, dat, file) {
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)
  .verify_columns(
    step_data,
    c("variable", "rcsVariables", "knots"),
    "rcs step file",
    file
  )

  output_columns <- c()
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    variable <- info[["variable"]]
    rcs_variables <- .get_string_parts(info[["rcsVariables"]])
    knots <- as.double(.get_string_parts(info[["knots"]]))

    vals <- .get_rcs(dat[[variable]], knots)
    dat[rcs_variables] <- vals
    output_columns <- c(output_columns, rcs_variables)
  }

  list(
    mod = mod,
    data = dat,
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
#' @keywords internal
.get_rcs <- function(x, knots) {
  k <- length(knots)
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
