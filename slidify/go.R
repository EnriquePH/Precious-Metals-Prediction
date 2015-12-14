# Step 0: Install Slidify
# Slidify is not on CRAN as yet and needs to be installed from github.
# You can use Hadley's devtools package to accomplish this easily.
# You will also need slidifyLibraries which contains all external
# libraries required by Slidify.

# require(devtools)
# install_github("ramnathv/slidify")
# install_github("ramnathv/slidifyLibraries")

library(slidify)
library(slidifyLibraries)

# 1 Author:
author("EnriquePH")

# 2 Edit
# Write in RMarkdown, separating slides with a blank line
# followed by three dashes ---.
# 3 Slidify


slidify("index.Rmd")
# 4 Publish