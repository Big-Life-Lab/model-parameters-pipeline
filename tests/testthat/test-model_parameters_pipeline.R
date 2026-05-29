test_that("model pipeline matches predicted risk with HTNPoRT", {
  # Test both the female and male validation data. We pass the input data
  # through the pipeline to get the final predicted risk, then compare that
  # computed risk with the predicted risk in the validation data.
  for (sex in c("female", "male")) {
    paths <- get_htnport_paths(sex)

    mod <- prepare_model_pipeline(paths$model_export_file)
    output_data <- run_model_pipeline(mod, x = paths$data_file)

    validation_data <- utils::read.csv(paths$data_file)

    expect_equal(
      unname(unlist(output_data)),
      validation_data[["predicted_risk"]],
      tolerance = 1e-6
    )
  }
})

test_that("model pipeline matches all intermediate columns with HTNPoRT", {
  # The predicted-risk test above only checks the final output. The HTNPoRT
  # validation data also stores every intermediate column produced along the
  # way (the rcs, interaction, and centered "_C" columns), so here we run the
  # pipeline in "full" mode and compare each produced column against its
  # reference column. This guards the entire pipeline against regressions, not
  # just the final risk.
  for (sex in c("female", "male")) {
    paths <- get_htnport_paths(sex)

    mod <- prepare_model_pipeline(paths$model_export_file)
    full_data <- run_model_pipeline(mod, x = paths$data_file, mode = "full")

    validation_data <- utils::read.csv(paths$data_file)

    # Compare every produced column that also appears in the reference data.
    # Columns the reference does not carry (unused dummy levels and the
    # internal logistic output name) are not part of the published outputs.
    shared_columns <- intersect(colnames(full_data), colnames(validation_data))
    expect_true(length(shared_columns) > 0)

    for (column in shared_columns) {
      expect_equal(
        full_data[[column]],
        validation_data[[column]],
        tolerance = 1e-6,
        info = paste0("sex = ", sex, ", column = ", column)
      )
    }
  }
})

test_that("model pipeline works with dataframes (instead of files)", {
  # Run the pipeline by passing in already-loaded dataframes (instead of
  # file names) vs running by specifying a file name for the model_export file
  for (sex in c("female", "male")) {
    paths <- get_htnport_paths(sex)

    # Run with dataframes
    mod <- prepare_model_pipeline(paths$model_export_file)
    output_data <- run_model_pipeline(
      mod,
      x = utils::read.csv(paths$data_file),
      mode = "full"
    )

    # Run with file names
    mod2 <- prepare_model_pipeline(paths$model_export_file)
    output_data2 <-  run_model_pipeline(
      mod2,
      x = paths$data_file,
      mode = "full"
    )

    expect_equal(
      output_data,
      output_data2
    )
  }
})

test_that("a model with no transformation steps raises empty_pipeline", {
  # Build a minimal model whose model-steps file defines no steps. The
  # pipeline has no output to return, so it should raise a classified
  # error rather than failing with a cryptic subscript error.
  base_tmp <- tempfile("empty_pipeline_test_")
  dir.create(base_tmp)
  on.exit(unlink(base_tmp, recursive = TRUE), add = TRUE)

  write.csv(
    data.frame(role = "Predictor", variable = "var_a"),
    file.path(base_tmp, "variables.csv"),
    row.names = FALSE
  )
  # Model steps file with the required columns but no rows
  write.csv(
    data.frame(step = character(0), filePath = character(0)),
    file.path(base_tmp, "model-steps.csv"),
    row.names = FALSE
  )
  write.csv(
    data.frame(
      fileType = c("variables", "model-steps"),
      filePath = c("./variables.csv", "./model-steps.csv")
    ),
    file.path(base_tmp, "model-export.csv"),
    row.names = FALSE
  )

  mod <- prepare_model_pipeline(file.path(base_tmp, "model-export.csv"))
  input_data <- data.frame(var_a = c(1, 2, 3))

  expect_error(
    run_model_pipeline(mod, x = input_data),
    class = "empty_pipeline"
  )
  expect_error(
    run_model_pipeline(mod, x = input_data, mode = "full"),
    class = "empty_pipeline"
  )
})

test_that("transformation steps work", {
  root_dir <- testthat::test_path("testdata/steps")
  for (cur_dir in list.dirs(root_dir, recursive = FALSE)) {
    run_step_on_test_data(basename(cur_dir))
  }
})

test_that("sandbox_path allows files within the sandbox", {
  paths <- get_htnport_paths("female")
  expect_no_error(
    prepare_model_pipeline(
      paths$model_export_file,
      sandbox_path = paths$root_dir
    )
  )
})

test_that("sandbox_path raises an error for files outside the sandbox", {
  paths <- get_htnport_paths("female")
  # Use a subdirectory that does not contain the model files as the sandbox
  expect_error(
    prepare_model_pipeline(
      paths$model_export_file,
      sandbox_path = tempdir()
    ),
    class = "inaccessible_file"
  )
})

test_that("sandbox_path = NULL imposes no restriction", {
  paths <- get_htnport_paths("female")
  expect_no_error(
    prepare_model_pipeline(
      paths$model_export_file,
      sandbox_path = NULL
    )
  )
})

test_that("sandbox_path prefix match without trailing slash is rejected", {
  # This test guards against a naive startsWith() check that omits the trailing
  # slash, when testing if a file is within the sandbox_path. Given:
  #   model files in:  <base>/htnport/
  #   sandbox_path:    <base>/htnpor   (no trailing slash)
  # A bare startsWith() test would return TRUE (ie. the model files are in the
  # sandbox path) because "htnpor" is a string prefix of "htnport", incorrectly
  # treating the sibling directory as the parent. The correct implementation
  # appends "/" to the sandbox_path before checking, to ensure that the files
  # are properly marked as not being within the sandbox_path.
  base_tmp <- tempfile("sandbox_prefix_test_")
  dir.create(base_tmp)
  on.exit(unlink(base_tmp, recursive = TRUE), add = TRUE)

  # Copy all HTNPoRT female model files into <base_tmp>/htnport/
  model_dir <- file.path(base_tmp, "htnport")
  dir.create(model_dir)
  src_paths <- get_htnport_paths("female")
  file.copy(list.files(src_paths$root_dir, full.names = TRUE), model_dir)

  model_export_file <- file.path(model_dir,
                                 basename(src_paths$model_export_file))

  # Create <base_tmp>/htnpor/ — this directory exists, but is a sibling of
  # htnport/, not its parent.  Its normalized path is a string-prefix of
  # model_dir only when no trailing slash is appended.
  sandbox_dir <- file.path(base_tmp, "htnpor")
  dir.create(sandbox_dir)

  expect_error(
    prepare_model_pipeline(model_export_file, sandbox_path = sandbox_dir),
    class = "inaccessible_file"
  )
})
