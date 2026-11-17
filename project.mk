# Precious Metals Prediction - project settings and targets (the repo owns this file).
# The Makefile (managed by the 00-CEREBRO template, KIND=r) includes it first; the defaults (devtools, lintr, styler)
# fit this package, so only the extra targets are here.

.PHONY: app reports

app: ## Shiny app: download prices and forecast on http://127.0.0.1:8323 (port convention)
	Rscript run.R

reports: ## PDF reports in USD and EUR (reports/)
	Rscript report_usd.R && Rscript report_eur.R
