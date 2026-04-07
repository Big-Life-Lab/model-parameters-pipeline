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
  parts <- strsplit(s, split = split, fixed = TRUE) |>
    unlist() |>
    stringr::str_trim()

  parts
}

#' Generate a column name that does not already exist in a list of columns
#'
#' Generates a unique column name by appending an integer to a prefix.
#'
#' @param existing_columns Existing character vector/list of columns. We
#'   want a column name that does not already exist among these column
#'   names.
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
#'
#' @section Errors:
#'   * `missing_tag`: Raised when `column_suffix` does not contain the `"#"`
#'     placeholder character, which is required for generating numbered column
#'     name variants.
#'
#' @keywords internal
.get_unused_column <- function(
  existing_columns,
  column_prefix,
  column_suffix = "_#"
) {
  if (!stringr::str_detect(column_suffix, "#")) {
    stop(.make_error(
      error_class = "missing_tag",
      "The column_suffix passed to .get_unused_column must contain ",
      "the number sign '#': ",
      column_suffix
    ))
  }

  col_i <- 1
  while (TRUE) {
    if (col_i == 1) {
      cur_col <- column_prefix
    } else {
      cur_col <- paste0(
        column_prefix,
        stringr::str_replace_all(column_suffix, "#", as.character(col_i))
      )
    }
    if (!(cur_col %in% existing_columns)) {
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
#'
#' @section Errors:
#'   * `missing_columns`: Raised when one or more entries in `columns` are not
#'     present in `colnames(data)`. The error message lists the missing column
#'     names and, if `file` is provided, the basename of the file.
#'
#' @keywords internal
.verify_columns <- function(data, columns, data_description, file = NULL) {
  # Make sure all the columns exist in the data
  missing_columns <- columns[!(columns %in% colnames(data))]
  if (length(missing_columns) > 0) {
    missing_columns <- paste0("'", missing_columns, "'", collapse = ", ")
    msg <- paste0(
      "The following columns are missing in the ",
      data_description,
      ": ",
      missing_columns
    )
    if (is.character(file) && stringr::str_length(file)) {
      msg <- paste(
        msg,
        "in file",
        basename(file)
      )
    }
    stop(.make_error(error_class = "missing_columns", msg))
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
#'
#' @section Errors:
#'   * `inaccessible_file`: Raised when `file` does not exist, or when
#'     `mod$sandbox_path` is set and `file` is not a descendant of that
#'     directory. In the sandbox case the error message deliberately avoids
#'     revealing whether the file exists, to prevent directory enumeration.
#'   * `invalid_file_format`: Raised when `file` exists and is within the
#'     sandbox but cannot be read as a CSV by [utils::read.csv()].
#'
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
      stop(.make_error(
        error_class = "inaccessible_file",
        "The file does not exist: ",
        reportable_file
      ))
    } else {
      stop(.make_error(
        error_class = "inaccessible_file",
        general_error_message
      ))
    }
  }

  if (!(file %in% names(mod$files))) {
    # The file was not previously added, so we load and add it to the
    # file cache

    # Make sure the file is a descendant of the sandbox path
    if (!is.null(mod$sandbox_path) &&
        !.is_file_descendant_of(file, mod$sandbox_path)
    ) {
      stop(.make_error(
        error_class = "inaccessible_file",
        general_error_message
      ))
    }

    # Load and add file contents to the file cache, so we can retrieve
    # it with .get_file
    tryCatch({
      data <- utils::read.csv(file)
      mod$files[[file]] <- data
    }, error = function(e) {
      stop(.make_error(
        error_class = "invalid_file_format",
        "Could not load the file ",
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
#'
#' @section Errors:
#'   * `file_not_added`: Raised when `file` has not been previously loaded into
#'     the model cache via [`.add_file()`], indicating the caller did not add
#'     the file before attempting to retrieve it.
#'
#' @keywords internal
.get_file <- function(mod, file) {
  # The file should have already been added by calling .add_file
  file <- .expand_and_normalize_path(file)
  if (!(file %in% names(mod$files))) {
    stop(.make_error(
      error_class = "file_not_added",
      "The file must be added by calling ",
      ".add_file before calling .get_file: ",
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
#' The returned value should not be used for actual file access.
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
    # Expand relative_to_path and add a trailing slash.
    # relative_to_path will be NULL if the path is invalid or
    # does not exist
    relative_to_path <- .expand_and_normalize_path(
      relative_to_path,
      add_trailing_slash = TRUE
    )
    if (!is.null(relative_to_path)) {
      # Expand the file path
      norm_file <- .expand_and_normalize_path(file)

      # If the normalized file path begins with relative_to_path, then
      # remove relative_to_path from the file and return it.
      if (!is.null(norm_file) && startsWith(norm_file, relative_to_path)) {
        rel_start <- nchar(relative_to_path) + 1
        return(substr(norm_file, rel_start, nchar(norm_file)))
      }
    }
    return(basename(file))
  }
  file
}
