library(shiny)
library(leaflet)
library(dplyr)
library(readr)
library(bslib)
library(htmltools)
library(DT)

# =============================================================================
# Data Loading & Validation
# =============================================================================

data <- tryCatch(
  read_csv("blantyre_combined_locations.csv", show_col_types = FALSE),
  error = function(e) {
    stop("Could not load 'blantyre_combined_locations.csv'. ",
         "Run data_prep.R first to fetch location data.")
  }
)

required_cols <- c("Name", "Latitude", "Longitude", "Type")
missing_cols <- setdiff(required_cols, names(data))
if (length(missing_cols) > 0) {
  stop("Missing columns in data: ", paste(missing_cols, collapse = ", "))
}

data <- data %>%
  filter(!is.na(Latitude), !is.na(Longitude)) %>%
  mutate(id = row_number())

map_center_lng <- mean(data$Longitude, na.rm = TRUE)
map_center_lat <- mean(data$Latitude, na.rm = TRUE)
all_types <- sort(unique(data$Type))

# =============================================================================
# Marker Styling
# =============================================================================

type_style <- list(
  "Restaurant"       = list(color = "red",       icon = "cutlery",        hex = "#d63e2a"),
  "Cafe"             = list(color = "orange",     icon = "coffee",         hex = "#f59630"),
  "Hospital"         = list(color = "blue",       icon = "plus-square",    hex = "#38aadd"),
  "Clinic"           = list(color = "cadetblue",  icon = "stethoscope",    hex = "#5f9ea0"),
  "Pharmacy"         = list(color = "purple",     icon = "medkit",         hex = "#d252b9"),
  "Police"           = list(color = "darkblue",   icon = "shield",         hex = "#003e6b"),
  "Market"           = list(color = "green",      icon = "shopping-basket", hex = "#72af26"),
  "Shopping Mall"    = list(color = "darkgreen",  icon = "shopping-bag",   hex = "#728224"),
  "Supermarket"      = list(color = "darkgreen",  icon = "shopping-cart",  hex = "#728224"),
  "Bank"             = list(color = "gray",       icon = "university",     hex = "#575757"),
  "School"           = list(color = "beige",      icon = "graduation-cap", hex = "#c5a75a"),
  "University"       = list(color = "beige",      icon = "graduation-cap", hex = "#c5a75a"),
  "Hotel"            = list(color = "pink",       icon = "bed",            hex = "#d5a6bd"),
  "Fuel Station"     = list(color = "black",      icon = "car",            hex = "#333333"),
  "Place of Worship" = list(color = "lightblue",  icon = "building",       hex = "#8bbddc"),
  "Library"          = list(color = "lightgray",  icon = "book",           hex = "#a3a3a3"),
  "Bus Station"      = list(color = "darkred",    icon = "bus",            hex = "#a23336"),
  "Police Station"   = list(color = "darkblue",   icon = "shield",         hex = "#003e6b"),
  "Police Post"      = list(color = "darkblue",   icon = "shield",         hex = "#003e6b"),
  "Restaurants"      = list(color = "red",        icon = "cutlery",        hex = "#d63e2a")
)

default_style <- list(color = "lightgray", icon = "map-marker", hex = "#a3a3a3")

get_style <- function(type) {
  if (type %in% names(type_style)) type_style[[type]] else default_style
}

get_marker_icons <- function(types) {
  colors <- unname(vapply(types, function(t) get_style(t)$color, character(1)))
  icons  <- unname(vapply(types, function(t) get_style(t)$icon,  character(1)))
  awesomeIcons(icon = icons, markerColor = colors, library = "fa")
}

# =============================================================================
# Custom CSS
# =============================================================================

app_css <- "
/* Sidebar refinements */
.location-list-container {
  max-height: calc(100vh - 420px);
  overflow-y: auto;
  border: 1px solid #e9ecef;
  border-radius: 6px;
}

.location-item {
  padding: 10px 12px;
  border-bottom: 1px solid #f0f0f0;
  cursor: pointer;
  transition: background 0.15s;
  display: flex;
  align-items: flex-start;
  gap: 10px;
}

