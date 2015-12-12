#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: ui.R
#  Enrique Pérez Herrero
#  11/Dec/2015
#  ----------------------------------------------------------------------------


shinyUI(fluidPage(
    theme = shinytheme("united"),
    
    titlePanel("PRECIOUS METALS PRICE FORECAST"),
    sidebarLayout(
        sidebarPanel(
            selectInput('metal_id', 'Metal:', precious_metals),
            selectInput('metal_curr', 'Currency:',
                        currency_list),
            selectInput('method', 'Method:', smooth_method),
            helpText(textOutput('text.sd')),
            helpText(textOutput('text.ed')),
            width = 3
        ),
        mainPanel(tabsetPanel(
            tabPanel("Prices Plot", plotOutput('prices.plot')),
            tabPanel("Forecast Plot", plotOutput('prediction.plot')),
            tabPanel("Prices Table", dataTableOutput('metals.table'))
        ))
    )
))
