#' Run Interaction Step
#'
#' Creates interaction terms by multiplying specified variables together.
#' Implements the 'interaction' transformation step from the Model
#' Parameters pipeline.
#'
#' @param mod Model object
#' @param file Path to interaction step specification file
#' @return Updated model object with interaction variables added to data
#' @keywords internal
.run_step_interaction <- function(mod, file) {
  mod <- .add_file(mod, file)
  step_df <- .get_file(mod, file)
  .verify_columns(
    step_df,
    c("interactingVariables", "interactionVariable"),
    "interaction step file",
    file
  )

  for (i in seq_len(nrow(step_df))) {
    info <- step_df[i, ]
    interacting_variables <- .get_string_parts(info[["interactingVariables"]])
    interaction_variable <- info[["interactionVariable"]]

    mod$df[interaction_variable] <- 1
    for (i in seq_along(interacting_variables)) {
      mod$df[interaction_variable] <- mod$df[interaction_variable] *
        mod$df[interacting_variables[i]]
    }
  }

  mod
}