.location-item:last-child { border-bottom: none; }
.location-item:hover { background: #f0f7ff; }

.location-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
  margin-top: 5px;
}

.location-name {
  font-weight: 500;
  font-size: 0.88em;
  color: #2c3e50;
  line-height: 1.3;
}

.location-type {
  font-size: 0.78em;
  color: #7f8c8d;
  margin-top: 1px;
}

/* Type badge chips */
.type-chip {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 10px;
  border-radius: 20px;
  font-size: 0.8em;
  color: white;
  cursor: default;
}

.type-chip .chip-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(255,255,255,0.6);
}

/* Stats cards */
.stat-card {
  text-align: center;
  padding: 16px 10px;
}

.stat-number {
  font-size: 2em;
  font-weight: 700;
  color: #2c3e50;
  line-height: 1;
}

.stat-label {
  font-size: 0.82em;
  color: #7f8c8d;
  margin-top: 4px;
}

/* Search box styling */
.search-wrapper {
  position: relative;
}

.search-wrapper .form-control {
  padding-left: 36px;
  border-radius: 20px;
  border: 1px solid #dfe6e9;
}

.search-wrapper .form-control:focus {
  border-color: #2ecc71;
  box-shadow: 0 0 0 0.2rem rgba(46,204,113,0.15);
}

.search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #b2bec3;
  font-size: 0.9em;
  pointer-events: none;
  z-index: 3;
}

/* Sidebar section labels */
.sidebar-section-label {
  font-size: 0.75em;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #95a5a6;
  margin-bottom: 6px;
  margin-top: 14px;
}

/* Better navbar */
.navbar { box-shadow: 0 1px 4px rgba(0,0,0,0.08); }

/* Map popup */
.leaflet-popup-content { margin: 10px 14px; }

.popup-title {
  font-size: 1.05em;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 4px;
}

.popup-type {
  font-size: 0.85em;
  color: #7f8c8d;
  margin-bottom: 8px;
}

.popup-directions {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 0.82em;
  color: #3498db;
  text-decoration: none;
  padding: 4px 10px;
  border: 1px solid #3498db;
  border-radius: 4px;
  transition: all 0.15s;
}

.popup-directions:hover {
  background: #3498db;
  color: white;
}

/* Reset button */
.btn-reset {
  font-size: 0.82em;
  padding: 4px 12px;
  border-radius: 20px;
}

