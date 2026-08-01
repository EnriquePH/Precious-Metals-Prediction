#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: ui.R
#  (c) 2015 - Enrique Pérez Herrero
#  20/Dec/2015 # nolint: commented_code_linter.
#  GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
#  ----------------------------------------------------------------------------
#
#  Shiny UI: a metal + currency picker feeds a tag like "XAU.USD" (built in
#  server.R) that selects one column of the wide `metals.df` data frame for
#  every tab below.

library(shiny)
library(shinythemes)
library(DT)

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
                plotlyOutput('prices.plot')
            ),
            tabPanel('Prices Table', DTOutput('metals.table')),
            tabPanel('Forecast Plot', plotlyOutput('prediction.plot')),
            tabPanel('Forecast Table', DTOutput('table.arima')),
            tabPanel('Arima model', verbatimTextOutput('text.arima')),
            tabPanel('Differences Plot',
                checkboxInput('chcklog', 'log10', value = TRUE),
                plotlyOutput('diff.plot')
            ),
            tabPanel('Residuals Plot', plotlyOutput('residuals.plot')),
            tabPanel('Help', includeMarkdown('help.Rmd'))
        ))
    )
))
