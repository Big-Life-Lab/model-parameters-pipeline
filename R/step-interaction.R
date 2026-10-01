#' Run Interaction Step
#'
#' Creates interaction terms by multiplying specified variables together.
#' Implements the 'interaction' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object containing input data in \code{mod$data}
#' @param file Path to interaction step specification file
#' @return A list containing: \code{mod} (the updated model object with
#'   interaction variables added to \code{mod$data}), and \code{output_columns}
#'   (character vector of output columns of this step)
#'
#' @section Errors:
#' \itemize{
#'   \item \code{missing_variable}: Raised when a variable listed in
#'     \code{interactingVariables} does not exist in \code{mod$data}.
#' }
#'
#' @keywords internal
.run_step_interaction <- function(mod, file) {
  # Load the step specification file
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)

  # Verify required columns exist in the specification file
  .verify_columns(
    step_data,
    c("interactingVariables", "interactionVariable"),
    "interaction step file",
    file
  )

  # Track which columns are produced by this step
  output_columns <- character(nrow(step_data))

  # Process each row in the step specification
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    interacting_variables <- .get_string_parts(info[["interactingVariables"]])
    interaction_variable <- info[["interactionVariable"]]

    # Accumulate the product in a plain vector so each multiplication runs on
    # vectors (not the slower Ops.data.frame) and the data frame is written
    # only once, after the loop.
    product <- rep(1, nrow(mod$data))
    for (interacting_variable in interacting_variables) {
      # Make sure the interacting variable exists
      if (!interacting_variable %in% colnames(mod$data)) {
        stop(.make_error(
          error_class = "missing_variable",
          "Interacting variable \"",
          interacting_variable,
          "\" does not exist in data when performing interaction step in ",
          basename(file)
        ))
      }

      product <- product * mod$data[[interacting_variable]]
    }
    mod$data[[interaction_variable]] <- product
    output_columns[i] <- interaction_variable
  }

  # Return the updated model object and output column names
  list(
    mod = mod,
    output_columns = output_columns
  )
}
