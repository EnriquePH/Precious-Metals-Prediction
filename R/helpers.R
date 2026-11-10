#!/usr/bin/env Rscript
# Helpers copied into R/ to be part of the package for R CMD check.
# Generated from ../helpers.R: edit that file and copy it again.

library(TTR)
library(quantmod)
library(ggplot2)
library(forecast)
library(plotly)
library(patchwork)

# Days of history downloaded at start-up (about three years of trading days).
max.range <- 3 * 365

# Prices come from Yahoo Finance: the COMEX/NYMEX front-month futures, in USD
# per troy ounce. Oanda, the original source, no longer serves metal prices
# to quantmod::getMetals(). Display tickers (XAU...) stay as before.
yahoo_futures <- c(
    'XAU' = 'GC=F',
    'XAG' = 'SI=F',
    'XPD' = 'PA=F',
    'XPT' = 'PL=F'
)

# USD per unit of each other currency, to convert the USD prices.
yahoo_fx <- c(
    'EUR' = 'EURUSD=X',
    'GBP' = 'GBPUSD=X'
)

#' Daily closing prices of one Yahoo Finance symbol
#'
#' @param symbol Yahoo Finance symbol, e.g. `'GC=F'`.
#' @param from First date to download.
#' @return A one-column `xts` series with missing days carried forward.
yahooClose <- function(symbol, from) {
    x <- suppressWarnings(
        quantmod::getSymbols(symbol, src = 'yahoo', from = from, auto.assign = FALSE)
    )
    zoo::na.locf(quantmod::Cl(x), na.rm = TRUE)
}

#' Download precious metals price history from Yahoo Finance
#'
#' For every metal, downloads the last [max.range] days of the front-month
#' future (USD per troy ounce) and converts it to each requested currency
#' with that day's exchange rate. Only trading days are returned.
#'
#' @param metals Named character vector of metal tickers (e.g.
#'   `c('Gold' = 'XAU')`); only the values are used.
#' @param currencies Named character vector of ISO currency codes (e.g.
#'   `c('US Dollar' = 'USD')`); only the values are used.
#' @return A data frame with a `date` column plus one `<metal>.<currency>`
#'   column per combination, e.g. `XAU.USD`.
getPreciousMetals <- function(metals, currencies) {
    from <- Sys.Date() - max.range
    fx <- lapply(setdiff(unname(currencies), 'USD'), function(currency) {
        cat(paste('Loading exchange rate:', currency, '\n'))
        yahooClose(yahoo_fx[[currency]], from)
    })
    names(fx) <- setdiff(unname(currencies), 'USD')

    columns <- list()
    for (metal in metals) {
        cat(paste('Loading data:', metal, '\n'))
        usd <- yahooClose(yahoo_futures[[metal]], from)
        for (currency in currencies) {
            price <- if (currency == 'USD') {
                usd
            } else {
                # rate of the same day, or of the last day it was quoted
                both <- zoo::na.locf(merge(usd, fx[[currency]]), na.rm = TRUE)[zoo::index(usd)]
                both[, 1] / both[, 2]
            }
            columns[[paste(metal, currency, sep = '.')]] <- stats::setNames(price, NULL)
        }
    }
    wide <- stats::na.omit(do.call(merge, unname(columns)))
    metal_data <- data.frame(date = as.Date(zoo::index(wide)), zoo::coredata(wide))
    names(metal_data) <- c('date', names(columns))
    rownames(metal_data) <- seq_len(nrow(metal_data))
    metal_data
}

#' Next trading days (Monday to Friday) after a date
#'
#' Prices exist only on trading days, so forecast horizons are dated with
#' weekdays. Exchange holidays are not taken into account.
#'
#' @param last Last observed date.
#' @param n Number of days.
#' @return A `Date` vector of length `n`.
nextTradingDays <- function(last, n) {
    days <- seq(last + 1, by = '1 day', length.out = ceiling(n * 7 / 5) + 7)
    days <- days[!format(days, '%u') %in% c('6', '7')]
    days[seq_len(n)]
}

