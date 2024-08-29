# Blantyre Explorer

Blantyre Explorer is an interactive web application built using R and Shiny that allows users to explore various locations in Blantyre, Malawi. The app features a map with customizable markers that represent different types of locations, allowing users to filter and visualize data based on their interests.

## Features

- **Interactive Map**: Explore locations in Blantyre with an easy-to-use map interface.
- **Customizable Markers**: Markers on the map change color and icon based on the type of location.
- **Filters**: Users can filter locations by type to focus on specific categories.
- **Responsive Design**: The app is responsive and works well on both desktop and mobile devices.

## Installation

If you want to run this app locally, follow these steps:

1. **Clone the Repository**:
    ```bash
    git clone https://github.com/Steven-Nanga/Blantyre-Explorer.git
    ```
   
2. **Navigate to the Project Directory**:
    ```bash
    cd Blantyre-Explorer
    ```

3. **Install Required Packages**:
    Ensure you have R installed on your machine, then run:
    ```r
    if (!require(shiny)) install.packages("shiny")
    if (!require(leaflet)) install.packages("leaflet")
    if (!require(dplyr)) install.packages("dplyr")
    if (!require(readr)) install.packages("readr")
    if (!require(bslib)) install.packages("bslib")
    ```

4. **Run the Application**:
    ```r
    shiny::runApp()
    ```

## Usage

- **Map Navigation**: Pan and zoom the map to explore different areas of Blantyre.
- **Filtering Locations**: Use the sidebar filter to select the type of location you want to view on the map.
- **Marker Interaction**: Click on markers to view more information about the location.

## Deployment

This application is deployed and can be accessed online. Visit the deployed app using the following link:

[Blantyre Explorer - Deployed Application](https://mnakjp-steven-nanga.shinyapps.io/BlantyreExplorer/)

## Data Source

The data used in this application is stored in a CSV file named `blantyre_combined_locations.csv`. The file contains information about various locations in Blantyre, including their names, types, and coordinates.

## Contributing

If you'd like to contribute to this project, feel free to fork the repository and submit a pull request. All contributions are welcome!

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Acknowledgements

- **Shiny**: [Shiny by RStudio](https://shiny.rstudio.com/)
- **Leaflet**: [Leaflet for R](https://rstudio.github.io/leaflet/)
- **Bootstrap**: [Bootstrap 5](https://getbootstrap.com/)

## Contact

For any questions or suggestions, please reach out to:

**Steven Nanga**  
- GitHub: [Steven-Nanga](https://github.com/Steven-Nanga)
- Email: stephennanga97@gmail.com
