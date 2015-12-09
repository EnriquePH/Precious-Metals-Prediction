# TEST
# File:  server.R

library(quantmod)
library(ggplot2)

source('helpers.R')

metals.df <- getPreciousMetals(precious_metals, currency_list)

shinyServer(function(input, output) {
    
    output$plot <- renderPlot({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        ggplot(data = metals.df , aes_string('date', tag)) +
            geom_line() +
            stat_smooth(method = input$method, formula = y ~ x, size = 1) +
            xlab('')

    })
})