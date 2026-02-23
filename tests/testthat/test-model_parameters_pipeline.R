test_that("model pipeline matches predicted risk with HTNPoRT", {
  # Test both the female and male validation data. We pass the input data
  # through the pipeline to get the final predicted risk, then compare that
  # computed risk with the predicted risk in the validation data.
  for (sex in c("female", "male")) {
    paths <- get_htnport_paths(sex)

    mod <- prepare_model_pipeline(paths$model_export_file)
    output_data <- run_model_pipeline(
      mod,
      dat = paths$data_file,
      mode = "output"
    )

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
      dat = utils::read.csv(paths$data_file), mode = "full"
    )

    # Run with file names
    mod2 <- prepare_model_pipeline(paths$model_export_file)
    output_data2 <- run_model_pipeline(
      mod2,
      dat = paths$data_file, mode = "full"
    )

    expect_equal(
      output_data,
      output_data2
    )
  }
})

test_that("transformation steps work", {
  root_dir <- testthat::test_path("testdata/step-tests")
  for (cur_dir in list.dirs(root_dir, recursive = FALSE)) {
    run_test_data(basename(cur_dir), "test-data.csv")
  }
})
