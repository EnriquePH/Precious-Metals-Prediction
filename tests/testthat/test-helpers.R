test_that('precious_metals maps display names to tickers', {
    expect_equal(unname(precious_metals[['Gold']]), 'XAU')
    expect_equal(unname(precious_metals[['Silver']]), 'XAG')
    expect_equal(unname(precious_metals[['Palladium']]), 'XPD')
    expect_equal(unname(precious_metals[['Platinum']]), 'XPT')
})

test_that('currency_list maps display names to ISO currency codes', {
    expect_equal(unname(currency_list[['US Dollar']]), 'USD')
    expect_equal(unname(currency_list[['Euro']]), 'EUR')
    expect_equal(unname(currency_list[['Pound Sterling']]), 'GBP')
})

test_that('arimaForecastPlot builds a ggplot from a forecast object', {
    set.seed(42)
    series <- ts(cumsum(rnorm(60, mean = 0, sd = 2)) + 100, frequency = 1)
    fit <- forecast::auto.arima(series, approximation = FALSE, trace = FALSE)
    pred <- forecast::forecast(fit, h = 10)

    p <- arimaForecastPlot(
        pred, start = as.Date('2020-01-01'), ylabel = 'Test.USD'
    )

    expect_s3_class(p, 'ggplot')
    expect_setequal(
        names(p$data),
        c('time', 'x', 'forecast', 'low1', 'upp1', 'low2', 'upp2')
    )
    # history + forecast horizon rows
    expect_equal(nrow(p$data), length(series) + 10)
    # the last `h` rows are the forecast horizon, and only those should be non-NA
    expect_equal(sum(!is.na(p$data$forecast)), 10)
})

test_that('every metal ticker has a Yahoo Finance future', {
    expect_setequal(names(yahoo_futures), unname(precious_metals))
    expect_true(all(setdiff(unname(currency_list), 'USD') %in% names(yahoo_fx)))
})

test_that('nextTradingDays skips weekends', {
    friday <- as.Date('2026-11-06')
    days <- nextTradingDays(friday, 6)
    expect_length(days, 6)
    expect_equal(days[1], as.Date('2026-11-09'))
    expect_false(any(format(days, '%u') %in% c('6', '7')))
})

test_that('arimaForecastPlot dates the horizon with trading days when given dates', {
    set.seed(1)
    dates <- nextTradingDays(as.Date('2026-01-01'), 40)
    series <- ts(cumsum(rnorm(40)) + 50)
    pred <- forecast::forecast(forecast::auto.arima(series), h = 5)
    p <- arimaForecastPlot(pred, start = dates[1], ylabel = 'Test.USD', dates = dates)
    expect_equal(nrow(p$data), 45)
    expect_equal(utils::head(p$data$time, 40), dates)
    expect_false(any(format(p$data$time, '%u') %in% c('6', '7')))
})
