library(testthat)
library(readr)
library(dplyr)

# Path to the CSV relative to the project root
csv_path <- file.path("BlantyreExplorer", "blantyre_combined_locations.csv")

test_that("CSV file exists and is readable", {
  skip_if_not(file.exists(csv_path), "CSV not found — run data_prep.R first")
  data <- read_csv(csv_path, show_col_types = FALSE)
  expect_true(is.data.frame(data))
  expect_gt(nrow(data), 0)
})

test_that("CSV contains all required columns", {
  skip_if_not(file.exists(csv_path), "CSV not found")
  data <- read_csv(csv_path, show_col_types = FALSE)
  required <- c("Name", "Latitude", "Longitude", "Type")
  expect_true(all(required %in% names(data)))
})

test_that("Coordinates are within Blantyre bounding box", {
  skip_if_not(file.exists(csv_path), "CSV not found")
  data <- read_csv(csv_path, show_col_types = FALSE) %>%
    filter(!is.na(Latitude), !is.na(Longitude))

  expect_true(all(data$Latitude  >= -16.0  & data$Latitude  <= -15.5))
  expect_true(all(data$Longitude >= 34.8   & data$Longitude <= 35.2))
})

test_that("No duplicate Name+Type combinations", {
  skip_if_not(file.exists(csv_path), "CSV not found")
  data <- read_csv(csv_path, show_col_types = FALSE)
  dupes <- data %>% group_by(Name, Type) %>% filter(n() > 1)
  expect_equal(nrow(dupes), 0, label = "Duplicate Name+Type rows")
})

test_that("All names are non-empty strings", {
  skip_if_not(file.exists(csv_path), "CSV not found")
  data <- read_csv(csv_path, show_col_types = FALSE)
  expect_true(all(!is.na(data$Name)))
  expect_true(all(nchar(trimws(data$Name)) > 0))
})

test_that("All types are non-empty strings", {
  skip_if_not(file.exists(csv_path), "CSV not found")
  data <- read_csv(csv_path, show_col_types = FALSE)
  expect_true(all(!is.na(data$Type)))
  expect_true(all(nchar(trimws(data$Type)) > 0))
})