# Display name -> ticker, used to populate the "Metal" select input
# (mapped to the Yahoo Finance futures in yahoo_futures).
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
    ci95       = '#b7d3f6', # 95% CI band (wider, so lighter/receding)
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
            color = metals_palette[['model']], fill = metals_palette[['ci95']]
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
#' @param start.date,end.date Not used since version 1.3.0 (the differences
#'   are dated with `df$date`, which has only trading days); kept so that
#'   existing calls keep working.
#' @param log10 If `TRUE` (default), differences the log10 of the series
#'   instead of the raw series.
#' @return A ggplot object.
metalsDiffPlot <- function(df, tag, start.date, end.date, log10 = TRUE) {
    series <- tsColumn(df, tag)
    series <- if (log10) diff(base::log10(series)) else diff(series)

    # first differences start on the second observed (trading) day
    diff.df <- data.frame(
        date = utils::tail(df$date, -1),
        price = as.numeric(series)
    )
    names(diff.df)[2] <- tag

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
#' line, and the 80%/95% confidence bands as two steps of that same blue hue
#' (narrower/darker = 80%, wider/lighter = 95%), with a legend identifying
#' all four. Based on:
#' http://librestats.com/2012/06/11/autoplot-graphical-methods-with-ggplot2/
#'
#' @param forecast A `forecast` object, as returned by
#'   [forecast::forecast()].
#' @param start Date the history component of `forecast$x` begins on.
#' @param ylabel Label for the y-axis.
#' @param dates Optional `Date` vector with the date of every observation in
#'   `forecast$x` (trading days); the horizon is then dated with the next
#'   trading days. Without it, consecutive days from `start` are assumed.
#' @param ... Passed through to the top-level [ggplot2::aes()] call.
#' @return A `ggplot` object.
arimaForecastPlot <- function(forecast, start, ylabel, dates = NULL, ...) {
    # data wrangling
    lenx <- length(forecast$x)
    if (is.null(dates)) {
        time <- attr(forecast$x, 'tsp')
        time <- as.Date(seq(time[1], attr(forecast$mean, 'tsp')[2], by = 1 / time[3]) + start)
    } else {
        time <- c(dates, nextTradingDays(utils::tail(dates, 1), length(forecast$mean)))
    }

    df <- data.frame(
        time = time,
        x = c(forecast$x, forecast$mean),
        forecast = c(rep(NA, lenx), forecast$mean),
        low1 = c(rep(NA, lenx), forecast$lower[, 1]),
        upp1 = c(rep(NA, lenx), forecast$upper[, 1]),
        low2 = c(rep(NA, lenx), forecast$lower[, 2]),
        upp2 = c(rep(NA, lenx), forecast$upper[, 2])
    )

    ggplot(df, aes(.data$time, .data$x), ...) +
        geom_ribbon(aes(ymin = .data$low2, ymax = .data$upp2, fill = '95% CI')) +
        geom_ribbon(aes(ymin = .data$low1, ymax = .data$upp1, fill = '80% CI')) +
        geom_line(aes(color = 'History'), linewidth = 0.6, na.rm = TRUE) +
        geom_line(
            data = df[!is.na(df$forecast), ],
            aes(.data$time, .data$forecast, color = 'Forecast'),
            linewidth = 0.7,
            na.rm = TRUE
        ) +
        scale_fill_manual(
            values = c('95% CI' = metals_palette[['ci95']], '80% CI' = metals_palette[['ci80']]),
            breaks = c('80% CI', '95% CI')
        ) +
        scale_color_manual(
            values = c('History' = metals_palette[['ink']], 'Forecast' = metals_palette[['model']])
        ) +
        ggtitle(paste('Forecasts from', forecast$method)) +
        xlab('') +
        ylab(ylabel) +
        theme_metals()
}
