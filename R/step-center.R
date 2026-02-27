#' Run Center Step
#'
#' Centers variables by subtracting a specified center value from original
#' variables. Implements the 'center' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object containing input data in \code{mod$data}
#' @param file Path to center step specification file
#' @return A list containing: \code{mod} (the updated model object with
#'   centered variables added to \code{mod$data}), and \code{output_columns}
#'   (character vector of output columns of this step)
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

  output_columns <- c()
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    orig_variable <- info[["origVariable"]]
    center_value <- info[["centerValue"]]
    centered_variable <- info[["centeredVariable"]]

    mod$data[centered_variable] <- mod$data[orig_variable] - center_value
    output_columns <- c(output_columns, centered_variable)
  }

  list(
    mod = mod,
    output_columns = output_columns
  )
}
