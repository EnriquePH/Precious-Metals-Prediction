#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: ui.R
#  (c) 2015 - Enrique Pérez Herrero
#  20/Dec/2015
#  GNU GENERAL PUBLIC LICENSE Version 2, June 1991
#  See licence: https://github.com/EnriquePH/Precious-Metals-Prediction
#  ----------------------------------------------------------------------------

library(shiny)
library(shinythemes)

source('helpers.R')

shinyUI(fluidPage(
    theme = shinytheme('united'),
    
    titlePanel('PRECIOUS METALS PRICE FORECAST'),
    sidebarLayout(
        sidebarPanel(
            selectInput('metal_id', 'Metal:', precious_metals),
            selectInput('metal_curr', 'Currency:', currency_list),
            wellPanel(
                helpText(textOutput('text.sd')),
                helpText(textOutput('text.ed'))
                ),
            width = 3
        ),
        mainPanel(tabsetPanel(
            tabPanel('Prices Plot',
                     radioButtons('method', 'Method:', smooth_method),
                     plotOutput('prices.plot')
            ),
            tabPanel('Prices Table', dataTableOutput('metals.table')),
            tabPanel('Forecast Plot', plotOutput('prediction.plot')),
            tabPanel('Forecast Table', dataTableOutput('table.arima')),
            tabPanel('Arima model', verbatimTextOutput('text.arima')),
            tabPanel('Differences Plot',
                     checkboxInput('chcklog', 'log10', value = TRUE),
                     plotOutput('diff.plot')
                     ),
            tabPanel('Residuals Plot', plotOutput('residuals.plot')),
            tabPanel('Help', includeMarkdown('help.Rmd'))
        ))
    )
))
