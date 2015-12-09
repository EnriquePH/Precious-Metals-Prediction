library(quantmod)
library(ggplot2)
library(forecast)
library(scales)


# https://en.wikipedia.org/wiki/Precious_metal

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


# Step 1: Plot Palladium price data as time series

start.date <- head(metals.df$date, 1)
end.date <- tail(metals.df$date, 1)

palladium.USD <- ts(zoo(metals.df['XPT.USD'], order.by = metals.df$date))

palladium.USD <- as.ts(metals.df['XPT.USD'], start = start.date, end = end.date)

plot(palladium.USD, xlab = 'Years', ylab = 'USD')

# Step 2: Difference data to make data stationary on mean (remove trend)

plot(diff(palladium.USD), ylab = 'Differenced Palladium Prices')

plot(log10(palladium.USD), ylab = 'Log (Palladium Price)')


# Step 3: log transform data to make data stationary on variance

plot(log10(palladium.USD), ylab = 'Log (Palladium Price)')


# Step 4: Difference log transform data to make data stationary
# on both mean and variance

plot(diff(log10(palladium.USD)), ylab = 'Differenced Log (Palladium Price)')
axis(1, metals.df$date, format(metals.df$date, "%b %d"))


df <- data.frame(
    date = seq(from = start.date , to = end.date - 1 , by="1 day"),
    price = diff(log10(palladium.USD))
)

View(df)

qplot(date, XPT.USD, data=df, geom="line")

# Step 5: Plot ACF and PACF to identify potential AR and MA model

par(mfrow = c(1, 2))
acf(ts(diff(palladium.USD)), main = 'ACF Palladium Price')
pacf(ts(diff(palladium.USD)), main = 'PACF Palladium Price')


# Step 6: Identification of best fit ARIMA model

ARIMAfit <- auto.arima(palladium.USD,
                       approximation = FALSE,
                       trace = FALSE)
summary(ARIMAfit)


# Step 7: Forecast sales using the best fit ARIMA model

pred <- forecast(ARIMAfit, h = 365)
pred

plot(pred, ylab = 'USD')



# Step 8: Plot ACF and PACF for residuals of ARIMA model to ensure no more
# information is left for extraction

par(mfrow = c(1, 2))
acf(ts(ARIMAfit$residuals), main = 'ACF Residual')
pacf(ts(ARIMAfit$residuals), main ='PACF Residual')


# ggplot() +
#     geom_line(data = metals.df,
#               aes(x = date, y = XAU.USD, colour = 'XAU.USD')) +
#     geom_line(data = metals.df,
#               aes(x = date, y = XPD.USD, colour = 'XPD.USD')) +
#     geom_line(data = metals.df,
#               aes(x = date, y = XPT.USD, colour = 'XPT.USD')) + 
#     geom_line(data = metals.df,
#               aes(x = date, y = XAG.USD, colour = 'XAG.USD')) +
#     theme(legend.title = element_blank()) +
#     xlab('') +
#     ylab('USD')
    

