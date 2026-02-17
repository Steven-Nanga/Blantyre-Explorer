# ============================================================================
# data_prep.R — Fetch precise location data for Blantyre Explorer
#
# This script pulls real, GPS-mapped locations from OpenStreetMap using:
#   1. Overpass API  — queries OSM for POIs in the Blantyre bounding box
#   2. Nominatim     — geocodes any manually-added locations for precision
#
# Both APIs are FREE and require NO API key.
# Run this script whenever you want to refresh the location data.
# ============================================================================

library(httr)
library(jsonlite)
library(dplyr)
library(readr)
library(tidygeocoder)

# --- Configuration -----------------------------------------------------------

# Blantyre bounding box (south, west, north, east)
BBOX <- c(south = -15.86, west = 34.94, north = -15.68, east = 35.08)

# Mapping from OSM amenity/shop tags to our display categories
TAG_TO_TYPE <- list(
  restaurant  = "Restaurant",
  fast_food   = "Restaurant",
  cafe        = "Cafe",
  hospital    = "Hospital",
  clinic      = "Clinic",
  pharmacy    = "Pharmacy",
  police      = "Police",
  marketplace = "Market",
  mall        = "Shopping Mall",
  supermarket = "Supermarket",
  bank        = "Bank",
  school      = "School",
  university  = "University",
  hotel       = "Hotel",
  guest_house = "Hotel",
  fuel        = "Fuel Station",
  place_of_worship = "Place of Worship",
  library     = "Library",
  bus_station = "Bus Station"
)

# --- 1. Fetch POIs from OpenStreetMap via Overpass API -----------------------

cat("=== Fetching locations from OpenStreetMap (Overpass API) ===\n")

# Build the Overpass query for all amenity and shop types we care about
amenity_tags <- c(
  "restaurant", "fast_food", "cafe",
  "hospital", "clinic", "pharmacy",
  "police", "marketplace",
  "bank", "school", "university",
  "hotel", "fuel", "place_of_worship",
  "library", "bus_station"
)

shop_tags <- c("mall", "supermarket")
tourism_tags <- c("hotel", "guest_house")

bbox_str <- sprintf("%s,%s,%s,%s", BBOX["south"], BBOX["west"], BBOX["north"], BBOX["east"])

# Build query parts for nodes and ways
query_parts <- c(
  # Amenity nodes and ways
  paste0(sprintf('  node["amenity"="%s"](%s);', amenity_tags, bbox_str), collapse = "\n"),
  paste0(sprintf('  way["amenity"="%s"](%s);',  amenity_tags, bbox_str), collapse = "\n"),
  # Shop nodes and ways
  paste0(sprintf('  node["shop"="%s"](%s);', shop_tags, bbox_str), collapse = "\n"),
  paste0(sprintf('  way["shop"="%s"](%s);',  shop_tags, bbox_str), collapse = "\n"),
  # Tourism nodes
  paste0(sprintf('  node["tourism"="%s"](%s);', tourism_tags, bbox_str), collapse = "\n"),
  paste0(sprintf('  way["tourism"="%s"](%s);',  tourism_tags, bbox_str), collapse = "\n")
)

overpass_query <- paste0(
  "[out:json][timeout:120];\n(\n",
  paste(query_parts, collapse = "\n"),
  "\n);\nout center;"
)

# Call the Overpass API
overpass_url <- "https://overpass-api.de/api/interpreter"
cat("Querying Overpass API (this may take a moment)...\n")

response <- tryCatch(
  POST(overpass_url, body = list(data = overpass_query), encode = "form"),
  error = function(e) {
    cat("ERROR: Could not connect to Overpass API:", conditionMessage(e), "\n")
    return(NULL)
  }
)

osm_data <- tibble()

if (!is.null(response) && status_code(response) == 200) {
  result <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  elements <- result$elements

  if (length(elements) > 0 && nrow(elements) > 0) {
    osm_data <- elements %>%
      mutate(
        # For ways, use the center coordinates
        lat = ifelse(!is.na(lat), lat, center$lat),
        lon = ifelse(!is.na(lon), lon, center$lon),
        # Extract the name
        name = tags$name,
        # Determine the type from tags
        raw_type = coalesce(tags$amenity, tags$shop, tags$tourism)
      ) %>%
      filter(!is.na(name), !is.na(lat), !is.na(lon)) %>%
      mutate(
        Type = sapply(raw_type, function(t) {
          if (t %in% names(TAG_TO_TYPE)) TAG_TO_TYPE[[t]] else tools::toTitleCase(t)
        })
      ) %>%
      select(Name = name, Latitude = lat, Longitude = lon, Type) %>%
      distinct(Name, Type, .keep_all = TRUE) %>%
      arrange(Type, Name)

    cat(sprintf("Found %d named locations from OpenStreetMap.\n", nrow(osm_data)))
    cat("\nBreakdown by type:\n")
    print(osm_data %>% count(Type, sort = TRUE))
  } else {
    cat("No elements returned from Overpass API.\n")
  }
} else {
  cat("WARNING: Overpass API request failed. Status:",
      ifelse(is.null(response), "connection error", status_code(response)), "\n")
}

