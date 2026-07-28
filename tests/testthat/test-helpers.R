test_that("precious_metals maps display names to Oanda tickers", {
  expect_equal(unname(precious_metals[["Gold"]]), "XAU")
  expect_equal(unname(precious_metals[["Silver"]]), "XAG")
  expect_equal(unname(precious_metals[["Palladium"]]), "XPD")
  expect_equal(unname(precious_metals[["Platinum"]]), "XPT")
})

test_that("currency_list maps display names to ISO currency codes", {
  expect_equal(unname(currency_list[["US Dollar"]]), "USD")
  expect_equal(unname(currency_list[["Euro"]]), "EUR")
  expect_equal(unname(currency_list[["Pound Sterling"]]), "GBP")
})

test_that("arimaForecastPlot builds a ggplot from a forecast object", {
  set.seed(42)
  series <- ts(cumsum(rnorm(60, mean = 0, sd = 2)) + 100, frequency = 1)
  fit <- forecast::auto.arima(series, approximation = FALSE, trace = FALSE)
  pred <- forecast::forecast(fit, h = 10)

  p <- arimaForecastPlot(pred, start = as.Date("2020-01-01"), ylabel = "Test.USD")

  expect_s3_class(p, "ggplot")
  expect_setequal(
    names(p$data),
    c("time", "x", "forecast", "low1", "upp1", "low2", "upp2")
  )
  # history + forecast horizon rows
  expect_equal(nrow(p$data), length(series) + 10)
  # the last `h` rows are the forecast horizon, and only those should be non-NA
  expect_equal(sum(!is.na(p$data$forecast)), 10)
})
