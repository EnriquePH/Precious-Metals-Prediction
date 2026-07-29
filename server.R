#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: server.R
#  (c) 2015 - Enrique Pérez Herrero
#  20/Dec/2015 # nolint: commented_code_linter.
#  GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
#  ----------------------------------------------------------------------------
#
#  Shiny server logic. Metal price history is downloaded once, at app start
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

    # Metal Prices plot using ggplot2
    output$prices.plot <- renderPlot({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        ggplot(data = metals.df, aes(.data$date, .data[[tag]])) +
            geom_line() +
            stat_smooth(
                method = input$method, formula = y ~ x, size = 1
            ) +
            xlab('')
    })

    # Forecasted data with auto.arima plot
    output$prediction.plot <- renderPlot({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        selected.metal <- ts(zoo(metals.df[tag],
                                 order.by = metals.df$date))
        arima.fit <- auto.arima(selected.metal,
                                approximation = FALSE,
                                trace = FALSE)
        pred <- forecast(arima.fit, h = forecast.days)
        arimaForecastPlot(pred, start = start.date, ylabel = tag)
    })

    # Data first differences plot
    output$diff.plot <- renderPlot({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        selected.metal <-
            ts(zoo(metals.df[tag], order.by = metals.df$date))

        if (input$chcklog) {
            selected.metal <- diff(log10(selected.metal))
        } else {
            selected.metal <- diff(selected.metal)
        }

        diff.df <- data.frame(
            date = seq(from = start.date + 1, to = end.date, by = '1 day'),
            price = selected.metal
        )

        ggplot(data = diff.df, aes(.data$date, .data[[tag]])) +
            geom_line() +
            xlab('')
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
        selected.metal <- ts(zoo(metals.df[tag],
                                 order.by = metals.df$date))
        arima.fit <- auto.arima(selected.metal,
                                approximation = FALSE,
                                trace = FALSE)
        summary(arima.fit)
    })

    output$metals.table <- renderDT(
        metals.df[, grepl(paste0(input$metal_id, '|date'), names(metals.df))],
        options = list(pageLength = 10)
    )

    output$residuals.plot <- renderPlot({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        selected.metal <- ts(zoo(metals.df[tag],
                                 order.by = metals.df$date))
        arima.fit <- auto.arima(selected.metal,
                                approximation = FALSE,
                                trace = FALSE)
        par(mfrow = c(1, 2))
        acf(ts(arima.fit$residuals), main = 'ACF Residual')
        pacf(ts(arima.fit$residuals), main = 'PACF Residual')
    })

    forecast.table <- reactive({
        tag <- paste(input$metal_id, input$metal_curr, sep = '.')
        selected.metal <- ts(zoo(metals.df[tag],
                                 order.by = metals.df$date))
        arima.fit <- auto.arima(selected.metal,
                                approximation = FALSE,
                                trace = FALSE)
        pred <- forecast(arima.fit, h = forecast.days)
        pred <- as.data.frame(pred)
        pred <- cbind(date = 0, pred[-1])
        pred$date <-
            seq(from = end.date + 1,
                to = end.date + forecast.days,
                by = '1 day')
        pred
    })

    output$table.arima <- renderDT({
        forecast.table()
    }, options = list(pageLength = 10))
})
