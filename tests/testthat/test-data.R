# These tests hit Yahoo Finance through quantmod::getSymbols(). It is an
# unofficial endpoint with no SLA, so failures here are skipped rather than
# failed to keep CI from flaking on network/upstream issues rather than actual
# code regressions.

test_that('getPreciousMetals returns well-formed data for a single metal/currency', {
    skip_if_offline()
    skip_on_cran()

    df <- tryCatch(
        getPreciousMetals(c('Gold' = 'XAU'), c('US Dollar' = 'USD')),
        error = function(e) NULL
    )
    skip_if(is.null(df), 'Yahoo Finance unavailable')

    expect_s3_class(df, 'data.frame')
    expect_true(all(c('date', 'XAU.USD') %in% names(df)))
    expect_true(nrow(df) > 0)
    expect_s3_class(df$date, 'Date')
    expect_true(all(df$XAU.USD > 0))
    # trading days only
    expect_false(any(format(df$date, '%u') %in% c('6', '7')))
})

test_that('getPreciousMetals converts USD prices to other currencies', {
    skip_if_offline()
    skip_on_cran()

    df <- tryCatch(
        getPreciousMetals(c('Gold' = 'XAU'), c('US Dollar' = 'USD', 'Euro' = 'EUR')),
        error = function(e) NULL
    )
    skip_if(is.null(df), 'Yahoo Finance unavailable')

    expect_true(all(c('date', 'XAU.USD', 'XAU.EUR') %in% names(df)))
    # a euro has been worth between 0.8 and 1.7 dollars
    ratio <- df$XAU.USD / df$XAU.EUR
    expect_true(all(ratio > 0.8 & ratio < 1.7))
})
