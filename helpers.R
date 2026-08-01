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
library(plotly)
library(patchwork)

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

# Shared colors for all app plots: dark ink for observed data, a single blue
# hue (light -> dark) for model output and its uncertainty, so every plot in
# the app reads with the same visual language instead of arbitrary per-plot
# colors. Ramp steps from a validated sequential blue scale.
metals_palette <- c(
    ink        = '#0b0b0b', # observed / historical data
    model      = '#1c5cab', # fitted trend / forecast mean
    ci80       = '#5598e7', # 80% CI band (narrower, closer to the mean)
    ci90       = '#b7d3f6', # 90% CI band (wider, so lighter/receding)
    grid       = '#e1e0d9',
    axis_text  = '#898781',
    axis_title = '#52514e'
)

#' Shared ggplot2 theme for the app's plots
#'
#' A clean, minimal theme (recessive gridlines, muted axis text, legend on
#' top when present) applied consistently across the Prices, Forecast, and
#' Differences plots.
#'
#' @param base_size Base font size, passed to [ggplot2::theme_minimal()].
#' @return A ggplot2 `theme` object.
theme_metals <- function(base_size = 12) {
    theme_minimal(base_size = base_size) +
        theme(
            panel.grid.minor = element_blank(),
            panel.grid.major = element_line(color = metals_palette[['grid']], linewidth = 0.3),
            axis.text = element_text(color = metals_palette[['axis_text']]),
            axis.title = element_text(color = metals_palette[['axis_title']]),
            plot.title = element_text(color = metals_palette[['ink']], face = 'bold'),
            legend.position = 'top',
            legend.title = element_blank()
        )
}

#' Build a metal price-history ggplot
#'
#' Shared by the Shiny app's "Prices Plot" tab (wrapped in `plotly::ggplotly()`
#' there) and `report-template.qmd`, which prints it unwrapped for the
#' static PDF report.
#'
#' @param df Wide metals data frame, as returned by [getPreciousMetals()].
#' @param tag Column name to plot, e.g. `'XAU.USD'`.
#' @param method Smoothing method passed to [ggplot2::stat_smooth()].
#' @return A ggplot object.
metalsPricePlot <- function(df, tag, method = 'loess') {
    ggplot(data = df, aes(.data$date, .data[[tag]])) +
        geom_line(color = metals_palette[['ink']], linewidth = 0.6) +
        stat_smooth(
            method = method, formula = y ~ x, linewidth = 0.8,
            color = metals_palette[['model']], fill = metals_palette[['ci90']]
        ) +
        ggtitle(paste(tag, 'Price History')) +
        xlab('') +
        theme_metals()
}

#' Build the metal first-differences ggplot
#'
#' Shared by the Shiny app's "Differences Plot" tab (wrapped in
#' `plotly::ggplotly()` there) and the Quarto report template, which prints
#' it unwrapped.
#'
#' @param df Wide metals data frame, as returned by [getPreciousMetals()].
#' @param tag Column name to plot, e.g. `'XAU.USD'`.
#' @param start.date Date the (undifferenced) series begins on.
#' @param end.date Date the (undifferenced) series ends on.
#' @param log10 If `TRUE` (default), differences the log10 of the series
#'   instead of the raw series.
#' @return A ggplot object.
metalsDiffPlot <- function(df, tag, start.date, end.date, log10 = TRUE) {
    series <- tsColumn(df, tag)
    series <- if (log10) diff(base::log10(series)) else diff(series)

    diff.df <- data.frame(
        date = seq(from = start.date + 1, to = end.date, by = '1 day'),
        price = series
    )

    ggplot(data = diff.df, aes(.data$date, .data[[tag]])) +
        geom_line(color = metals_palette[['ink']], linewidth = 0.6) +
        ggtitle(paste(tag, if (log10) 'Log10 Differences' else 'Differences')) +
        xlab('') +
        theme_metals()
}

#' Extract one metal/currency column as a time series
#'
#' @param df Wide metals data frame, as returned by [getPreciousMetals()].
#' @param tag Column name to extract, e.g. `'XAU.USD'`.
#' @return A `ts` object.
tsColumn <- function(df, tag) {
    ts(zoo::zoo(df[tag], order.by = df$date))
}

#' Plot a forecast object as a history + forecast-band chart
#'
#' Renders the observed history as a dark line, the forecast mean as a blue
#' line, and the 80%/90% confidence bands as two steps of that same blue hue
#' (narrower/darker = 80%, wider/lighter = 90%), with a legend identifying
#' all four. Based on:
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
        geom_ribbon(aes(ymin = .data$low2, ymax = .data$upp2, fill = '90% CI')) +
        geom_ribbon(aes(ymin = .data$low1, ymax = .data$upp1, fill = '80% CI')) +
        geom_line(aes(color = 'History'), linewidth = 0.6, na.rm = TRUE) +
        geom_line(
            data = df[!is.na(df$forecast), ],
            aes(.data$time, .data$forecast, color = 'Forecast'),
            linewidth = 0.7,
            na.rm = TRUE
        ) +
        scale_fill_manual(
            values = c('90% CI' = metals_palette[['ci90']], '80% CI' = metals_palette[['ci80']]),
            breaks = c('80% CI', '90% CI')
        ) +
        scale_color_manual(
            values = c('History' = metals_palette[['ink']], 'Forecast' = metals_palette[['model']])
        ) +
        ggtitle(paste('Forecasts from', forecast$method)) +
        xlab('') +
        ylab(ylabel) +
        theme_metals()
}
