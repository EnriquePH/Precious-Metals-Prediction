#!/usr/bin/env Rscript
#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: run.R
#  Starts the Shiny app: Rscript run.R
#  Port/host are configurable via SHINY_PORT / SHINY_HOST env vars.
#  ----------------------------------------------------------------------------

port <- as.integer(Sys.getenv('SHINY_PORT', '3838'))
host <- Sys.getenv('SHINY_HOST', '127.0.0.1')

shiny::runApp(
    appDir = '.',
    port = port,
    host = host,
    launch.browser = FALSE
)
