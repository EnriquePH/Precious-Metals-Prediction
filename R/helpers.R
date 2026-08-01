#!/usr/bin/env Rscript
# Helpers copied into R/ to be part of the package for R CMD check

library(TTR)
library(quantmod)
library(ggplot2)
library(forecast)
library(plotly)
library(patchwork)

# Oanda only provides historical data for the past 180 days.
max.range <- 180

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
    metal_data <- as.data.frame(metal_data)
    metal_data <- cbind(date = as.Date(rownames(metal_data)), metal_data)
    rownames(metal_data) <- seq_len(nrow(metal_data))
    metal_data
}

precious_metals <- c('Gold' = 'XAU', 'Silver' = 'XAG', 'Palladium' = 'XPD', 'Platinum' = 'XPT')

currency_list <- c('US Dollar' = 'USD', 'Euro' = 'EUR', 'Pound Sterling' = 'GBP')

smooth_method <- c('loess', 'lm')

metals_palette <- c(ink = '#0b0b0b', model = '#1c5cab', ci80 = '#5598e7', ci90 = '#b7d3f6', grid = '#e1e0d9', axis_text = '#898781', axis_title = '#52514e')

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

tsColumn <- function(df, tag) {
    ts(zoo::zoo(df[tag], order.by = df$date))
}

arimaForecastPlot <- function(forecast, start, ylabel, ...) {
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
