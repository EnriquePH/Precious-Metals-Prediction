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

metals.df <- getPreciousMetals(precious_metals, currency_list)

View(metals.df)


ggplot() +
    geom_line(data = metals.df,
              aes(x = date, y = XAU.USD, colour = 'XAU.USD')) +
    geom_line(data = metals.df,
              aes(x = date, y = XPD.USD, colour = 'XPD.USD')) +
    geom_line(data = metals.df,
              aes(x = date, y = XPT.USD, colour = 'XPT.USD')) + 
    geom_line(data = metals.df,
              aes(x = date, y = XAG.USD, colour = 'XAG.USD')) +
    theme(legend.title = element_blank()) +
    xlab('') +
    ylab('USD')
    

