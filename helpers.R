library(quantmod)
library(ggplot2)


getPreciousMetals <- function(metals, currencies){
    metal_data <- list()
    for(metal in metals){
        for(currency in currencies){
            num <- paste(metal, currency, sep = '.')
            print(num)
            metal_data[[num]] <- as.data.frame(
                getMetals(metal,
                          from = Sys.Date() - (5*365 - 13),
                          to = Sys.Date(),
                          base.currency = currency,
                          auto.assign = FALSE
                )
            )
        }
    }
    # Convert metal_data to df and improve formatting.
    metal_data <- as.data.frame(metal_data)
    metal_data <- cbind(date = as.Date(rownames(metal_data)), metal_data)
    rownames(metal_data) <- c(1: nrow(metal_data))
    return(metal_data)
}


precious_metals <- c('Gold' = 'XAU',
                     'Silver' = 'XAG',
                     'Palladium' = 'XPD',
                     'Platinum' = 'XPT')

currency_list <- c('US Dollar' = 'USD',
                   'Euro' = 'EUR',
                   'Pound Sterling' = 'GBP')


smooth_method <- c('loess', 'lm')
