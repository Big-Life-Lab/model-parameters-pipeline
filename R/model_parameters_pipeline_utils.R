#' Utility Functions for Model Parameters Pipeline
#'
#' This file contains internal utility functions used throughout the model
#' parameters pipeline for string manipulation, data validation, and
#' restricted cubic spline calculations.
#' @noRd
#' @name model_parameters_pipeline_utils

library(stringr)

#' Split and trim string parts
#'
#' @param s Character string to split
#' @param split Character string to use as delimiter (default: ";")
#' @return Character vector of trimmed string parts
#' @keywords internal
.get_string_parts <- function(s, split = ";") {
  parts <- strsplit(s, split = split) |>
    unlist() |>
    stringr::str_trim()

  parts
}

#' Find an unused column name in a dataframe
#'
#' Generates a unique column name by appending an integer to a prefix.
#' Iteratively checks for column_prefix1, column_prefix2, etc. until
#' finding a name that doesn't exist in the dataframe.
#'
#' @param df Data frame to check for existing column names
#' @param column_prefix Character prefix for the column name
#' @return Character string of an unused column name
#'   (e.g., "prefix1", "prefix2")
#' @keywords internal
.get_unused_column <- function(df, column_prefix) {
  col_i <- 1
  while (TRUE) {
    cur_col <- paste0(column_prefix, col_i)
    if (!(cur_col %in% colnames(df))) {
      return(cur_col)
    }
    col_i <- col_i + 1
  }
}

#' Verify required columns exist in a dataframe
#'
#' Checks that all required columns are present in the dataframe and stops
#' with an informative error message if any are missing.
#'
#' @param df Data frame to validate
#' @param columns Character vector of required column names
#' @param data_description Description of the data being validated to include
#'   in the error message.
#' @param file Optional file path to include in error message (to indicate
#'   where the data originated from). For example: "model steps file" or
#'   "model steps data".
#' @keywords internal
.verify_columns <- function(df, columns, data_description, file = NULL) {
  # Make sure all the columns exist in the dataframe
  missing_columns <- columns[!(columns %in% colnames(df))]
  if (length(missing_columns) > 0) {
    missing_columns <- paste0("'", missing_columns, "'", collapse = ", ")
    message <- paste0(
      "The following columns are missing in the ",
      data_description,
      ": ",
      missing_columns
    )
    if (is.character(file) && stringr::str_length(file)) {
      message <- paste0(message, " in file ", file)
    }
    stop(message)
  }
}

#' Add File to Model Cache
#'
#' Internal function that loads a CSV file and adds it to the model's file
#' cache.
#'
#' @param mod Model object
#' @param file Path to CSV file to load
#' @return Updated model object with file in cache
#' @keywords internal
.add_file <- function(mod, file) {
  file <- normalizePath(file, mustWork = TRUE)
  if (!(file %in% names(mod$files))) {
    # Add file contents to the model, so we can retrieve it with .get_file
    df <- utils::read.csv(file)
    mod$files[[file]] <- df
  }

  mod
}

#' Get File from Model Cache
#'
#' Internal function that retrieves a previously loaded file from the
#' model's cache.
#'
#' @param mod Model object
#' @param file Path to file to retrieve
#' @return Data frame from the file cache
#' @keywords internal
.get_file <- function(mod, file) {
  # The file should have already been added by calling .add_file
  file <- normalizePath(file, mustWork = TRUE)
  if (!(file %in% names(mod$files))) {
    stop(paste(
      "The file must be added by calling",
      ".add_file before calling .get_file:",
      file
    ))
  }
  mod$files[[file]]
}
