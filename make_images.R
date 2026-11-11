#!/usr/bin/env Rscript
#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: make_images.R
#  Redraws the images used by README.md and help.Rmd (img/gold-prices.png and
#  img/gold-arima.png) with today's Yahoo Finance data and the app's own plot
#  functions: Rscript make_images.R
#  ----------------------------------------------------------------------------

source('helpers.R')

metals.df <- getPreciousMetals(c('Gold' = 'XAU'), c('US Dollar' = 'USD'))
tag <- 'XAU.USD'

ggplot2::ggsave(
    'img/gold-prices.png', metalsPricePlot(metals.df, tag),
    width = 8.13, height = 4, dpi = 100, bg = 'white'
)

fit <- forecast::auto.arima(tsColumn(metals.df, tag), approximation = FALSE)
pred <- forecast::forecast(fit, h = 90)
ggplot2::ggsave(
    'img/gold-arima.png',
    arimaForecastPlot(pred, start = metals.df$date[1], ylabel = tag, dates = metals.df$date),
    width = 8.13, height = 4, dpi = 100, bg = 'white'
)

cat('Images written: img/gold-prices.png, img/gold-arima.png\n')
