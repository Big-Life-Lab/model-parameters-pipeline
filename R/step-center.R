#' Run Center Step
#'
#' Centers variables by subtracting a specified center value from original
#' variables. Implements the 'center' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object
#' @param dat Data frame containing the input data to be transformed
#' @param file Path to center step specification file
#' @return A list containing: \code{mod} (the updated model object),
#'   \code{data} (the transformed data frame with centered variables added),
#'   and \code{output_columns} (character vector of new column names added
#'   by this step)
#' @keywords internal
.run_step_center <- function(mod, dat, file) {
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

    dat[centered_variable] <- dat[orig_variable] - center_value
    output_columns <- c(output_columns, centered_variable)
  }

  list(
    mod = mod,
    data = dat,
    output_columns = output_columns
  )
}
