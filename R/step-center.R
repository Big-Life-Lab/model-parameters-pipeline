#' Run Center Step
#'
#' Centers variables by subtracting a specified center value from original
#' variables. Implements the 'center' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object
#' @param file Path to center step specification file
#' @return Updated model object with centered variables added to data
#' @keywords internal
.run_step_center <- function(mod, file) {
  mod <- .add_file(mod, file)
  step_df <- .get_file(mod, file)
  .verify_columns(
    step_df,
    c("origVariable", "centerValue", "centeredVariable"),
    "center step file",
    file
  )

  for (i in seq_len(nrow(step_df))) {
    info <- step_df[i, ]
    orig_variable <- info[["origVariable"]]
    center_value <- info[["centerValue"]]
    centered_variable <- info[["centeredVariable"]]

    mod$df[centered_variable] <- mod$df[orig_variable] - center_value
  }

  mod
}
