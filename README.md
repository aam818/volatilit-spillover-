# Volatility Spillover Analysis: US, China, and Taiwan Tech Sector

**Course**: BUS 330
**Topic**: Volatility spillovers between US, China, and Taiwan focusing on the tech sector

This project implements Asymmetric BEKK-GARCH models to analyze volatility spillovers and leverage effects across three markets.

## Overview

This repository contains R scripts for estimating Asymmetric BEKK (Baba-Engle-Kraft-Kroner) GARCH models to analyze:
- **Volatility spillovers** between US, China, and Taiwan tech sectors
- **Directional spillover effects** (which market transmits vs. receives volatility)
- **Asymmetric (leverage) effects** (differential impact of positive vs. negative shocks)
- **Short-run vs. long-run volatility persistence**

## Key Features

The corrected analysis script (`abekk_analysis.R`) addresses common issues with the BEKKs package and provides:

1. **Robust parameter extraction** - Correctly extracts C, A, B, G matrices from model estimates
2. **Comprehensive spillover analysis** - Calculates total, directional, and net spillovers
3. **Statistical significance testing** - Reports t-ratios and significance levels
4. **LaTeX table generation** - Publication-ready tables for academic papers
5. **Visualizations** - Professional plots for volatility dynamics and spillovers
6. **Error handling** - Validates data and handles edge cases

## Project Structure

```
volatilit-spillover-/
├── README.md                    # This file
├── abekk_analysis.R            # Main ABEKK estimation script (CORRECTED)
├── load_data.R                 # Data loading utilities
├── data/                       # Data directory (create this)
│   └── returns.csv             # Your return data
└── output/                     # Generated output (auto-created)
    ├── table_*.tex             # LaTeX tables
    ├── plot_*.png              # Visualizations
    └── abekk_results.rds       # Saved R results
```

## Installation

### Required R Packages

```r
install.packages(c("BEKKs", "xtable", "knitr", "ggplot2", "reshape2", "gridExtra"))

# For data loading (optional)
install.packages(c("xts", "quantmod"))
```

### System Requirements

- R version ≥ 4.0
- BEKKs package (for multivariate GARCH estimation)

## Usage

### Quick Start

1. **Load your data**:

```r
# Option 1: From CSV file
source("load_data.R")
returns <- load_from_csv("data/returns.csv", date_column = "Date")
returns <- prepare_returns_data(returns, market_names = c("US_ret", "CN_ret", "TW_ret"))

# Option 2: Download from Yahoo Finance
symbols <- c("QQQ", "FXI", "EWT")  # US Tech, China, Taiwan ETFs
returns <- load_from_yahoo(symbols, "2010-01-01", "2024-12-31")
returns <- prepare_returns_data(returns, market_names = c("US_ret", "CN_ret", "TW_ret"))

# Option 3: Use sample data for testing
returns <- create_sample_data(n_obs = 3492, n_markets = 3)
```

2. **Run the analysis**:

```r
source("abekk_analysis.R")
```

3. **View results**:

Results are automatically saved to the `output/` directory:
- LaTeX tables: `output/table_*.tex`
- Visualizations: `output/plot_*.png`
- R object: `output/abekk_results.rds`

### Advanced Usage

Load saved results for further analysis:

```r
results <- readRDS("output/abekk_results.rds")

# Access specific components
A_matrix <- results$parameters$A  # ARCH effects
B_matrix <- results$parameters$B  # Asymmetric effects
G_matrix <- results$parameters$G  # GARCH effects

spillover_summary <- results$spillover$summary
net_spillovers <- results$spillover$net
```

## Understanding the Output

### Parameter Matrices

- **C Matrix**: Lower triangular Cholesky factor of unconditional covariance
- **A Matrix**: Short-run shock spillovers (ARCH effects)
  - `A[i,j]` measures how shocks in market j affect volatility in market i
- **B Matrix**: Asymmetric/leverage effects
  - `B[i,j]` measures how negative shocks in market j affect volatility in market i
- **G Matrix**: Long-run volatility persistence (GARCH effects)
  - `G[i,j]` measures how past volatility in market j affects current volatility in market i

### Spillover Metrics

- **Spillover TO**: Total volatility a market receives from others
- **Spillover FROM**: Total volatility a market transmits to others
- **Net Spillover**: Spillover FROM - Spillover TO
  - Positive = Net transmitter of volatility
  - Negative = Net receiver of volatility

### Model Diagnostics

- **Log-Likelihood**: Higher is better (model fit)
- **AIC/BIC**: Lower is better (penalized fit)
- **Standardized residuals**: Should be approximately N(0,1)

## Data Requirements

### Input Format

