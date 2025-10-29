################################################################################
# Data Loading Template for ABEKK Analysis
#
# This script provides examples for loading financial returns data
# in various formats for use with the ABEKK estimation script.
#
# Modify this script according to your data source and format.
################################################################################

# Load required packages
library(xts)
library(zoo)

# ==============================================================================
# OPTION 1: Load from CSV file
# ==============================================================================

load_from_csv <- function(file_path, date_column = 1) {
  cat("Loading data from CSV...\n")

  # Read CSV file
  data <- read.csv(file_path, stringsAsFactors = FALSE)

  # Extract dates (assumes first column is dates)
  dates <- as.Date(data[, date_column])

  # Extract returns (all columns except date column)
  returns_data <- as.matrix(data[, -date_column])

  # Create xts object
  returns <- xts(returns_data, order.by = dates)

  # Set column names if needed
  if (is.null(colnames(returns))) {
    colnames(returns) <- paste0("Market", 1:ncol(returns))
  }

  cat(sprintf("Loaded %d observations for %d markets\n",
              nrow(returns), ncol(returns)))
  cat(sprintf("Date range: %s to %s\n",
              format(min(dates), "%Y-%m-%d"),
              format(max(dates), "%Y-%m-%d")))

  return(returns)
}

# Example usage:
# returns <- load_from_csv("data/returns.csv", date_column = 1)

# ==============================================================================
# OPTION 2: Load from Excel file
# ==============================================================================

load_from_excel <- function(file_path, sheet = 1, date_column = 1) {
  cat("Loading data from Excel...\n")

  # Install readxl if needed
  if (!require("readxl")) install.packages("readxl")
  library(readxl)

  # Read Excel file
  data <- as.data.frame(read_excel(file_path, sheet = sheet))

  # Extract dates
  dates <- as.Date(data[, date_column])

  # Extract returns
  returns_data <- as.matrix(data[, -date_column])

  # Create xts object
  returns <- xts(returns_data, order.by = dates)

  cat(sprintf("Loaded %d observations for %d markets\n",
              nrow(returns), ncol(returns)))

  return(returns)
}

# Example usage:
# returns <- load_from_excel("data/returns.xlsx", sheet = "Returns", date_column = 1)

# ==============================================================================
# OPTION 3: Download from Yahoo Finance
# ==============================================================================

load_from_yahoo <- function(symbols, start_date, end_date) {
  cat("Downloading data from Yahoo Finance...\n")

  # Install quantmod if needed
  if (!require("quantmod")) install.packages("quantmod")
  library(quantmod)

  # Download data
  prices_list <- lapply(symbols, function(sym) {
    cat(sprintf("Downloading %s...\n", sym))
    getSymbols(sym, from = start_date, to = end_date, auto.assign = FALSE)
  })

  # Extract adjusted close prices
  prices <- do.call(merge, lapply(prices_list, function(x) Ad(x)))
  colnames(prices) <- symbols

  # Calculate returns (log returns)
  returns <- diff(log(prices))[-1, ]

  cat(sprintf("Downloaded %d observations for %d symbols\n",
              nrow(returns), ncol(returns)))
  cat(sprintf("Date range: %s to %s\n",
              format(start(returns), "%Y-%m-%d"),
              format(end(returns), "%Y-%m-%d")))

  return(returns)
}

# Example usage:
# symbols <- c("^GSPC", "000001.SS", "^STOXX50E")  # S&P 500, Shanghai, Euro Stoxx
# returns <- load_from_yahoo(symbols, "2015-01-01", "2023-12-31")

# ==============================================================================
# OPTION 4: Load from RDS file
# ==============================================================================

load_from_rds <- function(file_path) {
  cat("Loading data from RDS file...\n")

  returns <- readRDS(file_path)

  # Verify it's in correct format
  if (!is.xts(returns) && !is.zoo(returns) && !is.matrix(returns)) {
    stop("RDS file must contain xts, zoo, or matrix object")
  }

  cat(sprintf("Loaded %d observations for %d markets\n",
              nrow(returns), ncol(returns)))

  return(returns)
}

# Example usage:
# returns <- load_from_rds("data/returns.rds")

# ==============================================================================
# OPTION 5: Create sample data for testing
# ==============================================================================

create_sample_data <- function(n_obs = 1000, n_markets = 3,
                               start_date = "2020-01-01") {
  cat("Creating sample data...\n")

  # Set seed for reproducibility
  set.seed(123)

  # Create dates
  dates <- seq(as.Date(start_date), by = "day", length.out = n_obs)

  # Simulate correlated returns using a simple DGP
  # Create correlation matrix
  rho <- 0.3  # Average correlation
  cor_matrix <- matrix(rho, n_markets, n_markets)
  diag(cor_matrix) <- 1

  # Cholesky decomposition
  L <- chol(cor_matrix)

  # Generate independent normal innovations
  innovations <- matrix(rnorm(n_obs * n_markets), n_obs, n_markets)

  # Create correlated returns
  returns_data <- innovations %*% L * 0.01  # Scale to reasonable return magnitude

  # Add some time-varying volatility
  for (i in 1:n_markets) {
    garch_sim <- rep(0, n_obs)
    h <- 0.01^2
    for (t in 2:n_obs) {
      h <- 0.00001 + 0.05 * returns_data[t-1, i]^2 + 0.90 * h
      returns_data[t, i] <- returns_data[t, i] * sqrt(h)
    }
  }

  # Create xts object
  returns <- xts(returns_data, order.by = dates)
  colnames(returns) <- paste0("Market", 1:n_markets)

  cat(sprintf("Created %d observations for %d markets\n",
              nrow(returns), ncol(returns)))

  return(returns)
}

