#' Utility Functions for Model Parameters Pipeline
#'
#' This file contains internal utility functions used throughout the model
#' parameters pipeline for string manipulation, data validation, and
#' restricted cubic spline calculations.
#' @noRd
#' @name model_parameters_pipeline_utils
NULL

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

#' Find an unused column name in the data
#'
#' Generates a unique column name by appending an integer to a prefix.
#'
#' @param data Data to check for existing column names.
#' @param column_prefix Character prefix for the column name
#' @param column_suffix If a column named column_prefix already exists
#'   then column_suffix is appended to column_prefix, replacing "#"
#'   with an integer, to try to find an unused column name. For example,
#'   if column_prefix = "output" and column_suffix = "_#", then "output"
#'   will be returned if such a column doesn't exist. If it does exist,
#'   then "output_2", "output_3", etc. will be tested until an unused
#'   column name is found.
#' @return Character string of an unused column name
#'   (e.g., "prefix_2", "prefix_3")
#' @keywords internal
.get_unused_column <- function(data, column_prefix, column_suffix = "_#") {
  if (!stringr::str_detect(column_suffix, "#")) {
    stop(paste(
      "The column_suffix passed to .get_unused_column must contain",
      "the number sign '#':",
      column_suffix
    ))
  }

  col_i <- 1
  while (TRUE) {
    if (col_i == 1) {
      cur_col = column_prefix
    } else {
      cur_col <- paste0(
        column_prefix,
        stringr::str_replace_all(column_suffix, "#", as.character(col_i))
      )
    }
    if (!(cur_col %in% colnames(data))) {
      return(cur_col)
    }
    col_i <- col_i + 1
  }
}

#' Verify required columns exist in the data
#'
#' Checks that all required columns are present in the data and stops
#' with an informative error message if any are missing.
#'
#' @param data Data to validate (eg. a dataframe)
#' @param columns Character vector of required column names
#' @param data_description Description of the data being validated to include
#'   in the error message.
#' @param file Optional file path to include in error message (to indicate
#'   where the data originated from). For example: "model steps file" or
#'   "model steps data".
#' @keywords internal
.verify_columns <- function(data, columns, data_description, file = NULL) {
  # Make sure all the columns exist in the data
  missing_columns <- columns[!(columns %in% colnames(data))]
  if (length(missing_columns) > 0) {
    missing_columns <- paste0("'", missing_columns, "'", collapse = ", ")
    message <- paste0(
      "The following columns are missing in the ",
      data_description,
      ": ",
      missing_columns
    )
    if (is.character(file) && stringr::str_length(file)) {
      message <- paste(
        message,
        "in file",
        basename(file)
      )
    }
    stop(message)
  }
}

#' Get a file path safe to include in user-facing error messages
#'
#' If `mod$sandbox_path` is set, returns the path of `file` relative to
#' `sandbox_path`, or just the filename if `file` is not inside `sandbox_path`
#' or if it does not exist. If `mod$sandbox_path` is not set, returns `file`
#' unchanged.
#'
#' The returned path avoids exposing the underlying directory structure of the
#' system to the user, which is useful for displaying error messages on a
#' website or other public-facing context.
#'
#' @param mod The model object, optionally containing `sandbox_path`.
#' @param file The file path to make reportable.
#' @return A file path safe to display in user-facing error messages.
#' @keywords internal
.reportable_file <- function(mod, file) {
  if (is.null(mod$sandbox_path)) {
    file
  } else {
    .file_relative_to_path(file, mod$sandbox_path)
  }
}

