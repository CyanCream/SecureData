#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny shinydashboard dplyr arrow
#' @importFrom shinyWidgets pickerInput
#' @noRd

mod_starwars_ui <- function(id) {
  ns <- NS(id)
  start_date <- if_else(
    golem::app_prod(),
    lubridate::ymd("2022-08-01"),
    lubridate::ymd("2022-11-01")
  )
  end_date <- lubridate::today()

  dashboardPage(
    dashboardHeader(title = "Star Wars Dataset Explorer"),
    dashboardSidebar(
      sidebarMenu(
        menuItem("Data Processing", tabName = "data", icon = icon("table")),
        menuItem("Bar Plot", tabName = "plot", icon = icon("chart-bar")),
        numericInput(ns("top_n"), "Select Number of Rows to Display:", value = 5, min = 1, max = 100),
        actionButton(ns("process"), "Apply Filter"),
        dateRangeInput(
          ns("dates"),
          label = "Record Creation Dates to Include:",
          start = start_date,
          end = end_date
        ),
        uiOutput(ns("homeworld_selector"))
      )
    ),
    dashboardBody(
      tabItems(
        # Page for Data Processing
        tabItem(
          tabName = "data",
          h3("Filtered Star Wars Dataset"),
          p("Choose homeworld(s) from the sidebar, then click 'Apply Filter' to view filtered results."),
          DT::dataTableOutput(ns("head_table")),
          verbatimTextOutput(ns("error_message")),
          selectInput(ns("file_format"), "Format to Download:", choices = c("CSV", "Excel"), selected = "CSV"),
          downloadButton(ns("download_data"), "Download")
        ),
        # Page for Bar Plot
        tabItem(
          tabName = "plot",
          h3("Filtered Star Wars Dataset - Frequency Bar Plot"),
          p("Choose homeworld(s) from the sidebar, then click 'Apply Filter' to view the bar plot with the filtered results."),
          p("This figure displays the frequency of characters' homeworlds within the selected range."),
          plotOutput(ns("bar_plot"))
        )
      )
    )
  )
}
