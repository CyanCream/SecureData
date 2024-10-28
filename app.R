library(shiny)
library(shinydashboard)
library(arrow)
library(dplyr)
library(purrr)
library(writexl)
library(devtools)

options("nwarnings")

my_password = "8gB$z7T*9@LmW#Q3"

# Define the UI using dashboardPage
ui <- dashboardPage(
    dashboardHeader(title = "Star Wars Dataset Explorer"),
    dashboardSidebar(
        sidebarMenu(
            menuItem("Data Processing", tabName = "data", icon = icon("table")),
            passwordInput("password", "Password", value = "8gB$z7T*9@LmW#Q3"),
            numericInput("top_n", "Select Number of Rows to Display:", value = 5, min = 1, max = 100),
            actionButton("process", "Process Data"),
            actionButton("check_all", "Check All"),
            actionButton("uncheck_all", "Uncheck All"),
            uiOutput("homeworld_selector")
        )
    ),

    dashboardBody(
        tabItems(
            tabItem(
                tabName = "data",
                h3("Head of the Filtered Star Wars Dataset"),
                p("The table below shows the first few rows of the filtered Star Wars dataset based on your selections.
                   Use the 'Select Number of Rows to Display' option to adjust how many rows are shown."),
                p("Choose homeworld(s) from the sidebar to filter the data, and use the action buttons to select or deselect all homeworlds."),
                tableOutput("head_table"),
                verbatimTextOutput("error_message"),  # To display any error messages
                selectInput("file_format", "Format to Download:", choices = c("CSV", "Excel"), selected = "CSV"),
                downloadButton("download_data", "Download")
            )
        )
    )
)

# Define server logic for the Shiny app
server <- function(input, output, session) {
    starwars_data <- reactiveVal(NULL)
    homeworlds <- reactiveVal(NULL)

    # Initialize the error message output
    output$error_message <- renderText({ "" })

    observeEvent(input$process, {
        Sys.sleep(1)
        # Check if the password is correct
        if (input$password != my_password) {  # Replace 'your_password' with the actual password
            output$error_message <- renderText("Invalid password. Please try again.")
            return(NULL)  # Exit without processing data
        }

        # If the password is correct, proceed with data processing
        pq_path <- "/srv/shiny-server/PullData/data/starwars"  # Use an absolute path
        pq_path <- "C:/Users/yren/Documents/BiostatDeptSuppprt/EzraMorrison/Shinyapp_Pulldata/data/starwars"
        # Check if the directory exists and has the correct files
        if (!file.exists(pq_path)) {
            output$error_message <- renderText({
                paste("Directory does not exist:", pq_path)
            })
            return(NULL)
        }

        # Try to open the dataset and handle any potential errors
        tryCatch({
            starwars2 <- open_dataset(sources = pq_path)
            starwars_data(starwars2)

            # Get the list of unique homeworlds for checkboxes
            unique_homeworlds <- starwars2 |>
                distinct(homeworld) |>
                collect() |>
                pull(homeworld)

            homeworlds(unique_homeworlds)

            output$homeworld_selector <- renderUI({
                checkboxGroupInput("homeworld", "Select Homeworld(s):",
                                   choices = unique_homeworlds,
                                   selected = unique_homeworlds)  # Select all by default
            })

            output$error_message <- renderText("")  # Clear the error message if processing succeeds
        }, error = function(e) {
            output$error_message <- renderText({
                paste("Failed to load dataset:", e$message)
            })
        })
    })

    observeEvent(input$check_all, {
        updateCheckboxGroupInput(session, "homeworld", selected = homeworlds())
    })

    observeEvent(input$uncheck_all, {
        updateCheckboxGroupInput(session, "homeworld", selected = character(0))
    })

    output$head_table <- renderTable({
        req(starwars_data(), input$homeworld, input$top_n)

        starwars_data() |>
            filter(homeworld %in% input$homeworld) |>
            head(n = input$top_n) |>
            collect() |>
            mutate(across(where(is.list), ~map_chr(., toString)))
    })

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

# Run the application
shinyApp(ui = ui, server = server)
