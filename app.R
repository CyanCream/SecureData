# Load necessary libraries
library(shiny)
library(shinydashboard)

# UI Module for Star Wars data processing and filtering
mod_starwars_ui <- function(id) {
    ns <- NS(id)  # Create namespace for module inputs/outputs

    dashboardPage(
        dashboardHeader(title = "Star Wars Dataset Explorer"),
        dashboardSidebar(
            sidebarMenu(
                menuItem("Data Processing", tabName = "data", icon = icon("table")),
                numericInput(ns("top_n"), "Select Number of Rows to Display:", value = 5, min = 1, max = 100),
                actionButton(ns("process"), "Process Data"),
                actionButton(ns("check_all"), "Check All"),
                actionButton(ns("uncheck_all"), "Uncheck All"),
                uiOutput(ns("homeworld_selector"))
            )
        ),

        dashboardBody(
            tabItems(
                tabItem(
                    tabName = "data",
                    h3("Head of the Filtered Star Wars Dataset"),
                    p("The table below shows the first few rows of the filtered Star Wars dataset based on your selections."),
                    p("Choose homeworld(s) from the sidebar to filter the data, and use the action buttons to select or deselect all homeworlds."),
                    tableOutput(ns("head_table")),
                    verbatimTextOutput(ns("error_message")),  # To display any error messages
                    selectInput(ns("file_format"), "Format to Download:", choices = c("CSV", "Excel"), selected = "CSV"),
                    downloadButton(ns("download_data"), "Download")
                )
            )
        )
    )
}




# Server Module for Star Wars data processing and filtering
mod_starwars_server <- function(input, output, session) {
    # Reactive values for storing data and unique homeworlds
    starwars_data <- reactiveVal(NULL)
    homeworlds <- reactiveVal(NULL)

    # Initialize error message output
    output$error_message <- renderText({ "" })

    # Process data on button click
    observeEvent(input$process, {
        pq_path <- "C:/Users/yren/Documents/github/SecureData/data_arrow/starwars"

        if (!file.exists(pq_path)) {
            output$error_message <- renderText({
                paste("Directory does not exist:", pq_path)
            })
            return(NULL)
        }

        # Attempt to load and process the dataset
        tryCatch({
            starwars2 <- open_dataset(sources = pq_path)
            starwars_data(starwars2)

            # Extract unique homeworlds
            unique_homeworlds <- starwars2 |>
                distinct(homeworld) |>
                collect() |>
                pull(homeworld)

            homeworlds(unique_homeworlds)

            output$homeworld_selector <- renderUI({
                checkboxGroupInput(ns("homeworld"), "Select Homeworld(s):",
                                   choices = unique_homeworlds,
                                   selected = unique_homeworlds)  # Select all by default
            })

            output$error_message <- renderText("")  # Clear error message on success
        }, error = function(e) {
            output$error_message <- renderText({
                paste("Failed to load dataset:", e$message)
            })
        })
    })

    # Check all homeworlds
    observeEvent(input$check_all, {
        updateCheckboxGroupInput(session, "homeworld", selected = homeworlds())
    })

    # Uncheck all homeworlds
    observeEvent(input$uncheck_all, {
        updateCheckboxGroupInput(session, "homeworld", selected = character(0))
    })

    # Render table of filtered data
    output$head_table <- renderTable({
        req(starwars_data(), input$homeworld, input$top_n)

        starwars_data() |>
            filter(homeworld %in% input$homeworld) |>
            head(n = input$top_n) |>
            collect() |>
            mutate(across(where(is.list), ~map_chr(., toString)))
    })

    # Handle data download
    output$download_data <- downloadHandler(
        filename = function() {
            paste("starwars_data", Sys.Date(), if (input$file_format == "CSV") ".csv" else ".xlsx", sep = "")
        },
        content = function(file) {
            filtered_data <- starwars_data() |>
                filter(homeworld %in% input$homeworld) |>
                collect()

            if (input$file_format == "CSV") {
                write.csv(filtered_data, file, row.names = FALSE)
            } else {
                writexl::write_xlsx(filtered_data, file)
            }
        }
    )
}



# Main App UI
app_ui <- function() {
    fluidPage(
        mod_starwars_ui("starwars")
    )
}

# Main App Server
app_server <- function(input, output, session) {
    callModule(mod_starwars_server, "starwars")
}

# Run the Shiny App
shinyApp(ui = app_ui, server = app_server)