Your data should be a matrix or data frame with:
- **Rows**: Time periods (daily observations recommended)
- **Columns**: Return series for each market
- **Format**: Returns in percentage (e.g., 1.5 for 1.5%)

Example CSV format:
```csv
Date,US_ret,CN_ret,TW_ret
2010-01-04,0.5,-0.3,0.8
2010-01-05,-0.2,0.4,0.1
...
```

### Data Collection Recommendations

For US-China-Taiwan tech sector analysis:

**US Tech**:
- QQQ (Nasdaq-100 ETF)
- SOXX (Semiconductor ETF)
- XLK (Technology Select Sector SPDR)

**China Tech**:
- FXI (China Large-Cap ETF)
- KWEB (China Internet ETF)
- MCHI (iShares MSCI China ETF)

**Taiwan Tech**:
- EWT (iShares Taiwan ETF)
- TSM (Taiwan Semiconductor ADR)

## Key Fixes in This Version

The original script had several critical errors that have been corrected:

### 1. **Parameter Extraction Issue** (FIXED)
**Problem**: `coef()` function returned NULL for all matrices
**Solution**: Direct extraction from `theta` vector with proper matrix reconstruction

```r
# OLD (broken):
params <- coef(asymmetric_bekk_fit)
C_matrix <- params$C  # Returns NULL

# NEW (fixed):
theta <- asymmetric_bekk_fit$theta
# Reconstruct matrices from theta vector
C_matrix <- matrix(...)  # Proper reconstruction
```

### 2. **Matrix Dimension Errors** (FIXED)
**Problem**: Attempting to set colnames on NULL objects
**Solution**: Validate matrices exist before adding dimensions

### 3. **Cascading Calculation Errors** (FIXED)
**Problem**: Spillover calculations failed due to NULL matrices
**Solution**: Ensure all parameter matrices are properly extracted first

### 4. **Visualization Errors** (FIXED)
**Problem**: Time index issues with xts objects
**Solution**: Use numeric time index when date information unavailable

### 5. **LaTeX Generation Errors** (FIXED)
**Problem**: Cannot create tables from NULL matrices
**Solution**: Validate matrix existence before table generation

## Output Files

### LaTeX Tables

All tables use `booktabs` package for professional formatting:

```latex
\usepackage{booktabs}
\input{output/table_A_matrix.tex}
```

Generated tables:
- `table_C_matrix.tex` - Constant matrix
- `table_A_matrix.tex` - ARCH effects
- `table_B_matrix.tex` - Asymmetric effects
- `table_G_matrix.tex` - GARCH effects
- `table_spillover.tex` - Total spillovers
- `table_summary.tex` - Model statistics

### Visualizations

High-resolution PNG plots (300 DPI):
- `plot_conditional_volatility.png` - Time series of conditional volatilities
- `plot_spillover_heatmap.png` - Spillover matrix heatmap
- `plot_directional_spillovers.png` - Transmitted vs. received spillovers
- `plot_net_spillover.png` - Net spillover positions

## Troubleshooting

### Common Issues

1. **"returns object not found"**
   - Run `load_data.R` first to create the `returns` object

2. **Package installation fails**
   - Ensure R version ≥ 4.0
   - Try installing from source: `install.packages("BEKKs", type = "source")`

3. **Model convergence issues**
   - Increase `max_iter` parameter
   - Check for missing values in data
   - Ensure sufficient observations (>500 recommended)

4. **Parameter extraction returns NULL**
   - Update BEKKs package: `update.packages("BEKKs")`
   - Check that model estimation completed successfully

## References

### Key Papers

- **BEKK Model**: Engle, R. F., & Kroner, K. F. (1995). "Multivariate simultaneous generalized ARCH." *Econometric Theory*, 11(1), 122-150.

- **Asymmetric GARCH**: Glosten, L. R., Jagannathan, R., & Runkle, D. E. (1993). "On the relation between the expected value and the volatility of the nominal excess return on stocks." *Journal of Finance*, 48(5), 1779-1801.

- **Volatility Spillovers**: Diebold, F. X., & Yilmaz, K. (2012). "Better to give than to receive: Predictive directional measurement of volatility spillovers." *International Journal of Forecasting*, 28(1), 57-66.

### R Packages

- **BEKKs**: Hafner, C. M., & Herwartz, H. (2008). "Analytical quasi maximum likelihood inference in multivariate volatility models."

## Contributing

Suggestions and improvements welcome! Please open an issue or submit a pull request.

## License

This project is for academic use in BUS 330.

## Contact

For questions about this analysis, please contact the course instructor or TA.

---

**Last Updated**: 2025-10-29
**Status**: Corrected and tested ✓ 
