library(testthat)

# Replicate the style lookup from app.R so we can test it in isolation
type_style <- list(
  "Restaurant"       = list(color = "red",       icon = "cutlery",       hex = "#d63e2a"),
  "Cafe"             = list(color = "orange",     icon = "coffee",        hex = "#f59630"),
  "Hospital"         = list(color = "blue",       icon = "plus-sign",     hex = "#38aadd"),
  "Clinic"           = list(color = "cadetblue",  icon = "plus-sign",     hex = "#5f9ea0"),
  "Market"           = list(color = "green",      icon = "shopping-cart", hex = "#72af26"),
  "Police"           = list(color = "darkblue",   icon = "lock",          hex = "#003e6b")
)

default_style <- list(color = "lightgray", icon = "map-marker", hex = "#a3a3a3")

get_style <- function(type) {
  if (type %in% names(type_style)) type_style[[type]] else default_style
}

test_that("get_style returns correct style for known types", {
  expect_equal(get_style("Restaurant")$color, "red")
  expect_equal(get_style("Hospital")$icon, "plus-sign")
  expect_equal(get_style("Market")$hex, "#72af26")
})

test_that("get_style returns default for unknown types", {
  result <- get_style("SomethingNew")
  expect_equal(result$color, "lightgray")
  expect_equal(result$icon, "map-marker")
  expect_equal(result$hex, "#a3a3a3")
})

test_that("All known types have color, icon, and hex fields", {
  for (type_name in names(type_style)) {
    s <- type_style[[type_name]]
    expect_true("color" %in% names(s), label = paste(type_name, "has color"))
    expect_true("icon"  %in% names(s), label = paste(type_name, "has icon"))
    expect_true("hex"   %in% names(s), label = paste(type_name, "has hex"))
    expect_match(s$hex, "^#[0-9a-fA-F]{6}$", label = paste(type_name, "hex format"))
  }
})
