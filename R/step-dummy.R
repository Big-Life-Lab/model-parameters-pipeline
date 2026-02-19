#' Run Dummy Coding Step
#'
#' Creates dummy variables for categorical values, setting 1 when the
#' original variable equals the specified category value, 0 otherwise.
#' Implements the 'dummy' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object
#' @param file Path to dummy step specification file
#' @return Updated model object with dummy variables added to data
#' @keywords internal
.run_step_dummy <- function(mod, file) {
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)
  .verify_columns(
    step_data,
    c("origVariable", "catValue", "dummyVariable"),
    "dummy step file",
    file
  )

  mod$output_columns <- c()
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    orig_variable <- info[["origVariable"]]
    cat_value <- info[["catValue"]]
    dummy_variable <- info[["dummyVariable"]]

    mod$data[dummy_variable] <- as.integer(mod$data[orig_variable] == cat_value)
    mod$output_columns <- c(mod$output_columns, dummy_variable)
  }

  mod
}
