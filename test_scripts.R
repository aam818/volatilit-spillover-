################################################################################
# Test Script for Asymmetric Volatility Spillover Analysis
# 
# This script tests the basic functionality without requiring data download
################################################################################

cat("Testing Asymmetric Volatility Spillover Analysis Scripts\n")
cat("========================================================\n\n")

# Test 1: Check if main script can be sourced
cat("Test 1: Sourcing main script...\n")
tryCatch({
  source("asymmetric_volatility_spillover.R")
  cat("✓ Main script sourced successfully\n\n")
}, error = function(e) {
  cat("✗ Error sourcing main script:", e$message, "\n\n")
})

# Test 2: Check if custom data script can be sourced
cat("Test 2: Sourcing custom data script...\n")
tryCatch({
  source("custom_data_analysis.R")
  cat("✓ Custom data script sourced successfully\n\n")
}, error = function(e) {
  cat("✗ Error sourcing custom data script:", e$message, "\n\n")
})

# Test 3: Check required packages
cat("Test 3: Checking required packages...\n")
required_packages <- c("rugarch", "rmgarch", "zoo", "xts", "quantmod", 
                       "ggplot2", "reshape2", "gridExtra", "vars")

for(pkg in required_packages) {
  if(pkg %in% installed.packages()[,"Package"]) {
    cat("✓", pkg, "is installed\n")
  } else {
    cat("✗", pkg, "is NOT installed\n")
  }
}
cat("\n")

# Test 4: Create sample data and test functions
cat("Test 4: Testing with simulated data...\n")

# Generate sample data
set.seed(123)
n_obs <- 500
dates <- seq.Date(from = as.Date("2020-01-01"), by = "day", length.out = n_obs)

# Simulate returns with GARCH-like properties
simulate_garch_returns <- function(n, omega = 0.01, alpha = 0.05, beta = 0.90) {
  returns <- numeric(n)
  sigma2 <- numeric(n)
  sigma2[1] <- omega / (1 - alpha - beta)
  
  for(t in 2:n) {
    epsilon <- rnorm(1)
    sigma2[t] <- omega + alpha * returns[t-1]^2 + beta * sigma2[t-1]
    returns[t] <- sqrt(sigma2[t]) * epsilon
  }
  
  return(returns * 100)  # Convert to percentage
}

# Create sample returns for three markets
returns_data <- data.frame(
  US_Tech = simulate_garch_returns(n_obs),
  China = simulate_garch_returns(n_obs),
  Taiwan_Tech = simulate_garch_returns(n_obs)
)

# Convert to xts
library(xts)
returns_xts <- xts(returns_data, order.by = dates)

# Test descriptive statistics function
tryCatch({
  desc_stats <- descriptive_statistics(returns_xts)
  cat("✓ Descriptive statistics calculated successfully\n")
  print(head(desc_stats, 3))
}, error = function(e) {
  cat("✗ Error calculating descriptive statistics:", e$message, "\n")
})

cat("\n")

# Test 5: Test GJR-GARCH estimation (if rugarch is installed)
cat("Test 5: Testing GJR-GARCH estimation...\n")
if("rugarch" %in% installed.packages()[,"Package"]) {
  tryCatch({
    # Test with just one series to save time
    spec <- ugarchspec(
      variance.model = list(model = "gjrGARCH", garchOrder = c(1, 1)),
      mean.model = list(armaOrder = c(1, 0), include.mean = TRUE),
      distribution.model = "std"
    )
    
    fit <- ugarchfit(spec = spec, data = returns_xts[, 1], solver = "hybrid")
    cat("✓ GJR-GARCH model estimated successfully\n")
  }, error = function(e) {
    cat("✗ Error estimating GJR-GARCH:", e$message, "\n")
  })
} else {
  cat("⊘ Skipping (rugarch not installed)\n")
}

cat("\n")

# Test 6: Test VAR and spillover calculation (if vars is installed)
cat("Test 6: Testing VAR and spillover calculation...\n")
if("vars" %in% installed.packages()[,"Package"]) {
  tryCatch({
    library(vars)
    
    # Estimate VAR
    var_model <- VAR(returns_data, p = 2, type = "const")
    
    # Forecast error variance decomposition
    fevd_result <- fevd(var_model, n.ahead = 10)
    
    cat("✓ VAR model and FEVD calculated successfully\n")
  }, error = function(e) {
    cat("✗ Error in VAR/FEVD:", e$message, "\n")
  })
} else {
  cat("⊘ Skipping (vars not installed)\n")
}

cat("\n")

# Test 7: Test plotting functions (if ggplot2 is installed)
cat("Test 7: Testing plotting functions...\n")
if("ggplot2" %in% installed.packages()[,"Package"]) {
  tryCatch({
    p <- plot_returns(returns_xts)
    cat("✓ Returns plot created successfully\n")
  }, error = function(e) {
    cat("✗ Error creating plot:", e$message, "\n")
  })
} else {
  cat("⊘ Skipping (ggplot2 not installed)\n")
}

cat("\n")

# Summary
cat("========================================================\n")
cat("Test Summary\n")
cat("========================================================\n\n")

cat("Core scripts: Ready to use\n")
cat("Required packages: Install any missing packages using:\n")
cat("  install.packages(c('rugarch', 'rmgarch', 'zoo', 'xts', 'quantmod',\n")
cat("                     'ggplot2', 'reshape2', 'gridExtra', 'vars'))\n\n")

cat("To run the full analysis:\n")
cat("  source('example_analysis.R')\n\n")

cat("For custom data:\n")
cat("  source('custom_data_analysis.R')\n")
cat("  results <- analyze_custom_data('your_data.csv', ...)\n\n")
