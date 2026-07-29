#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: helpers.R
#  (c) 2015 - Enrique Pérez Herrero
#  20/Dec/2015 # nolint: commented_code_linter.
#  GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
#  ----------------------------------------------------------------------------

library(TTR)
library(quantmod)
library(ggplot2)
library(forecast)

# Oanda only provides historical data for the past 180 days.
max.range <- 180

#' Download precious metals price history from Oanda
#'
#' For every combination of metal and base currency, fetches the last
#' [max.range] days of prices via [quantmod::getMetals()] and combines them
#' into a single wide data frame keyed by date.
#'
#' @param metals Named character vector of Oanda metal tickers (e.g.
#'   `c('Gold' = 'XAU')`); only the values are used.
#' @param currencies Named character vector of ISO currency codes (e.g.
#'   `c('US Dollar' = 'USD')`); only the values are used.
#' @return A data frame with a `date` column plus one `<metal>.<currency>`
#'   column per combination, e.g. `XAU.USD`.
getPreciousMetals <- function(metals, currencies) {
    metal_data <- list()
    for (metal in metals) {
        for (currency in currencies) {
            num <- paste(metal, currency, sep = '.')
            cat(paste('Loading data:', num, '\n'))
            metal_data[[num]] <- as.data.frame(
                quantmod::getMetals(
                    metal,
                    from = Sys.Date() - max.range,
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
    rownames(metal_data) <- seq_len(nrow(metal_data))
    metal_data
}

# Display name -> Oanda ticker, used to populate the "Metal" select input.
precious_metals <- c(
    'Gold'      = 'XAU',
    'Silver'    = 'XAG',
    'Palladium' = 'XPD',
    'Platinum'  = 'XPT'
)

# Display name -> ISO currency code, used to populate the "Currency" select input.
currency_list <- c(
    'US Dollar'      = 'USD',
    'Euro'           = 'EUR',
    'Pound Sterling' = 'GBP'
)

# Smoothing methods offered on the "Prices Plot" tab's stat_smooth() control.
smooth_method <- c('loess', 'lm')

#' Plot a forecast object as a history + forecast-band chart
#'
#' Renders the observed history as a black line, the forecast mean as a blue
#' line, and the 80%/90% confidence bands as orange/yellow ribbons. Based on:
#' http://librestats.com/2012/06/11/autoplot-graphical-methods-with-ggplot2/
#'
#' @param forecast A `forecast` object, as returned by
#'   [forecast::forecast()].
#' @param start Date the history component of `forecast$x` begins on.
#' @param ylabel Label for the y-axis.
#' @param ... Passed through to the top-level [ggplot2::aes()] call.
#' @return A `ggplot` object.
arimaForecastPlot <- function(forecast, start, ylabel, ...) {
    # data wrangling
    time <- attr(forecast$x, 'tsp')
    time <- seq(time[1], attr(forecast$mean, 'tsp')[2], by = 1 / time[3])
    lenx <- length(forecast$x)

    df <- data.frame(
        time = as.Date(time + start),
        x = c(forecast$x, forecast$mean),
        forecast = c(rep(NA, lenx), forecast$mean),
        low1 = c(rep(NA, lenx), forecast$lower[, 1]),
        upp1 = c(rep(NA, lenx), forecast$upper[, 1]),
        low2 = c(rep(NA, lenx), forecast$lower[, 2]),
        upp2 = c(rep(NA, lenx), forecast$upper[, 2])
    )

    ggplot(df, aes(.data$time, .data$x), ...) +
        geom_ribbon(aes(ymin = .data$low2, ymax = .data$upp2), fill = 'yellow') +
        geom_ribbon(aes(ymin = .data$low1, ymax = .data$upp1), fill = 'orange') +
        geom_line() +
        geom_line(
            data = df[!is.na(df$forecast), ],
            aes(.data$time, .data$forecast),
            color = 'blue',
            na.rm = TRUE
        ) +
        ggtitle(paste('Forecasts from', forecast$method)) +
        xlab('') +
        ylab(ylabel)
}
