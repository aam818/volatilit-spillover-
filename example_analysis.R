################################################################################
# Example Analysis Script
# 
# This script demonstrates how to run the asymmetric volatility spillover
# analysis for China, US, and Taiwan markets
################################################################################

# Clear workspace
rm(list = ls())

# Set working directory (adjust as needed)
# setwd("your/path/to/project")

# Source the main analysis scripts
source("asymmetric_volatility_spillover.R")
source("custom_data_analysis.R")

################################################################################
# EXAMPLE 1: Basic Analysis with Automatic Data Download
################################################################################

cat("\n")
cat("========================================\n")
cat("EXAMPLE 1: Basic Analysis\n")
cat("========================================\n\n")

# Run analysis with default parameters
# This will download data from Yahoo Finance for:
# - US Tech (XLK): S&P 500 Technology Sector
# - China (FXI): FTSE China 50 Index
# - Taiwan Tech (TSM): Taiwan Semiconductor
results_basic <- run_spillover_analysis(
  start_date = "2018-01-01",
  end_date = Sys.Date(),
  lag_order = 2,
  n_ahead = 10,
  window_size = 250,
  run_rolling = TRUE
)

# Display key results
cat("\n--- Key Findings ---\n")
cat("Total Spillover Index:", round(results_basic$spillover_result$total_spillover, 2), "%\n\n")

cat("Net Spillover Effects:\n")
net_spillovers <- results_basic$spillover_result$net_spillovers
for(i in seq_along(net_spillovers)) {
  market <- names(net_spillovers)[i]
  value <- net_spillovers[i]
  direction <- ifelse(value > 0, "net transmitter", "net receiver")
  cat(sprintf("  %s: %.2f%% (%s)\n", market, abs(value), direction))
}

# Display plots
cat("\nDisplaying plots...\n")
print(results_basic$plots$returns_plot)
Sys.sleep(2)
print(results_basic$plots$volatility_plot)
Sys.sleep(2)
print(results_basic$plots$spillover_plot)
Sys.sleep(2)
if(!is.null(results_basic$plots$rolling_spillover_plot)) {
  print(results_basic$plots$rolling_spillover_plot)
}

################################################################################
# EXAMPLE 2: Generate Comprehensive Report
################################################################################

cat("\n")
cat("========================================\n")
cat("EXAMPLE 2: Generate Report\n")
cat("========================================\n\n")

# Generate comprehensive report with all outputs
generate_report(results_basic, output_dir = "example_results")

cat("\nReport generated! Check the 'example_results' folder for outputs.\n")

################################################################################
# EXAMPLE 3: Advanced Analysis - Asymmetry Tests
################################################################################

cat("\n")
cat("========================================\n")
cat("EXAMPLE 3: Asymmetry Tests\n")
cat("========================================\n\n")

# Test for asymmetric volatility effects (leverage effect)
asymmetry_results <- test_asymmetric_effects(results_basic$gjr_models)

cat("\nInterpretation:\n")
cat("- Positive gamma indicates negative shocks increase volatility more (leverage effect)\n")
cat("- Statistically significant gamma confirms asymmetric behavior\n\n")

################################################################################
# EXAMPLE 4: Pairwise Spillover Analysis
################################################################################

cat("\n")
cat("========================================\n")
cat("EXAMPLE 4: Pairwise Analysis\n")
cat("========================================\n\n")

# Calculate pairwise spillovers
pairwise_results <- pairwise_spillovers(results_basic$spillover_result)

# Calculate net pairwise spillovers
net_pairwise_results <- net_pairwise_spillovers(results_basic$spillover_result)

cat("\nInterpretation:\n")
cat("- Pairwise spillovers show bilateral connections\n")
cat("- Net pairwise shows which market dominates in each pair\n\n")

################################################################################
# EXAMPLE 5: Shorter Sample Period (Recent Data Only)
################################################################################

cat("\n")
cat("========================================\n")
cat("EXAMPLE 5: Recent Data Analysis\n")
cat("========================================\n\n")

# Analyze only recent 2 years
recent_start <- as.character(Sys.Date() - 365*2)

