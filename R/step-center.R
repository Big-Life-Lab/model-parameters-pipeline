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
  step_data <- .get_file(mod, file)
  .verify_columns(
    step_data,
    c("origVariable", "centerValue", "centeredVariable"),
    "center step file",
    file
  )

  mod$output_columns <- c()
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    orig_variable <- info[["origVariable"]]
    center_value <- info[["centerValue"]]
    centered_variable <- info[["centeredVariable"]]

    mod$data[centered_variable] <- mod$data[orig_variable] - center_value
    mod$output_columns <- c(mod$output_columns, centered_variable)
  }

  mod
}
