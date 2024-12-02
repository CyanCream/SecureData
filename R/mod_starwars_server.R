library(dplyr)
library(arrow)

mod_starwars_server <- function(input, output, session) {
  ns <- session$ns

  starwars_data <- reactiveVal(NULL)
  homeworlds <- reactiveVal(NULL)
  processed_data <- reactiveVal(NULL)

  observe({
    pq_path <- paste0(getwd(), "/inst/extdata/starwars.parquet")

    if (!file.exists(pq_path)) {
      output$error_message <- renderText({
        paste("File does not exist:", pq_path)
      })
      return(NULL)
    }

    tryCatch({
      starwars2 <- open_dataset(sources = pq_path)
      starwars_data(starwars2)

      unique_homeworlds <- starwars2 |>
        distinct(homeworld) |>
        collect() |>
        pull(homeworld)

      homeworlds(unique_homeworlds)

      output$homeworld_selector <- renderUI({
        shinyWidgets::pickerInput(
          ns("homeworld"),
          label = "Select Homeworld(s):",
          choices = unique_homeworlds,
          selected = unique_homeworlds,
          multiple = TRUE,
          options = shinyWidgets::pickerOptions(
            `actions-box` = TRUE,
            `deselect-all-text` = "None",
            `select-all-text` = "All",
            dropupAuto = TRUE
          )
        )
      })

      output$error_message <- renderText("")
    }, error = function(e) {
      output$error_message <- renderText({
        paste("Failed to load dataset:", e$message)
      })
    })
  })

  observeEvent(input$process, {
    req(starwars_data(), input$homeworld, input$top_n, input$dates)

    start_date <- as.Date(input$dates[1])
    end_date <- as.Date(input$dates[2])

    filtered_data <- starwars_data() |>
      filter(as.Date(record_date) >= start_date & as.Date(record_date) <= end_date) |>
      filter(homeworld %in% input$homeworld) |>
      head(n = input$top_n) |>
      mutate(across(where(is.list), ~map_chr(., toString)))

    processed_data(filtered_data)

    output$head_table <- renderTable({
      req(processed_data())
      processed_data()
    })
  })

  output$download_data <- downloadHandler(
    filename = function() {
      paste("starwars_data", Sys.Date(), if (input$file_format == "CSV") ".csv" else ".xlsx", sep = "")
    },
    content = function(file) {
      req(processed_data())
      filtered_data <- processed_data()

      if (input$file_format == "CSV") {
        write.csv(filtered_data, file, row.names = FALSE)
      } else {
        writexl::write_xlsx(filtered_data, file)
      }
    }
  )
}