/* About page */
.about-hero {
  background: linear-gradient(135deg, #1abc9c 0%, #2c3e50 100%);
  color: white;
  padding: 40px;
  border-radius: 12px;
  margin-bottom: 24px;
}

.about-hero h2 { margin: 0 0 8px; font-weight: 700; }
.about-hero p { margin: 0; opacity: 0.9; font-size: 1.05em; }

/* No results message */
.no-results {
  text-align: center;
  padding: 30px 15px;
  color: #95a5a6;
}

.no-results .icon { font-size: 2em; margin-bottom: 8px; }
"

# =============================================================================
# UI
# =============================================================================

ui <- page_navbar(
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#2c3e50",
    success = "#1abc9c",
    "font-size-base" = "0.92rem"
  ),
  title = tags$span(
    style = "display: inline-flex; align-items: center; gap: 8px; font-weight: 600;",
    tags$span(style = "font-size: 1.2em;", "\U0001F30D"),
    "Blantyre Explorer"
  ),
  header = tags$head(
    tags$style(HTML(app_css)),
    tags$meta(name = "description", content = "Explore places in Blantyre, Malawi — restaurants, hospitals, markets, and more."),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")
  ),

  # --- Map Tab ---------------------------------------------------------------
  nav_panel(
    title = "Map",
    icon = icon("map-location-dot"),
    layout_sidebar(
      sidebar = sidebar(
        width = 340,
        title = NULL,

        # Search
        tags$div(
          class = "sidebar-section-label", "Search"
        ),
        tags$div(
          class = "search-wrapper",
          tags$span(class = "search-icon", icon("magnifying-glass")),
          textInput("search", label = NULL, placeholder = "Search locations...")
        ),

        # Filter by type
        tags$div(
          class = "sidebar-section-label", "Filter by Type"
        ),
        selectInput("type", label = NULL,
                    choices = c("All Types" = "All", setNames(all_types, all_types)),
                    selected = "All"),

        # Location count + reset
        tags$div(
          style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;",
          tags$span(
            style = "font-size: 0.85em; color: #7f8c8d;",
            textOutput("location_count", inline = TRUE)
          ),
          actionButton("reset_view", "Reset View",
                       class = "btn btn-outline-secondary btn-reset btn-sm",
                       icon = icon("arrows-to-dot"))
        ),

        # Location list
        tags$div(
          class = "sidebar-section-label", "Locations"
        ),
        uiOutput("location_list")
      ),
      leafletOutput("map", height = "calc(100vh - 80px)")
    )
  ),

  # --- Data Tab --------------------------------------------------------------
  nav_panel(
    title = "Data",
    icon = icon("table"),
    layout_sidebar(
      sidebar = sidebar(
        width = 260,
        title = "Data Explorer",
        tags$p(
          style = "font-size: 0.85em; color: #7f8c8d;",
          "Browse and search all locations in the dataset. Click a row to fly to it on the map."
        ),
        tags$div(
          class = "sidebar-section-label", "Quick Stats"
        ),
        uiOutput("stats_cards")
      ),
      card(
        card_body(
          DTOutput("data_table")
        )
      )
    )
  ),

  # --- About Tab -------------------------------------------------------------
  nav_panel(
    title = "About",
    icon = icon("circle-info"),
    layout_column_wrap(
      width = 1,
      fill = FALSE,
      # Hero banner
      tags$div(
        class = "about-hero",
        tags$h2("Blantyre Explorer"),
        tags$p("Discover places across Blantyre, Malawi \u2014 the warm heart of Africa's commercial hub.")
      )
    ),
    layout_column_wrap(
      width = 1 / 3,
      fill = FALSE,
      heights_equal = "row",
      card(
        card_header(tags$span(icon("map-location-dot"), " Interactive Map")),
        card_body(
          tags$p("Browse an interactive map with color-coded markers for every type of location.",
                 "Filter by category, search by name, and click any location to fly right to it.")
        )
      ),
      card(
        card_header(tags$span(icon("database"), " OpenStreetMap Data")),
        card_body(
          tags$p("All locations are sourced from ",
                 tags$a("OpenStreetMap", href = "https://www.openstreetmap.org", target = "_blank"),
                 " via the Overpass API, giving you precise, community-maintained GPS coordinates.",
                 " Additional locations are geocoded via Nominatim.")
        )
      ),
      card(
        card_header(tags$span(icon("code"), " Open Source")),
        card_body(
          tags$p("This project is open source and contributions are welcome.",
                 " Fork the repo, add locations, or improve the code."),
          tags$a(
            class = "btn btn-outline-dark btn-sm",
            href = "https://github.com/Steven-Nanga/Blantyre-Explorer",
            target = "_blank",
            icon("github"), " View on GitHub"
          )
        )
      )
    ),
    layout_column_wrap(
      width = 1 / 2,
      fill = FALSE,
      card(
        card_header("Legend"),
        card_body(
          tags$div(
            style = "display: flex; flex-wrap: wrap; gap: 6px;",
            lapply(all_types, function(type) {
              s <- get_style(type)
              tags$span(
                class = "type-chip",
                style = sprintf("background: %s;", s$hex),
                tags$span(class = "chip-dot"),
                type
              )
            })
          )
        )
      ),
      card(
        card_header("How to Refresh Data"),
        card_body(
          tags$p("To update the location database with the latest from OpenStreetMap:"),
          tags$pre(
            style = "background: #f8f9fa; padding: 12px; border-radius: 6px; font-size: 0.88em;",
            "# In RStudio, from the BlantyreExplorer/ folder:\nsource(\"data_prep.R\")"
          ),
          tags$p(
            style = "font-size: 0.85em; color: #7f8c8d;",
            "Requires: httr, jsonlite, tidygeocoder (all free, no API keys)."
          )
        )
      )
    )
  ),

  nav_spacer(),
  nav_item(
    tags$a(
      style = "display: flex; align-items: center; gap: 5px; color: inherit; text-decoration: none;",
      icon("github"),
      "Source",
      href = "https://github.com/Steven-Nanga/Blantyre-Explorer",
      target = "_blank",
      rel = "noopener noreferrer",
      `aria-label` = "View source code on GitHub"
    )
  )
)

