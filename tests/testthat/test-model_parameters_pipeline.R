test_that("model pipeline matches predicted risk with HTNPoRT", {
  # Test both the female and male validation data. We pass the input data
  # through the pipeline to get the final predicted risk, then compare that
  # computed risk with the predicted risk in the validation data.
  for (sex in c("female", "male")) {
    paths <- get_htnport_paths(sex)

    mod <- prepare_model_pipeline(paths$model_export_file)
    output_data <- run_model_pipeline(mod, dat = paths$data_file)

    validation_data <- utils::read.csv(paths$data_file)

    expect_equal(
      unname(unlist(output_data)),
      validation_data[["predicted_risk"]],
      tolerance = 1e-6
    )
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
      dat = utils::read.csv(paths$data_file),
      mode = "full"
    )

    # Run with file names
    mod2 <- prepare_model_pipeline(paths$model_export_file)
    output_data2 <-  run_model_pipeline(
      mod2,
      dat = paths$data_file,
      mode = "full"
    )

    expect_equal(
      output_data,
      output_data2
    )
  }
})

test_that("transformation steps work", {
  root_dir <- testthat::test_path("testdata/steps")
  for (cur_dir in list.dirs(root_dir, recursive = FALSE)) {
    run_test_data(basename(cur_dir), "data.csv")
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
    )
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
    prepare_model_pipeline(model_export_file, sandbox_path = sandbox_dir)
  )
})
