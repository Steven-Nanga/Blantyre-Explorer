# Install and load required packages
if (!require(shiny)) install.packages("shiny")
if (!require(leaflet)) install.packages("leaflet")
if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")
if (!require(bslib)) install.packages("bslib")

library(shiny)
library(leaflet)
library(dplyr)
library(readr)
library(bslib)

# Read the data
data <- read_csv("blantyre_combined_locations.csv")

# Define UI
ui <- page_navbar(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  title = "Blantyre Explorer",
  nav_panel(
    "Map",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        selectInput("type", "Select Type:", 
                    choices = c("All", unique(data$Type)),
                    selected = "All")
      ),
      leafletOutput("map", height = "calc(100vh - 150px)")
    )
  ),
  nav_spacer(),
  nav_item(
    tags$a(
      icon("github"), 
      "Source Code", 
      href = "https://github.com/Steven-Nanga/Blantyre-Explorer",
    
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  # Filter data based on selected type
  filtered_data <- reactive({
    if (input$type == "All") {
      data
    } else {
      data %>% filter(Type == input$type)
    }
  })
  
  # Create the map
  output$map <- renderLeaflet({
    leaflet(filtered_data()) %>%
      addTiles() %>%
      addMarkers(
        ~Longitude, ~Latitude,
        popup = ~paste("<strong>", Name, "</strong><br>", Type),
        label = ~Name,
        labelOptions = labelOptions(permanent = TRUE, direction = "top", offset = c(0, -10)),
        clusterOptions = markerClusterOptions()
      ) %>%
      setView(lng = mean(data$Longitude), lat = mean(data$Latitude), zoom = 13)
  })
}

# Run the application 
shinyApp(ui = ui, server = server)