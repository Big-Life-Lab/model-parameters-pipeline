test_that("model pipeline matches predicted risk with HTNPoRT", {
  # Test both the female and male validation data. We pass the input data
  # through the pipeline to get the final predicted risk, then compare that
  # computed risk with the predicted risk in the validation data.
  for (sex in c("female", "male")) {
    paths <- get_htnport_paths(sex)

    mod <- run_model_pipeline(
      root_dir = dirname(paths$model_export_file),
      model_export = paths$model_export_file,
      data = paths$data_file
    )

    validation_data <- utils::read.csv(paths$data_file)

    expect_equal(
      mod$df[["logistic_1"]],
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
    mod <- run_model_pipeline(
      root_dir = dirname(paths$model_export_file),
      model_export = utils::read.csv(paths$model_export_file),
      variables = utils::read.csv(paths$variables_file),
      model_steps = utils::read.csv(paths$model_steps_file),
      data = utils::read.csv(paths$data_file)
    )

    # Run with file names
    mod2 <- run_model_pipeline(
      root_dir = dirname(paths$model_export_file),
      model_export = paths$model_export_file,
      data = paths$data_file
    )

    expect_equal(
      mod$df,
      mod2$df
    )
  }
})

test_that("using existing model pipeline for cached performance with HTNPoRT", {
  # run_model_pipeline allows an existing_mod parameter to pass in a
  # pipeline that has already been run. This pipeline should have
  # some cached data (ie. copies of all data and model parameter files
  # already loaded from disk). Rerunning the pipeline with the existing
  # one should give identical results.
  for (sex in c("female", "male")) {
    paths <- get_htnport_paths(sex)

    mod <- run_model_pipeline(
      root_dir = paths$root_dir,
      model_export = paths$model_export_file,
      data = paths$data_file
    )

    # Reuse the previous mod (should have improved performance but same results
    # due to cached files)
    mod2 <- run_model_pipeline(
      root_dir = paths$root_dir,
      model_export = paths$model_export_file,
      data = paths$data_file,
      existing_mod = mod
    )

    validation_data <- utils::read.csv(paths$data_file)
    expect_equal(
      mod2$df[["logistic_1"]],
      mod$df[["logistic_1"]]
    )
  }
})

test_that("transformation steps work", {
  root_dir <- testthat::test_path("testdata/step-tests")
  for (cur_dir in list.dirs(root_dir, recursive = FALSE)) {
    run_test_data(basename(cur_dir), "test-data.csv")
  }
})
