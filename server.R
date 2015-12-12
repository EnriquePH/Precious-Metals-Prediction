#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: server.R
#  Enrique Pérez Herrero
#  11/Dec/2015
#  ----------------------------------------------------------------------------

source('helpers.R')

metals.df <- getPreciousMetals(precious_metals, currency_list)

start.date <- head(metals.df$date, 1)
end.date <- tail(metals.df$date, 1)

shinyServer(function(input, output) {
    output$prices.plot <- renderPlot({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        ggplot(data = metals.df , aes_string('date', tag)) +
            geom_line() +
            stat_smooth(
                method = input$method, formula = y ~ x, size = 1
            ) +
            xlab('')
        
    })
    
    output$prediction.plot <- renderPlot({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        selected.metal <- ts(zoo(metals.df[tag],
                                 order.by = metals.df$date))
        arima.fit <- auto.arima(selected.metal,
                                approximation = FALSE,
                                trace = FALSE)
        pred <- forecast(arima.fit, h = 365)
        arimaForecastPlot(pred, start = start.date, ylabel = tag)
        
    })
    
    output$text.sd <- renderText({
        paste0("Start Date: ",
               start.date <- head(metals.df$date, 1))
    })
    
    output$text.ed <- renderText({
        paste0("End Date: ",
               end.date <- tail(metals.df$date, 1))
    })
    
    output$metals.table <- renderDataTable({
        metals.df[, grepl(paste0(input$metal_id, '|date'), names(metals.df))]
    })
    
})