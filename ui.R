#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: ui.R
#  Enrique Pérez Herrero
#  11/Dec/2015
#  ----------------------------------------------------------------------------

library(shinythemes)

source('helpers.R')

shinyUI(fluidPage(theme = shinytheme("united"),
    navbarPage("Menu",
               tabPanel("Prices Plot",
                        sidebarPanel(
                            titlePanel('PRECIOUS METAL PRICES'),
                            selectInput('metal_id', 'Metal:', precious_metals),
                            selectInput('metal_curr', 'Currency:',
                                        currency_list),
                            selectInput('method', 'Method:', smooth_method),
                            helpText(textOutput('text.sd')),
                            helpText(textOutput('text.ed'))
                        ),
                        mainPanel(
                            plotOutput('prices.plot')
                            )
                        ),
               tabPanel("Forecast Plot",
                        sidebarPanel(
                            titlePanel('PRECIOUS METAL ARIMA FORECAST'),
                            selectInput('metal_id1', 'Metal:', precious_metals),
                            selectInput('metal_curr1', 'Currency:',
                                        currency_list)
                        ),
                        mainPanel(
                            plotOutput('prediction.plot')
                            )
                        )
    )
))