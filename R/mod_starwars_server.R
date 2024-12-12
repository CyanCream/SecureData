mod_starwars_server <- function(input, output, session) {
  ns <- session$ns

  starwars_data <- reactiveVal(NULL)
  filtered_data <- reactiveVal(NULL)
  homeworlds <- reactiveVal(NULL)
  processed_data <- reactiveVal(NULL)

  # Load and filter dataset based on date range
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

      output$error_message <- renderText("")
    }, error = function(e) {
      output$error_message <- renderText({
        paste("Failed to load dataset:", e$message)
      })
    })
  })

  # Filter by date range and update homeworlds
  observe({
    req(starwars_data(), input$dates)

    start_date <- as.Date(input$dates[1])
    end_date <- as.Date(input$dates[2])

    date_filtered_data <- starwars_data() |>
      filter(as.Date(record_date) >= start_date & as.Date(record_date) <= end_date) |>
      collect()

    filtered_data(date_filtered_data)

    unique_homeworlds <- date_filtered_data |>
      distinct(homeworld) |>
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
  })

  # Process the filtered data and generate outputs
  observeEvent(input$process, {
    # Ensure filtered data exists and top_n is valid
    req(filtered_data(), input$top_n)

    # Check if homeworld is selected
    if (is.null(input$homeworld)) {
      output$head_table <- DT::renderDataTable({
        DT::datatable(data.frame(Message = "No data selected"), options = list(dom = "t"))
      })
      output$bar_plot <- renderPlot({
        plot.new()
        title(main = "No data selected")
      })
      return()  # Exit the observer early if no homeworlds are selected
    }

    # Process the filtered data
    filtered_homeworld_data <- filtered_data() |>
      filter(homeworld %in% input$homeworld) |>
      mutate(across(where(is.list), ~map_chr(., toString)))

    if (nrow(filtered_homeworld_data) == 0) {
      processed_data(NULL)
    } else {
      processed_data(filtered_homeworld_data)
    }

    # Update outputs
    output$head_table <- DT::renderDataTable({
      req(processed_data())
      DT::datatable(
        processed_data(),
        options = list(
          pageLength = input$top_n,
          autoWidth = TRUE,
          searchHighlight = TRUE,
          scrollX = TRUE
        )
      )
    })

    output$bar_plot <- renderPlot({
      req(processed_data())
      ggplot(processed_data(), aes(x = homeworld)) +
        geom_bar(fill = "steelblue") +
        theme_minimal() +
        labs(
          title = "Count of Characters by Homeworld",
          x = "Homeworld",
          y = "Count"
        ) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
    })
  })


  # Download handler
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