#' Load and Add File to Model Cache
#'
#' Internal function that loads a CSV file and adds it to the model's file
#' cache.
#'
#' @param mod Model object
#' @param file Path to CSV file to load
#' @return Updated model object with file in cache
#' @keywords internal
.add_file <- function(mod, file) {
  # If an error occurs, we display this file to the user. If mod$sandbox_path is
  # set then the reportable_file only shows the path relative to the
  # sandbox_path (or just the filename if it is not in the sandbox_path)
  reportable_file <- .reportable_file(mod, file)

  # We use this general error message that says a file either doesn't exist
  # or it is outside of the sandbox path (but not telling them which one)
  # so that users cannot determine which files exist on the file system.
  # We only do this if mod$sandbox_path is set. If it isn't, we give a
  # more detailed error message.
  general_error_message <- paste(
    "The file does not exist or is outside of the sandbox path:",
    reportable_file
  )

  file <- .expand_and_normalize_path(file)
  if (is.null(file)) {
    if (is.null(mod$sandbox_path)) {
      stop(paste(
        "The file does not exist:",
        reportable_file
      ))
    } else {
      stop(general_error_message)
    }
  }

  if (!(file %in% names(mod$files))) {
    # The file was not previously added, so we load and add it to the
    # file cache

    # Make sure the file is a descendant of the sandbox path
    if (!is.null(mod$sandbox_path) &&
        !.is_file_descendant_of(file, mod$sandbox_path)
    ) {
      stop(general_error_message)
    }

    # Load and add file contents to the file cache, so we can retrieve
    # it with .get_file
    tryCatch({
      data <- utils::read.csv(file)
      mod$files[[file]] <- data
    }, error = function(e) {
      stop(paste(
        "Could not load the file",
        reportable_file
      ))
    })
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
#' @return Data from the file cache (eg. a dataframe)
#' @keywords internal
.get_file <- function(mod, file) {
  # The file should have already been added by calling .add_file
  file <- .expand_and_normalize_path(file)
  if (!(file %in% names(mod$files))) {
    stop(paste(
      "The file must be added by calling",
      ".add_file before calling .get_file:",
      .reportable_file(mod, file)
    ))
  }
  mod$files[[file]]
}

#' Expand and normalize a file path.
#'
#' Symbolic links and ".." will be followed and expanded.
#'
#' @param p Character. The path to expand and normalize.
#' @param add_trailing_slash Logical. If `TRUE`, a trailing slash is appended to
#'   the normalized path if it does not already have one. This is useful if the
#'   path is known to be a directory. Defaults to `FALSE`.
#' @return Character. The normalized path, or `NULL` if the path is invalid or
#'   does not exist.
#' @keywords internal
.expand_and_normalize_path <- function(p, add_trailing_slash = FALSE) {
  # Try to normalize the path. If the path does not exist then
  # we return NULL
  normalized <- NULL
  tryCatch({
    normalized <- normalizePath(
      p,
      winslash = .Platform$file.sep,
      mustWork = TRUE
    )
  }, error = function(e) {
    # This error handler stops normalizePath from printing out an error
  })
  if (is.null(normalized)) {
    return(NULL)
  }

  if (add_trailing_slash) {
    # Add a trailing slash if there isn't one. This is useful
    # for directories
    len <- stringr::str_length(normalized)
    if (len > 0 && substr(normalized, len, len) != .Platform$file.sep) {
      normalized <- paste0(normalized, .Platform$file.sep)
    }
  }

  normalized
}

#' Check if a file is a descendant of a directory, and that both the file and
#' directory exist.
#'
#' Symbolic links and ".." will be followed and expanded.
#'
#' @param file Character. The path to the file to check.
#' @param top_level_directory Character. The path to the directory that `file`
#'   should be a descendant of.
#' @return Logical. `TRUE` if `file` is a descendant of `top_level_directory`,
#'   `FALSE` otherwise. Returns `FALSE` if either `file` or
#'   `top_level_directory` do not exist on the file system.
#' @keywords internal
.is_file_descendant_of <- function(file, top_level_directory) {
  file <- .expand_and_normalize_path(file)
  top_level_directory <- .expand_and_normalize_path(
    top_level_directory,
    add_trailing_slash = TRUE
  )

  # Check if file or top_level_directory are invalid or do not exist
  if (is.null(file) || is.null(top_level_directory)) {
    return(FALSE)
  }

  # Make sure file is within top_level_directory
  startsWith(file, top_level_directory)
}

#' Format the file path to be relative to relative_to_path
#'
#' This is generally for informational purposes to report to the user. It is
#' meant to hide the full paths of files on the system from a user so that
#' attackers cannot gather information about the system's directory structure.
#' Usually, the relative_to_path parameter would be the sandbox path.
#'
#' @param file The file path to format.
#' @param relative_to_path The path that we want the file to be
#'   relative to.
#' @return The formatted file path. If either `file` or `relative_to_path`
#'   do not exist, or if `file` is not a descendant of `relative_to_path` then
#'   simply the basename of `file` is returned.
#' @keywords internal
.file_relative_to_path <- function(file, relative_to_path) {
  if (!is.null(relative_to_path)) {
    relative_to_path <- .expand_and_normalize_path(
      relative_to_path,
      add_trailing_slash = TRUE
    )
    if (!is.null(relative_to_path)) {
      norm_file <- .expand_and_normalize_path(file)
      if (!is.null(norm_file) && startsWith(norm_file, relative_to_path)) {
        rel_start <- nchar(relative_to_path) + 1
        return(substr(norm_file, rel_start, nchar(norm_file)))
      }
    }
    return(basename(file))
  }
  file
}

#' Rename output columns to use a standard prefix/suffix scheme
#'
#' Renames the output columns of the last step in a pipeline model object so
#' that they follow a consistent naming convention based on the given prefix and
#' suffix. Each output column is assigned a unique name via
#' [.get_unused_column()], avoiding collisions with existing columns in the
#' data.
#'
#' @param mod A pipeline model object. Must contain `$data` (a data frame) and
#'   `$steps_info` (a list of step metadata), where the last element of
#'   `steps_info` has an `$output_columns` field.
#' @param prefix Character string used as the base name for output columns.
#'   Defaults to `"output"`.
#' @param suffix Character string appended to `prefix` (with `"#"` replaced by
#'   an integer) when the bare prefix is already taken. Must contain `"#"`.
#'   Defaults to `"_#"`, producing names like `"output"`, `"output_2"`,
#'   `"output_3"`, etc.
#' @return The modified pipeline model object with output columns renamed in
#'   both `$data` and the last element of `$steps_info$output_columns`.
#' @keywords internal
.rename_output_columns <- function(mod, prefix = "output", suffix = "_#") {
  dat <- mod$data

  # Get the current output column names
  original_output_columns <-
    mod$steps_info[[length(mod$steps_info)]]$output_columns

  # Rename the columns in the data to the final prefix/suffix names
  new_output_columns <- c()
  for (column in original_output_columns) {
    cur_column <- .get_unused_column(dat, prefix, suffix)
    colnames(dat)[colnames(dat) == column] <- cur_column
    new_output_columns <- c(new_output_columns, cur_column)
  }

  # Reassign the output columns to mod
  mod$steps_info[[length(mod$steps_info)]]$output_columns <- new_output_columns

  # Reassign the data
  mod$data <- dat

  mod
}
