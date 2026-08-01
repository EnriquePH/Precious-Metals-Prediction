#!/usr/bin/env Rscript
#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: report_usd.R
#  Renders report-template.qmd for every metal priced in US Dollars, with
#  the same price/forecast/differences/residuals plots, tables, and ARIMA
#  summaries as the Shiny app: Rscript report_usd.R
#  Output path is configurable via the REPORT_FILE env var.
#  ----------------------------------------------------------------------------

file <- Sys.getenv('REPORT_FILE', 'reports/metals-report-usd.pdf')
dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

quarto::quarto_render(
    input = 'report-template.qmd',
    output_file = 'report-template-usd.pdf',
    execute_params = list(currency = 'USD')
)
file.rename('report-template-usd.pdf', file)

cat(paste('Report written to', file, '\n'))
