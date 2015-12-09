# TEST
# File:  ui.R

source('helpers.R')

shinyUI(fluidPage(
    titlePanel('PRECIOUS METAL PRICES'),
    selectInput('metal_id', 'Metal:', precious_metals),
    selectInput('metal_curr', 'Currency:', currency_list),
    selectInput('method', 'Method:', smooth_method),
    mainPanel(
        plotOutput('plot'),
        textOutput('text1')
    )
))