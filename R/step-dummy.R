#' Run Dummy Coding Step
#'
#' Creates dummy variables for categorical values, setting 1 when the
#' original variable equals the specified category value, 0 otherwise.
#' Implements the 'dummy' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object
#' @param dat Data frame containing the input data to be transformed
#' @param file Path to dummy step specification file
#' @return A list containing: \code{mod} (the updated model object),
#'   \code{data} (the transformed data frame with dummy variables added),
#'   and \code{output_columns} (character vector of new column names added
#'   by this step)
#' @keywords internal
.run_step_dummy <- function(mod, dat, file) {
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)
  .verify_columns(
    step_data,
    c("origVariable", "catValue", "dummyVariable"),
    "dummy step file",
    file
  )

  output_columns <- c()
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    orig_variable <- info[["origVariable"]]
    cat_value <- info[["catValue"]]
    dummy_variable <- info[["dummyVariable"]]

    dat[dummy_variable] <- as.integer(dat[orig_variable] == cat_value)
    output_columns <- c(output_columns, dummy_variable)
  }

  list(
    mod = mod,
    data = dat,
    output_columns = output_columns
  )
}
