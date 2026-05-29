test_that(".add_file and .get_file work", {
  # Get and load datafiles for HTNPoRT for testing
  female_paths <- get_htnport_paths("female")
  female_data_file <- female_paths$data_file
  female_expected_data <- utils::read.csv(female_paths$data_file)
  male_paths <- get_htnport_paths("male")
  male_data_file <- male_paths$data_file
  male_expected_data <- utils::read.csv(male_paths$data_file)

  mod <- list()

  mod <- .add_file(mod, female_data_file)
  test_data <- .get_file(mod, female_data_file)
  expect_equal(
    test_data,
    female_expected_data,
    info = "Failed retrieving single file added with .add_file"
  )

  mod <- .add_file(mod, male_data_file)
  test_data <- .get_file(mod, male_data_file)
  expect_equal(
    test_data,
    male_expected_data,
    info = "Failed retrieving second file added with .add_file"
  )

  test_data <- .get_file(mod, female_data_file)
  expect_equal(
    test_data,
    female_expected_data,
    info = "Failed retrieving 1st file after adding 2nd file with .add_file"
  )

  expect_error(
    .add_file(mod, "___unused_name___.csv"),
    info = "Expected error adding invalid file name with .add_file",
    class = "inaccessible_file"
  )

  # Add already added file
  expect_no_error(
    .add_file(mod, male_data_file)
  )

  mod2 <- list()
  expect_error(
    .get_file(mod2, female_data_file),
    info = "Expected error calling .get_file with file not added by .add_file",
    class = "file_not_added"
  )
})

test_that("Utility function .verify_columns works", {
  test_data <- data.frame(
    "other" = c("1", "2", "3"),
    "col_1" = c("a", "b", "c"),
    "col_2" = c("d", "e", "f"),
    "col_3" = c("g", "h", "i")
  )

  expect_no_error(
    .verify_columns(test_data, c("col_1"), "test data")
  )

  expect_no_error(
    .verify_columns(test_data, c("col_1", "col_2", "col_3"), "test data")
  )

  expect_error(
    .verify_columns(test_data, c("missing"), "test data"),
    info = "Expected error testing for a single missing column",
    class = "missing_columns",
  )

  expect_error(
    .verify_columns(test_data, c("col_1", "col_2", "bad"), "test data"),
    info = "Expected error testing for multiple missing columns",
    class = "missing_columns",
  )
})

test_that("Utility function .get_unused_column works", {
  existing_columns <- c(
    "other",
    "col",
    "col_1",
    "col_2",
    "col_4"
  )
  expect_equal(
    .get_unused_column(existing_columns, "col"),
    "col_3",
    info = paste("Failed with two existing columns")
  )
  expect_equal(
    .get_unused_column(existing_columns, "extra"),
    "extra",
    info = paste("Failed with no existing column")
  )
})

test_that(".run_step_rcs validates the rcsVariables count against the knots", {
  base_tmp <- tempfile("rcs_count_test_")
  dir.create(base_tmp)
  on.exit(unlink(base_tmp, recursive = TRUE), add = TRUE)

  mod <- list(data = data.frame(var_a = c(1, 2, 3, 4)))

  # 4 knots require 3 rcsVariables, but only 2 are specified -> mismatch
  too_few_file <- file.path(base_tmp, "rcs-too-few.csv")
  write.csv(
    data.frame(
      variable = "var_a",
      rcsVariables = "var_a_rcs_1;var_a_rcs_2",
      knots = "-150;20;100;350"
    ),
    too_few_file,
    row.names = FALSE
  )
  expect_error(
    .run_step_rcs(mod, too_few_file),
    class = "rcs_variable_count_mismatch"
  )

  # The matching count (3 rcsVariables for 4 knots) must not error
  correct_file <- file.path(base_tmp, "rcs-correct.csv")
  write.csv(
    data.frame(
      variable = "var_a",
      rcsVariables = "var_a_rcs_1;var_a_rcs_2;var_a_rcs_3",
      knots = "-150;20;100;350"
    ),
    correct_file,
    row.names = FALSE
  )
  expect_no_error(.run_step_rcs(mod, correct_file))
})

test_that("step functions reject non-numeric parameters", {
  base_tmp <- tempfile("non_numeric_test_")
  dir.create(base_tmp)
  on.exit(unlink(base_tmp, recursive = TRUE), add = TRUE)

  mod <- list(data = data.frame(var_a = c(1, 2, 3, 4)))

  # rcs: a non-numeric knot
  rcs_file <- file.path(base_tmp, "rcs.csv")
  write.csv(
    data.frame(
      variable = "var_a",
      rcsVariables = "var_a_rcs_1;var_a_rcs_2",
      knots = "-150;abc;350"
    ),
    rcs_file,
    row.names = FALSE
  )
  expect_error(.run_step_rcs(mod, rcs_file), class = "non_numeric_knots")

  # center: a non-numeric centerValue
  center_file <- file.path(base_tmp, "center.csv")
  write.csv(
    data.frame(
      origVariable = "var_a",
      centerValue = "not_a_number",
      centeredVariable = "var_a_C"
    ),
    center_file,
    row.names = FALSE
  )
  expect_error(
    .run_step_center(mod, center_file),
    class = "non_numeric_center_value"
  )

  # logistic-regression: a non-numeric coefficient
  logistic_file <- file.path(base_tmp, "logistic.csv")
  write.csv(
    data.frame(
      variable = "var_a",
      coefficient = "oops"
    ),
    logistic_file,
    row.names = FALSE
  )
  expect_error(
    .run_step_logistic_regression(mod, logistic_file),
    class = "non_numeric_coefficient"
  )
})

test_that("Utility function .get_string_parts works", {
  # Basic test with 3 parts
  expected_parts <- c("part1", "part2", "part3")
  str_parts <- paste(expected_parts, collapse = ";")
  expect_equal(
    .get_string_parts(str_parts, split = ";"),
    expected_parts,
    info = paste("Failed on basic test with 3 parts:", str_parts)
  )

  # Basic test with a different split value
  expected_parts <- c("part1", "part2", "part3")
  str_parts <- paste(expected_parts, collapse = ",")
  expect_equal(
    .get_string_parts(str_parts, split = ","),
    expected_parts,
    info = paste("Failed with alternate ',' separator:", str_parts)
  )

  # Basic test with one part
  expected_parts <- c("part1")
  str_parts <- paste(expected_parts, collapse = ";")
  expect_equal(
    .get_string_parts(str_parts, split = ";"),
    expected_parts,
    info = paste("Failed on string with a single part", str_parts)
  )

  # Test for trimming whitespace
  expected_parts <- c("part1", "part2", "part3")
  str_parts <- paste0(expected_parts, collapse = " ;  ")
  expect_equal(
    .get_string_parts(str_parts, split = ";"),
    expected_parts,
    info = paste("Failed trimming additional whitespace:", str_parts)
  )
})
