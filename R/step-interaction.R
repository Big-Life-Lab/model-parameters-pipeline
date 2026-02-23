#' Run Interaction Step
#'
#' Creates interaction terms by multiplying specified variables together.
#' Implements the 'interaction' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object
#' @param dat Data frame containing the input data to be transformed
#' @param file Path to interaction step specification file
#' @return A list containing: \code{mod} (the updated model object),
#'   \code{data} (the transformed data frame with interaction variables added),
#'   and \code{output_columns} (character vector of new column names added
#'   by this step)
#' @keywords internal
.run_step_interaction <- function(mod, dat, file) {
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

    dat[interaction_variable] <- 1
    for (i in seq_along(interacting_variables)) {
      dat[interaction_variable] <- dat[interaction_variable] *
        dat[interacting_variables[i]]
    }
    output_columns <- c(output_columns, interaction_variable)
  }

  list(
    mod = mod,
    data = dat,
    output_columns = output_columns
  )
}
