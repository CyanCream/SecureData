# library(shiny)
# library(shinydashboard)
#
# # Source the module files
# source("R/mod_starwars_ui.R")
# source("R/mod_starwars_server.R")
#
# # Define the UI
# app_ui <- function() {
#     fluidPage(
#         mod_starwars_ui("starwars")
#     )
# }
#
# # Define the server
# app_server <- function(input, output, session) {
#     callModule(mod_starwars_server, "starwars")
# }
#
# # Run the Shiny App
# shinyApp(ui = app_ui, server = app_server)


1# Launch the ShinyApp (Do not remove this comment)
# To deploy, run: rsconnect::deployApp()
# Or use the blue button on top of this file
options(shiny.reactlog = TRUE)

pkgload::load_all(export_all = FALSE,helpers = FALSE,attach_testthat = FALSE)
options( "golem.app.prod" = TRUE)
SecureData::run_app() # add parameters here (if any)
