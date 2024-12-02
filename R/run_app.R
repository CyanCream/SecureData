#' Run the Shiny Application
#'
#' This function launches the Shiny application.
#'
#' @export
#' @importFrom shiny shinyApp
#' @importFrom shinydashboard dashboardPage
#' @importFrom golem with_golem_options
#'
run_app <- function() {
  shinyApp(
    ui = mod_starwars_ui("starwars"),
    server = function(input, output, session) {
      callModule(mod_starwars_server, "starwars")
    }
  )
}
