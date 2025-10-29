# =============================================================================
# DATA LOADING SCRIPT
# Volatility Spillovers: US, China, Taiwan Tech Sector
# =============================================================================

# This script demonstrates how to load and prepare return data for ABEKK analysis
# Modify this script according to your data source and format

# Load required packages
if (!require("xts")) install.packages("xts")
if (!require("quantmod")) install.packages("quantmod")

library(xts)
library(quantmod)

# =============================================================================
# OPTION 1: Load from CSV file
# =============================================================================

load_from_csv <- function(filepath, date_column = "Date", has_header = TRUE) {
  # Read CSV file
  data <- read.csv(filepath, header = has_header, stringsAsFactors = FALSE)

  # Convert date column to Date format
  dates <- as.Date(data[[date_column]])

  # Extract return columns (all except date column)
  return_cols <- setdiff(names(data), date_column)
  returns_data <- as.matrix(data[, return_cols])

  # Create xts object
  returns <- xts(returns_data, order.by = dates)

  cat(sprintf("Loaded %d observations from %s to %s\n",
              nrow(returns),
              format(min(index(returns)), "%Y-%m-%d"),
              format(max(index(returns)), "%Y-%m-%d")))

  return(returns)
}

# Example usage:
# returns <- load_from_csv("data/returns.csv", date_column = "Date")

# =============================================================================
# OPTION 2: Download from Yahoo Finance
# =============================================================================

load_from_yahoo <- function(symbols, from_date, to_date) {
  # Download stock data
  cat("Downloading data from Yahoo Finance...\n")

  prices <- NULL
  for (symbol in symbols) {
    cat(sprintf("Downloading %s...\n", symbol))
    tryCatch({
      data <- getSymbols(symbol, from = from_date, to = to_date,
                        auto.assign = FALSE, warnings = FALSE)
      # Extract adjusted close prices
      price <- Ad(data)
      colnames(price) <- symbol

      if (is.null(prices)) {
        prices <- price
      } else {
        prices <- merge(prices, price)
      }
    }, error = function(e) {
      cat(sprintf("Error downloading %s: %s\n", symbol, e$message))
    })
  }

  # Calculate log returns (percentage)
  returns <- diff(log(prices)) * 100
  returns <- na.omit(returns)

  cat(sprintf("\nDownloaded %d observations from %s to %s\n",
              nrow(returns),
              format(min(index(returns)), "%Y-%m-%d"),
              format(max(index(returns)), "%Y-%m-%d")))

  return(returns)
}

# Example usage for US, China, Taiwan tech indices:
# US: QQQ (Nasdaq-100), SOXX (Semiconductor ETF)
# China: FXI (China Large-Cap ETF), KWEB (China Internet ETF)
# Taiwan: EWT (Taiwan ETF)

# symbols <- c("QQQ", "FXI", "EWT")
# from_date <- "2010-01-01"
# to_date <- "2024-12-31"
# returns <- load_from_yahoo(symbols, from_date, to_date)

# =============================================================================
# OPTION 3: Manual data entry (for testing)
# =============================================================================

create_sample_data <- function(n_obs = 1000, n_markets = 3,
                               market_names = c("US_ret", "CN_ret", "TW_ret")) {
  # Generate synthetic return data for testing
  set.seed(123)

  # Simulate correlated returns
  # Create correlation matrix
  rho <- 0.3
  Sigma <- matrix(rho, n_markets, n_markets)
  diag(Sigma) <- 1

  # Cholesky decomposition
  L <- chol(Sigma)

  # Generate random returns
  Z <- matrix(rnorm(n_obs * n_markets), n_obs, n_markets)
  returns_matrix <- Z %*% L

  # Scale to realistic return volatility (around 1-2% daily)
  returns_matrix <- returns_matrix * 1.5

  # Add some GARCH-like volatility clustering
  vol <- rep(1, n_obs)
  for (i in 2:n_obs) {
    vol[i] <- 0.05 + 0.85 * vol[i-1] + 0.1 * returns_matrix[i-1, 1]^2
  }

  for (j in 1:n_markets) {
    returns_matrix[, j] <- returns_matrix[, j] * sqrt(vol)
  }

  # Create dates
  dates <- seq(as.Date("2010-01-01"), by = "day", length.out = n_obs)

  # Create xts object
  colnames(returns_matrix) <- market_names
  returns <- xts(returns_matrix, order.by = dates)

  cat(sprintf("Created sample data: %d observations, %d markets\n", n_obs, n_markets))

  return(returns)
}

# Example usage:
# returns <- create_sample_data(n_obs = 3492, n_markets = 3)

# =============================================================================
# DATA PREPARATION AND VALIDATION
# =============================================================================

prepare_returns_data <- function(returns, market_names = NULL) {
  # Remove any missing values
  returns <- na.omit(returns)

  # Set column names if provided
  if (!is.null(market_names)) {
    colnames(returns) <- market_names
  }

  # Basic validation
  cat("\nData Summary:\n")
  cat(sprintf("Number of markets: %d\n", ncol(returns)))
  cat(sprintf("Number of observations: %d\n", nrow(returns)))
  cat(sprintf("Market names: %s\n", paste(colnames(returns), collapse=", ")))
  cat(sprintf("Date range: %s to %s\n",
              format(min(index(returns)), "%Y-%m-%d"),
              format(max(index(returns)), "%Y-%m-%d")))

  cat("\nDescriptive Statistics:\n")
  print(summary(coredata(returns)))

  cat("\nData preparation complete.\n")

  return(returns)
}

# =============================================================================
# EXAMPLE: Complete workflow for the project
# =============================================================================

# For US-China-Taiwan tech sector analysis, you might use:

# Method 1: Yahoo Finance (Recommended for quick start)
# symbols <- c("QQQ", "FXI", "EWT")  # US Tech, China, Taiwan
# returns <- load_from_yahoo(symbols, "2010-01-01", "2024-12-31")
# returns <- prepare_returns_data(returns, market_names = c("US_ret", "CN_ret", "TW_ret"))

# Method 2: From CSV file
# returns <- load_from_csv("your_data.csv", date_column = "Date")
# returns <- prepare_returns_data(returns, market_names = c("US_ret", "CN_ret", "TW_ret"))

# Method 3: Sample data for testing
# returns <- create_sample_data(n_obs = 3492, n_markets = 3)
# returns <- prepare_returns_data(returns)

# After loading data, save it for future use:
# saveRDS(returns, "data/returns.rds")

# To load saved data:
# returns <- readRDS("data/returns.rds")

# Then run the ABEKK analysis:
# source("abekk_analysis.R")

cat("\n=============================================================================\n")
cat("Data loading functions ready. Choose one of the methods above to load data.\n")
cat("=============================================================================\n\n")
