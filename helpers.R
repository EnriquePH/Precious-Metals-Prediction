#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: helpers.R
#  Enrique Pérez Herrero
#  11/Dec/2015
#  ----------------------------------------------------------------------------


library(quantmod)
library(ggplot2)
library(forecast)


getPreciousMetals <- function(metals, currencies) {
    metal_data <- list()
    for (metal in metals) {
        for (currency in currencies) {
            num <- paste(metal, currency, sep = '.')
            print(num)
            metal_data[[num]] <- as.data.frame(
                getMetals(
                    metal,
                    from = Sys.Date() - (5 * 365 - 13),
                    to = Sys.Date(),
                    base.currency = currency,
                    auto.assign = FALSE
                )
            )
        }
    }
    # Convert metal_data to df and improve formatting.
    metal_data <- as.data.frame(metal_data)
    metal_data <-
        cbind(date = as.Date(rownames(metal_data)), metal_data)
    rownames(metal_data) <- c(1:nrow(metal_data))
    return(metal_data)
}


precious_metals <- c(
    'Gold' = 'XAU',
    'Silver' = 'XAG',
    'Palladium' = 'XPD',
    'Platinum' = 'XPT'
)

currency_list <- c('US Dollar' = 'USD',
                   'Euro' = 'EUR',
                   'Pound Sterling' = 'GBP')


smooth_method <- c('loess', 'lm')


arimaForecastPlot <- function(forecast, start, ylabel, ...) {
    # data wrangling
    time <- attr(forecast$x, 'tsp')
    time <-
        seq(time[1], attr(forecast$mean, 'tsp')[2], by = 1 / time[3])
    lenx <- length(forecast$x)
    lenmn <- length(forecast$mean)
    time2 <-
        seq(from = start, to = start + lenx + lenmn , by = "1 day")
    
    df <- data.frame(
        time = as.Date(time + start),
        x = c(forecast$x, forecast$mean),
        forecast = c(rep(NA, lenx), forecast$mean),
        low1 = c(rep(NA, lenx), forecast$lower[, 1]),
        upp1 = c(rep(NA, lenx), forecast$upper[, 1]),
        low2 = c(rep(NA, lenx), forecast$lower[, 2]),
        upp2 = c(rep(NA, lenx), forecast$upper[, 2])
    )
    
    
    p <- ggplot(df, aes(time, x), ...) +
        geom_ribbon(aes(ymin = low2, ymax = upp2), fill = 'yellow') +
        geom_ribbon(aes(ymin = low1, ymax = upp1), fill = 'orange') +
        geom_line() +
        geom_line(
            data = df[!is.na(df$forecast),],
            aes(time, forecast),
            color = 'blue',
            na.rm = TRUE
        ) +
        ggtitle(paste('Forecasts from', forecast$method)) +
        xlab('') +
        ylab(ylabel)
    return(p)
}
