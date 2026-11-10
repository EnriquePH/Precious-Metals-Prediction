#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: server.R
#  (c) 2015 - Enrique Pérez Herrero
#  20/Dec/2015 # nolint: commented_code_linter.
#  GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
#  ----------------------------------------------------------------------------
#
#  Shiny server logic. Metal price history (Yahoo Finance futures) is downloaded once, at app start
#  (not per-session), into `metals.df`; each output below subsets that
#  data frame using the currently selected metal/currency `tag`
#  (e.g. "XAU.USD") and either plots it directly or fits an ARIMA model
#  with `auto.arima()` first.

source('helpers.R')

metals.df <- getPreciousMetals(precious_metals, currency_list)

start.date <- head(metals.df$date, 1)
end.date <- tail(metals.df$date, 1)

# Forecast interval parameter
forecast.days <- 90

shinyServer(function(input, output) {

    # Metal Prices plot: built with ggplot2 (same code path used for the
    # static PDF/PNG report), rendered interactively via plotly.
    output$prices.plot <- renderPlotly({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        ggplotly(metalsPricePlot(metals.df, tag, input$method))
    })

    # Forecasted data with auto.arima plot
    output$prediction.plot <- renderPlotly({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        arima.fit <- auto.arima(tsColumn(metals.df, tag),
                                approximation = FALSE,
                                trace = FALSE)
        pred <- forecast(arima.fit, h = forecast.days)
        ggplotly(arimaForecastPlot(pred, start = start.date, ylabel = tag, dates = metals.df$date))
    })

    # Data first differences plot
    output$diff.plot <- renderPlotly({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        ggplotly(metalsDiffPlot(metals.df, tag, start.date, end.date, log10 = input$chcklog))
    })

    output$text.sd <- renderText({
        paste0('Start Date: ',
               start.date <- head(metals.df$date, 1))
    })

    output$text.ed <- renderText({
        paste0('End Date: ',
               end.date <- tail(metals.df$date, 1))
    })

    # ARIMA results from auto.arima
    output$text.arima <- renderPrint({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        arima.fit <- auto.arima(tsColumn(metals.df, tag),
                                approximation = FALSE,
                                trace = FALSE)
        summary(arima.fit)
    })

    output$metals.table <- renderDT(
        metals.df[, grepl(paste0(input$metal_id, '|date'), names(metals.df))],
        options = list(pageLength = 10)
    )

    output$residuals.plot <- renderPlotly({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        arima.fit <- auto.arima(tsColumn(metals.df, tag),
                                approximation = FALSE,
                                trace = FALSE)
        residuals <- ts(arima.fit$residuals)
        acf.plot <- ggAcf(residuals, color = metals_palette[['ink']]) +
            ggtitle('ACF Residual') +
            theme_metals()
        pacf.plot <- ggPacf(residuals, color = metals_palette[['ink']]) +
            ggtitle('PACF Residual') +
            theme_metals()
        subplot(ggplotly(acf.plot), ggplotly(pacf.plot), nrows = 1, titleX = TRUE, titleY = TRUE)
    })

    forecast.table <- reactive({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        arima.fit <- auto.arima(tsColumn(metals.df, tag),
                                approximation = FALSE,
                                trace = FALSE)
        pred <- forecast(arima.fit, h = forecast.days)
        pred <- as.data.frame(pred)
        pred <- cbind(date = 0, pred[-1])
        # prices exist only on trading days: date the horizon with weekdays
        pred$date <- nextTradingDays(end.date, forecast.days)
        pred
    })

    output$table.arima <- renderDT({
        forecast.table()
    }, options = list(pageLength = 10))
})