# --- 2. Geocode manually-added locations via Nominatim -----------------------

cat("\n=== Geocoding manually-listed locations via Nominatim ===\n")

# Locations that you want to ensure are included even if not in OSM
manual_locations <- tribble(
  ~Name,                              ~Type,
  "21 Grill on Hannover, Blantyre",   "Restaurant",
  "Chez Maky, Blantyre",              "Restaurant",
  "Casa Mia Restaurant, Blantyre",    "Restaurant",
  "L'Hostaria, Blantyre",             "Restaurant",
  "La Caverna, Blantyre",             "Restaurant",
  "The Blue Elephant, Blantyre",      "Restaurant",
  "Hostellerie de France, Blantyre",  "Restaurant",
  "Veg-Delight, Blantyre",           "Restaurant",
  "KFC, Blantyre, Malawi",           "Restaurant",
  "Debonairs Pizza, Blantyre",        "Restaurant",
  "Queen Elizabeth Central Hospital, Blantyre", "Hospital",
  "Blantyre Adventist Hospital",      "Hospital",
  "Mwaiwathu Private Hospital, Blantyre", "Hospital",
  "Beit Cure International Hospital, Blantyre", "Hospital",
  "Mlambe Mission Hospital, Blantyre", "Hospital",
  "Chichiri Shopping Mall, Blantyre",  "Shopping Mall",
  "Blantyre Market, Malawi",          "Market",
  "Limbe Market, Blantyre",           "Market"
)

# Geocode using Nominatim (OSM) — free, no API key
cat("Geocoding", nrow(manual_locations), "manual locations via Nominatim...\n")

geocoded <- manual_locations %>%
  geocode(
    address = Name,
    method = "osm",
    lat = Latitude,
    long = Longitude,
    full_results = FALSE
  )

# Clean up the names (remove ", Blantyre" etc. from display name)
geocoded <- geocoded %>%
  mutate(Name = gsub(",\\s*(Blantyre|Malawi).*$", "", Name)) %>%
  filter(!is.na(Latitude), !is.na(Longitude))

cat(sprintf("Successfully geocoded %d of %d manual locations.\n",
            nrow(geocoded), nrow(manual_locations)))

if (nrow(geocoded) > 0) {
  cat("\nGeocoded locations:\n")
  print(geocoded %>% select(Name, Latitude, Longitude, Type))
}

# --- 3. Combine OSM + Geocoded data -----------------------------------------

cat("\n=== Combining data sources ===\n")

combined <- bind_rows(
  osm_data %>% mutate(Source = "OpenStreetMap"),
  geocoded %>% mutate(Source = "Geocoded")
) %>%
  # Remove near-duplicates (same name, close coordinates)
  distinct(Name, Type, .keep_all = TRUE) %>%
  # Ensure coordinates are within Blantyre bbox
  filter(
    Latitude  >= BBOX["south"], Latitude  <= BBOX["north"],
    Longitude >= BBOX["west"],  Longitude <= BBOX["east"]
  ) %>%
  arrange(Type, Name)

cat(sprintf("Total unique locations: %d\n", nrow(combined)))
cat("\nFinal breakdown by type:\n")
print(combined %>% count(Type, sort = TRUE))

# --- 4. Save to CSV ---------------------------------------------------------

output_file <- "blantyre_combined_locations.csv"

# Back up the old file
if (file.exists(output_file)) {
  backup_file <- paste0("blantyre_combined_locations_backup_",
                        format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
  file.copy(output_file, backup_file)
  cat(sprintf("\nBacked up old data to: %s\n", backup_file))
}

write_csv(combined, output_file)
cat(sprintf("Saved %d locations to: %s\n", nrow(combined), output_file))

cat("\n=== Done! ===\n")
cat("You can now run the Shiny app with the updated location data.\n")
