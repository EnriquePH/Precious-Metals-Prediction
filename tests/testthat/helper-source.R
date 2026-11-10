library(TTR)
library(quantmod)
library(ggplot2)
library(forecast)

# Under R CMD check the package is installed: load its functions. Run
# directly (CI, `Rscript testthat.R`), the package is not installed: read the
# app's helpers.R instead (tests/testthat -> project root).
if (requireNamespace('Precious.metals', quietly = TRUE)) {
    library(Precious.metals)
} else {
    source(file.path('..', '..', 'helpers.R'), chdir = FALSE)
}
