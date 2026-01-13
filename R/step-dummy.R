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
  step_df <- .get_file(mod, file)
  .verify_columns(
    step_df,
    c("origVariable", "catValue", "dummyVariable"),
    "dummy step file",
    file
  )

  for (i in seq_len(nrow(step_df))) {
    info <- step_df[i, ]
    orig_variable <- info[["origVariable"]]
    cat_value <- info[["catValue"]]
    dummy_variable <- info[["dummyVariable"]]

    mod$df[dummy_variable] <- as.integer(mod$df[orig_variable] == cat_value)
  }

  mod
}