# Example usage:
# returns <- create_sample_data(n_obs = 1000, n_markets = 3)

# ==============================================================================
# DATA QUALITY CHECKS
# ==============================================================================

check_data_quality <- function(returns) {
  cat("\n================================\n")
  cat("DATA QUALITY CHECKS\n")
  cat("================================\n\n")

  # Check for missing values
  n_missing <- sum(is.na(returns))
  if (n_missing > 0) {
    cat(sprintf("WARNING: %d missing values detected\n", n_missing))
    cat("Missing values by column:\n")
    print(colSums(is.na(returns)))
  } else {
    cat("No missing values detected\n")
  }

  # Check for infinite values
  n_infinite <- sum(is.infinite(returns))
  if (n_infinite > 0) {
    cat(sprintf("WARNING: %d infinite values detected\n", n_infinite))
  } else {
    cat("No infinite values detected\n")
  }

  # Check for extreme outliers (> 5 standard deviations)
  outliers <- apply(returns, 2, function(x) {
    z_scores <- abs((x - mean(x, na.rm=TRUE)) / sd(x, na.rm=TRUE))
    sum(z_scores > 5, na.rm=TRUE)
  })

  if (sum(outliers) > 0) {
    cat("\nExtreme outliers (|z| > 5) by market:\n")
    print(outliers)
  } else {
    cat("No extreme outliers detected\n")
  }

  # Check for zero variance
  variances <- apply(returns, 2, var, na.rm=TRUE)
  if (any(variances == 0)) {
    cat("\nWARNING: Zero variance detected in:\n")
    print(names(variances)[variances == 0])
  }

  # Display summary statistics
  cat("\nSummary Statistics:\n")
  print(summary(returns))

  # Check stationarity (simple check: mean and variance in first/second half)
  n <- nrow(returns)
  half <- floor(n/2)

  cat("\nStability Check (First half vs Second half):\n")
  mean_1 <- apply(returns[1:half, ], 2, mean, na.rm=TRUE)
  mean_2 <- apply(returns[(half+1):n, ], 2, mean, na.rm=TRUE)
  var_1 <- apply(returns[1:half, ], 2, var, na.rm=TRUE)
  var_2 <- apply(returns[(half+1):n, ], 2, var, na.rm=TRUE)

  stability <- data.frame(
    Market = colnames(returns),
    Mean_1st = mean_1,
    Mean_2nd = mean_2,
    Var_1st = var_1,
    Var_2nd = var_2
  )
  print(stability)

  cat("\n================================\n\n")

  return(invisible(NULL))
}

# ==============================================================================
# DATA PREPROCESSING
# ==============================================================================

preprocess_returns <- function(returns,
                               remove_na = TRUE,
                               winsorize = FALSE,
                               winsorize_quantiles = c(0.01, 0.99)) {
  cat("Preprocessing returns data...\n")

  original_n <- nrow(returns)

  # Remove missing values
  if (remove_na) {
    returns <- na.omit(returns)
    removed <- original_n - nrow(returns)
    if (removed > 0) {
      cat(sprintf("Removed %d rows with missing values\n", removed))
    }
  }

  # Winsorize extreme values
  if (winsorize) {
    cat(sprintf("Winsorizing at %.1f%% and %.1f%% quantiles\n",
                winsorize_quantiles[1]*100, winsorize_quantiles[2]*100))

    for (i in 1:ncol(returns)) {
      q_low <- quantile(returns[,i], winsorize_quantiles[1], na.rm=TRUE)
      q_high <- quantile(returns[,i], winsorize_quantiles[2], na.rm=TRUE)

      returns[,i] <- pmin(pmax(returns[,i], q_low), q_high)
    }
  }

  cat(sprintf("Final dataset: %d observations\n", nrow(returns)))

  return(returns)
}

# ==============================================================================
# EXAMPLE WORKFLOW
# ==============================================================================

# Uncomment and modify based on your data source:

# 1. Load data (choose one method)
# returns <- load_from_csv("data/returns.csv")
# returns <- load_from_excel("data/returns.xlsx")
# returns <- load_from_yahoo(c("^GSPC", "000001.SS", "^STOXX50E"), "2015-01-01", "2023-12-31")
# returns <- create_sample_data(n_obs = 1000, n_markets = 3)

# 2. Check data quality
# check_data_quality(returns)

# 3. Preprocess if needed
# returns <- preprocess_returns(returns, remove_na = TRUE, winsorize = FALSE)

# 4. Verify final data
# cat("\nFinal returns object ready for ABEKK estimation:\n")
# str(returns)
# head(returns)

# 5. Run ABEKK estimation
# source("abekk_estimation.R")

################################################################################
# END OF DATA LOADING TEMPLATE
################################################################################

cat("\nData loading template loaded.\n")
cat("Modify the example workflow section to load your specific data.\n")
cat("Available functions:\n")
cat("  - load_from_csv()\n")
cat("  - load_from_excel()\n")
cat("  - load_from_yahoo()\n")
cat("  - load_from_rds()\n")
cat("  - create_sample_data()\n")
cat("  - check_data_quality()\n")
cat("  - preprocess_returns()\n\n")
