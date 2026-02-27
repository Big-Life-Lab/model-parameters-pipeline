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
#' @keywords internal
.run_step_interaction <- function(mod, file) {
  mod <- .add_file(mod, file)
  step_data <- .get_file(mod, file)
  .verify_columns(
    step_data,
    c("interactingVariables", "interactionVariable"),
    "interaction step file",
    file
  )

  output_columns <- c()
  for (i in seq_len(nrow(step_data))) {
    info <- step_data[i, ]
    interacting_variables <- .get_string_parts(info[["interactingVariables"]])
    interaction_variable <- info[["interactionVariable"]]

    mod$data[interaction_variable] <- 1
    for (i in seq_along(interacting_variables)) {
      mod$data[interaction_variable] <- mod$data[interaction_variable] *
        mod$data[interacting_variables[i]]
    }
    output_columns <- c(output_columns, interaction_variable)
  }

  list(
    mod = mod,
    output_columns = output_columns
  )
}