# =============================================================================
# Server
# =============================================================================

server <- function(input, output, session) {

  # --- Filtered + searched data ------------------------------------------------
  filtered_data <- reactive({
    df <- data

    if (input$type != "All") {
      df <- df %>% filter(Type == input$type)
    }

    search_term <- trimws(input$search)
    if (nchar(search_term) > 0) {
      df <- df %>% filter(grepl(search_term, Name, ignore.case = TRUE))
    }

    df
  })

  # --- Location count ----------------------------------------------------------
  output$location_count <- renderText({
    n <- nrow(filtered_data())
    total <- nrow(data)
    sprintf("%d of %d places", n, total)
  })

  # --- Location list in sidebar ------------------------------------------------
  output$location_list <- renderUI({
    df <- filtered_data()

    if (nrow(df) == 0) {
      return(tags$div(
        class = "no-results",
        tags$div(class = "icon", icon("magnifying-glass")),
        tags$p("No locations found."),
        tags$small("Try a different search or filter.")
      ))
    }

    tags$div(
      class = "location-list-container",
      role = "list",
      `aria-label` = "Location list",
      lapply(seq_len(nrow(df)), function(i) {
        row <- df[i, ]
        s <- get_style(row$Type)
        tags$div(
          class = "location-item",
          role = "listitem",
          `data-id` = row$id,
          onclick = sprintf(
            "Shiny.setInputValue('fly_to', {id: %d, lat: %f, lng: %f, nonce: Math.random()});",
            row$id, row$Latitude, row$Longitude
          ),
          tags$span(class = "location-dot", style = sprintf("background: %s;", s$hex)),
          tags$div(
            tags$div(class = "location-name", htmlEscape(row$Name)),
            tags$div(class = "location-type", htmlEscape(row$Type))
          )
        )
      })
    )
  })

  # --- Stats cards for Data tab ------------------------------------------------
  output$stats_cards <- renderUI({
    type_counts <- data %>% count(Type, sort = TRUE)
    top_type <- type_counts$Type[1]
    top_count <- type_counts$n[1]

    tags$div(
      style = "display: flex; flex-direction: column; gap: 8px;",
      card(
        class = "stat-card",
        tags$div(class = "stat-number", nrow(data)),
        tags$div(class = "stat-label", "Total Locations")
      ),
      card(
        class = "stat-card",
        tags$div(class = "stat-number", length(all_types)),
        tags$div(class = "stat-label", "Categories")
      ),
      card(
        class = "stat-card",
        tags$div(class = "stat-number", top_count),
        tags$div(class = "stat-label", paste("Most:", top_type))
      )
    )
  })

  # --- Render the base map once ------------------------------------------------
  output$map <- renderLeaflet({
    leaflet(options = leafletOptions(zoomControl = TRUE)) %>%
      addProviderTiles(providers$CartoDB.Positron, group = "Light") %>%
      addProviderTiles(providers$OpenStreetMap, group = "Streets") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
      addLayersControl(
        baseGroups = c("Light", "Streets", "Satellite"),
        options = layersControlOptions(collapsed = TRUE)
      ) %>%
      addScaleBar(position = "bottomleft") %>%
      setView(lng = map_center_lng, lat = map_center_lat, zoom = 13) %>%
      addEasyButton(
        easyButton(
          icon = "fa-crosshairs",
          title = "Reset View",
          onClick = JS(sprintf(
            "function(btn, map){ map.setView([%f, %f], 13); }",
            map_center_lat, map_center_lng
          ))
        )
      )
  })

  # --- Update markers via proxy ------------------------------------------------
  observe({
    df <- filtered_data()

    proxy <- leafletProxy("map") %>%
      clearMarkerClusters() %>%
      clearMarkers()

    if (nrow(df) > 0) {
      icons <- get_marker_icons(df$Type)

      popups <- mapply(function(name, type, lat, lng) {
        gmaps_url <- sprintf(
          "https://www.google.com/maps/dir/?api=1&destination=%f,%f", lat, lng
        )
        paste0(
          "<div style='min-width: 180px;'>",
          "<div class='popup-title'>", htmlEscape(name), "</div>",
          "<div class='popup-type'>", htmlEscape(type), "</div>",
          "<a class='popup-directions' href='", gmaps_url, "' ",
          "target='_blank' rel='noopener noreferrer'>",
          "<i class='fa fa-location-arrow'></i> Get Directions</a>",
          "</div>"
        )
      }, df$Name, df$Type, df$Latitude, df$Longitude, SIMPLIFY = TRUE, USE.NAMES = FALSE)

      labels <- lapply(df$Name, function(nm) {
        htmltools::HTML(sprintf(
          "<span style='font-size:12px; font-weight:500; text-shadow: 1px 1px 2px white, -1px -1px 2px white;'>%s</span>",
          htmlEscape(nm)
        ))
      })

      proxy %>%
        addAwesomeMarkers(
          data = df,
          lng = ~Longitude, lat = ~Latitude,
          icon = icons,
          layerId = ~id,
          popup = popups,
          label = labels,
          labelOptions = labelOptions(
            permanent = TRUE,
            direction = "top",
            offset = c(0, -12),
            style = list(
              "background" = "transparent",
              "border" = "none",
              "box-shadow" = "none",
              "font-size" = "11px"
            )
          ),
          clusterOptions = markerClusterOptions(
            spiderfyOnMaxZoom = TRUE,
            showCoverageOnHover = FALSE,
            zoomToBoundsOnClick = TRUE,
            disableClusteringAtZoom = 16
          )
        )
    }
  })

  # --- Fly to location when clicking sidebar item ------------------------------
  observeEvent(input$fly_to, {
    loc <- input$fly_to
    leafletProxy("map") %>%
      flyTo(lng = loc$lng, lat = loc$lat, zoom = 17)
  })

  # --- Reset view button -------------------------------------------------------
  observeEvent(input$reset_view, {
    updateTextInput(session, "search", value = "")
    updateSelectInput(session, "type", selected = "All")
    leafletProxy("map") %>%
      flyTo(lng = map_center_lng, lat = map_center_lat, zoom = 13)
  })

  # --- Fly to marker when clicked on map (open popup) --------------------------
  observeEvent(input$map_marker_click, {
    click <- input$map_marker_click
    if (!is.null(click$id)) {
      leafletProxy("map") %>%
        flyTo(lng = click$lng, lat = click$lat, zoom = 17)
    }
  })

  # --- Data table --------------------------------------------------------------
  output$data_table <- renderDT({
    display_data <- data %>%
      select(Name, Type, Latitude, Longitude) %>%
      mutate(
        Latitude = round(Latitude, 6),
        Longitude = round(Longitude, 6)
      )

    datatable(
      display_data,
      selection = "single",
      rownames = FALSE,
      filter = "top",
      options = list(
        pageLength = 20,
        dom = "frtip",
        language = list(
          search = "Search all:",
          emptyTable = "No locations found."
        ),
        columnDefs = list(
          list(className = "dt-left", targets = c(0, 1)),
          list(className = "dt-right", targets = c(2, 3))
        )
      ),
      class = "display compact stripe hover"
    )
  })

  # --- Click table row to fly to on map ----------------------------------------
  observeEvent(input$data_table_rows_selected, {
    row_idx <- input$data_table_rows_selected
    if (length(row_idx) > 0) {
      loc <- data[row_idx, ]
      updateNavbarPage(session, inputId = ".navbar", selected = "Map")
      leafletProxy("map") %>%
        flyTo(lng = loc$Longitude, lat = loc$Latitude, zoom = 17)
    }
  })
}

# =============================================================================
# Launch
# =============================================================================

shinyApp(ui = ui, server = server)
