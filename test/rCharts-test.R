# library(quantmod)
# library(ggplot2)
# library(forecast)
# library(scales)
# library(rCharts)
# library(reshape2)
# 
# # Parameters
# 
# forecast.days <- 365
# max.range <- (5 * 365 - 13)
# 
# # https://en.wikipedia.org/wiki/Precious_metal
# 
# getPreciousMetals <- function(metals, currencies){
#     metal_data <- list()
#     for(metal in metals){
#         for(currency in currencies){
#             num <- paste(metal, currency, sep = '.')
#             print(num)
#             metal_data[[num]] <- as.data.frame(
#                 getMetals(metal,
#                           from = Sys.Date() - max.range,
#                           to = Sys.Date(),
#                           base.currency = currency,
#                           auto.assign = FALSE
#                 )
#             )
#         }
#     }
#     # Convert metal_data to df and improve formatting.
#     metal_data <- as.data.frame(metal_data)
#     # rCharts needs date as character
#     metal_data <- cbind(date = as.character(rownames(metal_data)),
#                         metal_data)
#     rownames(metal_data) <- c(1: nrow(metal_data))
#     return(metal_data)
# }
# 
# 
# precious_metals <- c('Gold' = 'XAU',
#                      'Silver' = 'XAG',
#                      'Palladium' = 'XPD',
#                      'Platinum' = 'XPT')
# 
# currency_list <- c('US Dollar' = 'USD',
#                    'Euro' = 'EUR',
#                    'Pound Sterling' = 'GBP')
# 
# metals.df <- getPreciousMetals(precious_metals, currency_list)
# 
# 
# m1 <- mPlot(x = 'date',
#             y = paste(precious_metals, 'USD', sep = '.'),
#             type = 'Line',
#             events = paste(2011:2016),
#             eventLineColors = 'black',
#             eventStrokeWidth = .1,
#             data = metals.df
#             )
# m1$set(pointSize = 0, lineWidth = 1)
# #m1$print("chart2")
# m1$show('server')
