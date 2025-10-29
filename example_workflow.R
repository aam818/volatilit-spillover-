# =============================================================================
# EXAMPLE WORKFLOW
# Complete demonstration of ABEKK analysis from data loading to results
# =============================================================================

cat("=============================================================================\n")
cat("ABEKK VOLATILITY SPILLOVER ANALYSIS - EXAMPLE WORKFLOW\n")
cat("=============================================================================\n\n")

# =============================================================================
# STEP 1: Load data loading functions
# =============================================================================

cat("STEP 1: Loading data utilities...\n")
source("load_data.R")
cat("Data loading functions ready.\n\n")

# =============================================================================
# STEP 2: Choose your data source
# =============================================================================

cat("STEP 2: Loading return data...\n")
cat("Choose one of the following options:\n\n")

# -----------------------------------------------------------------------------
# OPTION A: Download real data from Yahoo Finance (recommended for quick demo)
# -----------------------------------------------------------------------------

cat("Using Option A: Yahoo Finance data\n")
cat("Downloading US (QQQ), China (FXI), Taiwan (EWT) data...\n\n")

# Uncomment these lines to download real data:
# symbols <- c("QQQ", "FXI", "EWT")
# returns <- load_from_yahoo(symbols, "2010-01-01", "2024-10-01")
# returns <- prepare_returns_data(returns, market_names = c("US_ret", "CN_ret", "TW_ret"))

# -----------------------------------------------------------------------------
# OPTION B: Use sample data (for quick testing without internet)
# -----------------------------------------------------------------------------

cat("Using Option B: Sample synthetic data for testing\n\n")

# Generate sample data
returns <- create_sample_data(n_obs = 3492, n_markets = 3,
                             market_names = c("US_ret", "CN_ret", "TW_ret"))
returns <- prepare_returns_data(returns)

# -----------------------------------------------------------------------------
# OPTION C: Load from CSV file
# -----------------------------------------------------------------------------

# Uncomment these lines if you have your own CSV file:
# returns <- load_from_csv("data/returns.csv", date_column = "Date")
# returns <- prepare_returns_data(returns, market_names = c("US_ret", "CN_ret", "TW_ret"))

cat("\n")

# =============================================================================
# STEP 3: Run ABEKK analysis
# =============================================================================

cat("=============================================================================\n")
cat("STEP 3: Running ABEKK model estimation...\n")
cat("This will take several minutes. Please wait...\n")
cat("=============================================================================\n\n")

# Run the main analysis script
source("abekk_analysis.R")

cat("\n")

# =============================================================================
# STEP 4: Examine results
# =============================================================================

cat("=============================================================================\n")
cat("STEP 4: Examining results...\n")
cat("=============================================================================\n\n")

# Load the saved results
if (file.exists("output/abekk_results.rds")) {
  results <- readRDS("output/abekk_results.rds")

  cat("Results loaded successfully!\n\n")

  cat("Quick Summary:\n")
  cat("--------------\n")
  cat(sprintf("Markets analyzed: %s\n",
              paste(results$data_info$markets, collapse=", ")))
  cat(sprintf("Number of observations: %d\n", results$data_info$n_obs))
  cat(sprintf("Log-likelihood: %.4f\n", results$diagnostics$log_likelihood))
  cat(sprintf("AIC: %.4f\n", results$diagnostics$AIC))
  cat(sprintf("BIC: %.4f\n\n", results$diagnostics$BIC))

  cat("Net Spillover Effects:\n")
  cat("----------------------\n")
  print(results$spillover$summary)
  cat("\n")

  cat("Interpretation:\n")
  cat("---------------\n")
  for (i in 1:length(results$data_info$markets)) {
    market <- results$data_info$markets[i]
    net <- results$spillover$net[i]
    if (net > 0) {
      cat(sprintf("- %s: NET TRANSMITTER (sends %.4f more volatility than receives)\n",
                  market, net))
    } else {
      cat(sprintf("- %s: NET RECEIVER (receives %.4f more volatility than sends)\n",
                  market, abs(net)))
    }
  }
  cat("\n")

  cat("Parameter Matrices:\n")
  cat("-------------------\n")
  cat("\nARCH Matrix (A) - Short-run shock spillovers:\n")
  print(round(results$parameters$A, 4))

  cat("\nAsymmetric Matrix (B) - Leverage effects:\n")
  print(round(results$parameters$B, 4))

  cat("\nGARCH Matrix (G) - Long-run persistence:\n")
  print(round(results$parameters$G, 4))

  cat("\n")
} else {
  cat("Warning: Results file not found. Check for errors in the analysis.\n\n")
}

# =============================================================================
# STEP 5: View output files
# =============================================================================

cat("=============================================================================\n")
cat("STEP 5: Output files created\n")
cat("=============================================================================\n\n")

if (dir.exists("output")) {
  output_files <- list.files("output", full.names = FALSE)
  if (length(output_files) > 0) {
    cat("Files in output/ directory:\n")
    for (f in output_files) {
      cat(sprintf("  - %s\n", f))
    }
    cat("\n")
  }
}

# =============================================================================
# NEXT STEPS
# =============================================================================

cat("=============================================================================\n")
cat("NEXT STEPS\n")
cat("=============================================================================\n\n")

cat("1. View visualizations:\n")
cat("   Open the PNG files in output/ directory\n\n")

cat("2. Use LaTeX tables in your paper:\n")
cat("   Add to preamble: \\usepackage{booktabs}\n")
cat("   Include table: \\input{output/table_A_matrix.tex}\n\n")

cat("3. Further analysis:\n")
cat("   results <- readRDS('output/abekk_results.rds')\n")
cat("   # Access any component of the results\n\n")

cat("4. Customize the analysis:\n")
cat("   - Edit abekk_analysis.R to modify parameters\n")
cat("   - Adjust model specification (asymmetric, BEKK type, etc.)\n")
cat("   - Change visualization options\n\n")

cat("=============================================================================\n")
cat("WORKFLOW COMPLETE!\n")
cat("=============================================================================\n")