results_recent <- run_spillover_analysis(
  start_date = recent_start,
  end_date = Sys.Date(),
  lag_order = 2,
  n_ahead = 10,
  window_size = 200,  # Smaller window for shorter period
  run_rolling = FALSE  # Skip rolling analysis for shorter period
)

cat("\n--- Comparison: Recent vs Full Sample ---\n")
cat("Recent Period Total Spillover:", 
    round(results_recent$spillover_result$total_spillover, 2), "%\n")
cat("Full Sample Total Spillover:", 
    round(results_basic$spillover_result$total_spillover, 2), "%\n\n")

################################################################################
# EXAMPLE 6: Different VAR Specifications
################################################################################

cat("\n")
cat("========================================\n")
cat("EXAMPLE 6: Sensitivity Analysis\n")
cat("========================================\n\n")

cat("Testing different VAR lag orders...\n\n")

# Extract standardized residuals from basic analysis
std_residuals <- results_basic$std_residuals

# Test different lag orders
lag_orders <- c(1, 2, 3, 4)
spillover_by_lag <- data.frame(
  Lag_Order = integer(),
  Total_Spillover = numeric()
)

for(lag in lag_orders) {
  cat("Lag order:", lag, "\n")
  spillover_result <- calculate_spillover_index(
    std_residuals, 
    lag_order = lag, 
    n_ahead = 10
  )
  
  spillover_by_lag <- rbind(spillover_by_lag, data.frame(
    Lag_Order = lag,
    Total_Spillover = spillover_result$total_spillover
  ))
}

cat("\n--- Spillover Index by VAR Lag Order ---\n")
print(spillover_by_lag)
cat("\n")

# Plot sensitivity
p_sensitivity <- ggplot(spillover_by_lag, aes(x = Lag_Order, y = Total_Spillover)) +
  geom_line(color = "blue", size = 1) +
  geom_point(color = "red", size = 3) +
  theme_minimal() +
  labs(title = "Total Spillover Index Sensitivity to VAR Lag Order",
       x = "VAR Lag Order",
       y = "Total Spillover Index (%)") +
  scale_x_continuous(breaks = lag_orders)

print(p_sensitivity)

################################################################################
# EXAMPLE 7: Export Data for External Use
################################################################################

cat("\n")
cat("========================================\n")
cat("EXAMPLE 7: Export Data\n")
cat("========================================\n\n")

# Create exports directory
if(!dir.exists("exports")) {
  dir.create("exports")
}

# Export returns data
returns_df <- data.frame(
  Date = index(results_basic$returns),
  results_basic$returns
)
write.csv(returns_df, "exports/returns_data.csv", row.names = FALSE)

# Export conditional volatility
vol_df <- data.frame(
  Date = index(results_basic$returns)
)
for(name in names(results_basic$gjr_models)) {
  vol_df[[paste0(name, "_volatility")]] <- sigma(results_basic$gjr_models[[name]])
}
write.csv(vol_df, "exports/conditional_volatility.csv", row.names = FALSE)

# Export standardized residuals
resid_df <- data.frame(
  Date = index(results_basic$std_residuals),
  results_basic$std_residuals
)
write.csv(resid_df, "exports/standardized_residuals.csv", row.names = FALSE)

cat("Data exported to 'exports/' folder:\n")
cat("- returns_data.csv\n")
cat("- conditional_volatility.csv\n")
cat("- standardized_residuals.csv\n\n")

################################################################################
# SUMMARY
################################################################################

cat("\n")
cat("========================================\n")
cat("ANALYSIS COMPLETE\n")
cat("========================================\n\n")

cat("Summary of outputs:\n")
cat("1. Basic analysis results saved in memory\n")
cat("2. Comprehensive report in 'example_results/' folder\n")
cat("3. Exported data in 'exports/' folder\n\n")

cat("To access results:\n")
cat("- View spillover table: results_basic$spillover_result$spillover_table\n")
cat("- View GJR-GARCH models: results_basic$gjr_models\n")
cat("- View plots: results_basic$plots\n")
cat("- Load saved results: readRDS('example_results/complete_results.rds')\n\n")

cat("For custom data analysis, use:\n")
cat("source('custom_data_analysis.R')\n")
cat("results <- analyze_custom_data('your_data.csv', market_columns = c('col1', 'col2', 'col3'))\n\n")
