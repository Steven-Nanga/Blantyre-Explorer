# Blantyre Explorer

[![Deployed on shinyapps.io](https://img.shields.io/badge/Shiny-shinyapps.io-blue?style=flat&labelColor=white&logo=RStudio&logoColor=blue)](https://mnakjp-steven-nanga.shinyapps.io/BlantyreExplorer/)

An interactive web application for discovering places across **Blantyre, Malawi** — the warm heart of Africa's commercial hub. Built with R Shiny, Leaflet, and real-time OpenStreetMap data.

**[Launch the Live App](https://mnakjp-steven-nanga.shinyapps.io/BlantyreExplorer/)**

## Features

- **360+ GPS-Precise Locations** — All sourced from OpenStreetMap, mapped by real contributors with GPS coordinates.
- **Interactive Map** — Pan, zoom, and choose from three base map layers (Light, Streets, Satellite).
- **Color-Coded Markers** — Each of the 16 location types gets a unique color and Font Awesome icon:

  | Color | Type | Color | Type |
  |-------|------|-------|------|
  | Red | Restaurants | Blue | Hospitals |
  | Orange | Cafes | Cadet Blue | Clinics |
  | Purple | Pharmacies | Dark Blue | Police |
  | Green | Markets | Dark Green | Shopping Malls & Supermarkets |
  | Gray | Banks | Beige | Schools & Universities |
  | Pink | Hotels | Black | Fuel Stations |
  | Light Blue | Places of Worship | Light Gray | Libraries |
  | Dark Red | Bus Stations | | |

- **Live Search** — Instantly filter locations by name as you type.
- **Filter by Type** — Dropdown to narrow down to a specific category.
- **Click-to-Fly** — Click any location in the sidebar list to smoothly fly to it on the map at zoom 17.
- **Permanent Labels** — Location names appear above markers when you zoom in (zoom 16+).
- **Get Directions** — Every marker popup includes a Google Maps directions link.
- **Data Table** — Full sortable, searchable, paginated table of all locations in the Data tab.
- **Quick Stats** — Total locations, number of categories, and most common type at a glance.
- **Marker Clustering** — Nearby markers cluster automatically; clusters break apart at zoom 16.
- **Reset View** — One click to clear all filters and return to the default map view.
- **About Page** — Color legend, data source info, and refresh instructions.
- **Responsive Design** — Works on desktop, tablet, and mobile.

## Live Demo

**https://mnakjp-steven-nanga.shinyapps.io/BlantyreExplorer/**

## Data Pipeline

Location data comes from two free sources (**no API keys required**):

1. **Overpass API** — Queries the OpenStreetMap database for all named POIs (restaurants, hospitals, police, markets, schools, banks, hotels, fuel stations, pharmacies, places of worship, libraries, bus stations, and more) within the Blantyre bounding box.
2. **Nominatim Geocoding** (via `tidygeocoder`) — Geocodes any manually-listed locations that may not yet be mapped in OSM.

The data pipeline (`data_prep.R`) combines both sources, deduplicates, validates coordinates, and saves to CSV. Run it anytime to refresh the data with the latest from OpenStreetMap.

## Installation

1. **Clone the Repository**:

    ```bash
    git clone https://github.com/Steven-Nanga/Blantyre-Explorer.git
    cd Blantyre-Explorer
    ```

2. **Install Required Packages**:

    ```r
    install.packages(c(
      "shiny", "leaflet", "dplyr", "readr", "bslib", "htmltools", "DT",
      "httr", "jsonlite", "tidygeocoder", "testthat"
    ))
    ```

3. **Fetch Location Data** (first time, or to refresh):

    ```r
    setwd("BlantyreExplorer")
    source("data_prep.R")
    ```

4. **Run the Application**:

    ```r
    shiny::runApp("BlantyreExplorer")
    ```

## Usage

| Action | How |
|--------|-----|
| **Search** | Type in the sidebar search bar to filter by name |
| **Filter by type** | Select a category from the dropdown |
| **Fly to a location** | Click any item in the sidebar list |
| **Get directions** | Click a marker, then click "Get Directions" in the popup |
| **Switch base map** | Use the layer control (top-right corner) |
| **Browse all data** | Switch to the **Data** tab for a sortable table |
| **Reset everything** | Click **Reset View** to clear filters and re-center |
| **Refresh data** | Run `source("data_prep.R")` from the `BlantyreExplorer/` folder |

## Running Tests

```r
testthat::test_dir("tests/testthat")
```

Tests cover:
- CSV file existence and structure
- Required columns validation
- Coordinate bounding box checks
- Duplicate detection
- Marker style helper functions

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Web Framework | [Shiny](https://shiny.posit.co/) |
| Maps | [Leaflet](https://rstudio.github.io/leaflet/) with Awesome Markers |
| UI Theme | [bslib](https://rstudio.github.io/bslib/) (Bootstrap 5, Flatly) |
| Data Table | [DT](https://rstudio.github.io/DT/) |
| Data Pipeline | [httr](https://httr.r-lib.org/) + [jsonlite](https://jeroen.r-universe.dev/jsonlite) + [tidygeocoder](https://jessecambon.github.io/tidygeocoder/) |
| Location Data | [OpenStreetMap](https://www.openstreetmap.org/) via [Overpass API](https://overpass-api.de/) |
| Hosting | [shinyapps.io](https://www.shinyapps.io/) |

## Project Structure

```
Blantyre-Explorer/
├── BlantyreExplorer/
│   ├── app.R                              # Shiny app (UI + server + styling)
│   ├── data_prep.R                        # Data pipeline (Overpass API + Nominatim)
│   └── blantyre_combined_locations.csv    # 360 locations (generated by data_prep.R)
├── tests/
│   ├── testthat.R                         # Test runner
│   └── testthat/
│       ├── test-data-validation.R         # Data integrity tests
│       └── test-app-helpers.R             # Marker style helper tests
├── Blantyre-Explorer.Rproj               # RStudio project file
├── .gitignore
└── README.md
```

## Contributing

Contributions are welcome! You can:

- **Add locations** — Edit the `manual_locations` list in `data_prep.R` and re-run the script.
- **Improve the UI** — The app uses `bslib` and custom CSS in `app.R`.
- **Fix bugs** — Open an issue or submit a pull request.
- **Improve OSM data** — Map new places in Blantyre on [openstreetmap.org](https://www.openstreetmap.org/) — they'll appear the next time `data_prep.R` is run.

Fork the repo and submit a pull request!

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [OpenStreetMap](https://www.openstreetmap.org/) — Community-maintained location data
- [Overpass API](https://overpass-api.de/) — Free OSM query engine
- [Shiny](https://shiny.posit.co/) — R web application framework
- [Leaflet](https://rstudio.github.io/leaflet/) — Interactive map library
- [Bootstrap 5](https://getbootstrap.com/) — UI framework (via bslib)
- [Font Awesome](https://fontawesome.com/) — Marker icons

## Contact

**Steven Nanga**
- GitHub: [Steven-Nanga](https://github.com/Steven-Nanga)
- Email: stephennanga97@gmail.com
