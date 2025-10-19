# Asymmetric Volatility Spillover Analysis

BUS 330 - Volatility spillovers between China, US, and Taiwan, with focus on the tech sector of Taiwan

## Overview

This repository implements a comprehensive asymmetric volatility spillover analysis framework for studying the interconnectedness between financial markets. The analysis focuses on China, US, and Taiwan markets, particularly the technology sector, using advanced econometric techniques.

## Key Features

- **Asymmetric Volatility Modeling**: GJR-GARCH(1,1) models to capture leverage effects and asymmetric responses to positive and negative shocks
- **Spillover Analysis**: Diebold-Yilmaz spillover index methodology using VAR models and forecast error variance decomposition (FEVD)
- **Rolling Window Analysis**: Time-varying spillover indices to track dynamic changes in market interconnectedness
- **Comprehensive Visualization**: Multiple plots for returns, conditional volatility, and spillover networks
- **Custom Data Support**: Functions to analyze custom datasets from CSV files

## Methodology

### 1. Asymmetric Volatility Modeling (GJR-GARCH)

The GJR-GARCH model captures asymmetric volatility responses:

```
σ²ₜ = ω + α·ε²ₜ₋₁ + γ·I(εₜ₋₁<0)·ε²ₜ₋₁ + β·σ²ₜ₋₁
```

Where:
- σ²ₜ is conditional variance
- γ is the asymmetry parameter (leverage effect)
- I(·) is an indicator function for negative shocks
- Positive γ indicates that negative shocks increase volatility more than positive shocks

### 2. Spillover Index (Diebold-Yilmaz)

The spillover index measures the proportion of forecast error variance in one market explained by shocks from other markets:

- **Total Spillover Index**: Overall connectedness across all markets
- **Directional Spillovers TO**: How much a market transmits to others
- **Directional Spillovers FROM**: How much a market receives from others
- **Net Spillovers**: Net transmission (TO - FROM)
- **Pairwise Spillovers**: Bilateral connections between specific markets

### 3. Rolling Window Analysis

Time-varying spillovers computed using rolling windows to identify:
- Periods of increased/decreased market integration
- Crisis episodes with heightened contagion
- Structural changes in market relationships

## Installation

### Required R Packages

The scripts will automatically install missing packages, but you can manually install them:

```r
install.packages(c("rugarch", "rmgarch", "zoo", "xts", "quantmod", 
                   "ggplot2", "reshape2", "gridExtra", "vars"))
```

## Usage

### Basic Usage (Download Data Automatically)

```r
# Source the main script
source("asymmetric_volatility_spillover.R")

# Run complete analysis
results <- run_spillover_analysis(
  start_date = "2015-01-01",
  end_date = Sys.Date(),
  lag_order = 2,           # VAR lag order
  n_ahead = 10,            # Forecast horizon
  window_size = 250,       # Rolling window size (approx. 1 year)
  run_rolling = TRUE       # Include rolling window analysis
)

# Display plots
print(results$plots$returns_plot)
print(results$plots$volatility_plot)
print(results$plots$spillover_plot)
print(results$plots$rolling_spillover_plot)

# View spillover table
print(results$spillover_result$spillover_table)

# Save results
saveRDS(results, "spillover_results.rds")
```

### Using Custom Data

```r
# Source both scripts
source("asymmetric_volatility_spillover.R")
source("custom_data_analysis.R")

# Analyze custom CSV data
results <- analyze_custom_data(
  file_path = "your_data.csv",
  date_column = "Date",
  market_columns = c("US_Tech", "China", "Taiwan_Tech"),
  output_dir = "my_results"
)

# Or load custom data manually
returns <- load_single_csv(
  file_path = "your_data.csv",
  date_column = "Date",
  market_columns = c("Market1", "Market2", "Market3")
)

# Then run analysis
gjr_models <- estimate_gjr_garch(returns)
std_residuals <- extract_standardized_residuals(gjr_models, returns)
spillover_result <- calculate_spillover_index(std_residuals)
```

### Advanced Analysis

```r
# Test for asymmetric effects
asymmetry_tests <- test_asymmetric_effects(results$gjr_models)

# Calculate pairwise spillovers
pairwise <- pairwise_spillovers(results$spillover_result)

# Calculate net pairwise spillovers
net_pairwise <- net_pairwise_spillovers(results$spillover_result)

# Generate comprehensive report
generate_report(results, output_dir = "spillover_results")
```

## Output Files

The analysis generates multiple outputs:

### CSV Files
- `descriptive_statistics.csv`: Summary statistics for returns
- `spillover_table.csv`: Complete spillover matrix with directional indices
- `garch_coefficients.csv`: GJR-GARCH model parameter estimates
- `asymmetry_tests.csv`: Tests for leverage effects
- `pairwise_spillovers.csv`: Bilateral spillover measures
- `net_pairwise_spillovers.csv`: Net spillover relationships
- `rolling_spillovers.csv`: Time-varying spillover indices

### Plots (PNG)
- `returns_plot.png`: Time series of market returns
- `volatility_plot.png`: Conditional volatility from GJR-GARCH models
- `spillover_plot.png`: Directional spillover bar chart
- `rolling_spillover_plot.png`: Rolling window spillover index

### R Objects
- `complete_results.rds`: Complete results object for further analysis

## Data Sources

By default, the script downloads data from Yahoo Finance:
- **US Tech**: S&P 500 Technology Sector ETF (XLK)
- **China**: FTSE China 50 Index ETF (FXI)
- **Taiwan Tech**: Taiwan Semiconductor Manufacturing (TSM)

You can modify the tickers in the `load_market_data()` function or provide your own CSV data.

## Interpreting Results

### GJR-GARCH Coefficients

- **γ (gamma)**: Asymmetry parameter
  - γ > 0: Leverage effect present (negative shocks increase volatility more)
  - γ = 0: Symmetric volatility response
  - Statistically significant γ confirms asymmetric behavior

### Spillover Table

The spillover table shows the percentage of forecast error variance in row markets explained by column markets:

```
         US_Tech  China  Taiwan_Tech  FROM
US_Tech    70%     15%      15%       30%
China      20%     65%      15%       35%
Taiwan     25%     20%      55%       45%
TO         45%     35%      30%       --
NET        15%      0%     -15%       --
```

- **Diagonal elements**: Own contribution (self-spillover)
- **Off-diagonal elements**: Cross-market spillovers
- **FROM**: Total spillover received from others
- **TO**: Total spillover transmitted to others
- **NET**: Net transmitter (positive) or receiver (negative)

### Total Spillover Index

- Higher values indicate greater market interconnectedness
- Typically increases during crisis periods
- Values typically range from 20% to 80%

## References

1. Diebold, F. X., & Yilmaz, K. (2012). Better to give than to receive: Predictive directional measurement of volatility spillovers. *International Journal of Forecasting*, 28(1), 57-66.

2. Glosten, L. R., Jagannathan, R., & Runkle, D. E. (1993). On the relation between the expected value and the volatility of the nominal excess return on stocks. *The Journal of Finance*, 48(5), 1779-1801.

3. Baruník, J., & Křehlík, T. (2018). Measuring the frequency dynamics of financial connectedness and systemic risk. *Journal of Financial Econometrics*, 16(2), 271-296.

## Contributing

For questions or issues, please open an issue on GitHub.

## License

This project is available for academic and research purposes.
