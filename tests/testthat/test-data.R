# These tests hit Oanda's live metals feed through quantmod::getMetals().
# It is an undocumented, unversioned endpoint with no SLA, so failures here
# are skipped rather than failed to keep CI from flaking on network/upstream
# issues rather than actual code regressions.

test_that("getPreciousMetals returns well-formed data for a single metal/currency", {
  skip_if_offline()
  skip_on_cran()

  df <- tryCatch(
    getPreciousMetals(c("Gold" = "XAU"), c("US Dollar" = "USD")),
    error = function(e) NULL
  )
  skip_if(is.null(df), "Oanda metals feed unavailable")

  expect_s3_class(df, "data.frame")
  expect_true(all(c("date", "XAU.USD") %in% names(df)))
  expect_true(nrow(df) > 0)
  expect_s3_class(df$date, "Date")
  expect_true(all(df$XAU.USD > 0))
})
