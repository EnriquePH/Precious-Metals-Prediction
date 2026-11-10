# Changelog

All notable changes to this project will be documented in this file.

The format is based on "Keep a Changelog" and aims to be human- and
machine-readable.

## [Unreleased]

### Added
- Plantilla inicial de changelog.

### Changed
- 

### Fixed
- 

### Deprecated
- 

### Removed
- 

## [1.3.0] - 2026-11-10
### Changed
- Prices now come from Yahoo Finance (COMEX/NYMEX front-month futures `GC=F`,
  `SI=F`, `PL=F`, `PA=F`, in USD per troy ounce), converted to EUR and GBP
  with each day's `EURUSD=X` / `GBPUSD=X` rate. Oanda no longer serves metal
  prices to `quantmod::getMetals()`, so the app could not load any data.
- Three years of history instead of 180 days.
- Forecast horizons, the forecast table and the differences plot are dated
  with trading days (`nextTradingDays()`); the data has no weekends.

### Fixed
- The wide forecast band is the 95 % interval (the `forecast()` default), not
  90 % as the legend and the help said.

### Added
- Tests for the currency conversion, `nextTradingDays()` and trading-day
  dates in `arimaForecastPlot(dates = )`.

## [1.2.0] - YYYY-MM-DD
### Added
- Initial release notes placeholder.

## Notas
- Fecha y versión: actualiza la sección `[Unreleased]` a una versión semántica y fecha cuando publiques.
