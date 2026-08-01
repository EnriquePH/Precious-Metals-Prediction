#!/usr/bin/env Rscript
#  ----------------------------------------------------------------------------
#  PRECIOUS METALS PRICE FORECAST
#  File: report_eur.R
#  Renders report-template.qmd for every metal priced in Euros, with the
#  same price/forecast/differences/residuals plots, tables, and ARIMA
#  summaries as the Shiny app: Rscript report_eur.R
#  Output path is configurable via the REPORT_FILE env var.
#  ----------------------------------------------------------------------------

file <- Sys.getenv('REPORT_FILE', 'reports/metals-report-eur.pdf')
dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

quarto::quarto_render(
    input = 'report-template.qmd',
    output_file = 'report-template-eur.pdf',
    execute_params = list(currency = 'EUR')
)
file.rename('report-template-eur.pdf', file)

cat(paste('Report written to', file, '\n'))
