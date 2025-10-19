# Quick Start Guide

## Prerequisites

- R version 4.0.0 or higher
- RStudio (recommended but not required)

## Installation Steps

1. **Clone or download this repository**

2. **Open R or RStudio**

3. **Set working directory to the project folder**
   ```r
   setwd("path/to/volatilit-spillover-")
   ```

4. **Install required packages** (if not already installed)
   ```r
   install.packages(c("rugarch", "rmgarch", "zoo", "xts", "quantmod", 
                      "ggplot2", "reshape2", "gridExtra", "vars"))
   ```

## Running the Analysis

### Option 1: Run Example Script (Recommended for First Time)

```r
source("example_analysis.R")
```

This will:
- Download market data automatically from Yahoo Finance
- Estimate GJR-GARCH models
- Calculate spillover indices
- Generate visualizations
- Create a comprehensive report in `example_results/` folder

### Option 2: Custom Analysis

```r
# Load the main script
source("asymmetric_volatility_spillover.R")

# Run analysis with your preferred parameters
results <- run_spillover_analysis(
  start_date = "2018-01-01",    # Adjust start date
  end_date = Sys.Date(),        # Or specify end date
  lag_order = 2,                # VAR lag order
  n_ahead = 10,                 # Forecast horizon
  window_size = 250,            # Rolling window size
  run_rolling = TRUE            # Include rolling analysis
)

# View results
print(results$spillover_result$spillover_table)
print(results$plots$spillover_plot)
```

### Option 3: Use Your Own Data

If you have your own CSV file with market data:

```r
# Load scripts
source("asymmetric_volatility_spillover.R")
source("custom_data_analysis.R")

# Analyze your data
results <- analyze_custom_data(
  file_path = "path/to/your_data.csv",
  date_column = "Date",
  market_columns = c("US_Market", "China_Market", "Taiwan_Market"),
  output_dir = "my_results"
)
```

**CSV Format Requirements:**
- Must have a date column (any name, specify in `date_column` parameter)
- Must have at least 2 market/stock price columns
- Dates should be in format: YYYY-MM-DD or specify format
- Example:

```csv
Date,US_Tech,China,Taiwan_Tech
2018-01-02,150.25,75.30,42.15
2018-01-03,151.50,76.20,42.80
...
```

## Understanding the Output

### Console Output
- Descriptive statistics for returns
- GJR-GARCH model coefficients
- Spillover table showing directional connections
- Total spillover index

### Generated Files (in output directory)
- **CSV files**: Numerical results and tables
- **PNG files**: Visualization plots
- **RDS files**: Complete R objects for further analysis

### Key Metrics to Look For

1. **Total Spillover Index**: Overall market connectedness (higher = more integrated)

2. **Net Spillovers**: 
   - Positive = net transmitter (sends more than receives)
   - Negative = net receiver (receives more than sends)

3. **Gamma Coefficient (γ)**: 
   - Positive and significant = leverage effect present
   - Negative shocks increase volatility more than positive shocks

4. **Pairwise Spillovers**: Shows bilateral relationships between markets

## Troubleshooting

### Problem: Package installation fails
**Solution**: Try installing packages one at a time:
```r
install.packages("rugarch")
install.packages("rmgarch")
# etc.
```

### Problem: Data download fails
**Solution**: 
1. Check internet connection
2. Try different date ranges
3. Use custom data instead (see Option 3 above)

### Problem: VAR estimation error
**Solution**: 
1. Check for sufficient data (need at least 100-200 observations)
2. Try different lag orders (1-4)
3. Check for missing values in data

### Problem: Out of memory error
**Solution**:
1. Use shorter date range
2. Skip rolling window analysis: `run_rolling = FALSE`
3. Reduce window size in rolling analysis

## Example Workflow

```r
# 1. Load the scripts
source("asymmetric_volatility_spillover.R")

# 2. Load data (automatically downloads from Yahoo Finance)
returns <- load_market_data(
  start_date = "2018-01-01",
  end_date = "2023-12-31"
)

# 3. View descriptive statistics
desc_stats <- descriptive_statistics(returns)
print(desc_stats)

# 4. Estimate GJR-GARCH models
gjr_models <- estimate_gjr_garch(returns)

# 5. Extract standardized residuals
std_residuals <- extract_standardized_residuals(gjr_models, returns)

# 6. Calculate spillover index
spillover_result <- calculate_spillover_index(std_residuals)

# 7. View spillover table
print(spillover_result$spillover_table)

# 8. Generate visualizations
plot_returns(returns)
plot_conditional_volatility(gjr_models)
plot_spillover_network(spillover_result)

# 9. Optional: Rolling window analysis
rolling_spillovers <- rolling_spillover_analysis(std_residuals, window_size = 250)
plot_rolling_spillovers(rolling_spillovers)
```

## Tips for Better Results

1. **Sample Size**: Use at least 2-3 years of daily data (500+ observations)

2. **Data Quality**: Ensure no large gaps in data; handle missing values appropriately

3. **Model Selection**: 
   - Start with lag_order = 2
   - Use n_ahead = 10 for standard analysis
   - Adjust based on information criteria if needed

4. **Interpretation**:
   - Compare results across different time periods
   - Look for changes during crisis periods
   - Consider economic events when interpreting spillovers

5. **Validation**:
   - Check model diagnostics (residual autocorrelation)
   - Verify stability of VAR model
   - Compare with alternative specifications

## Next Steps

After running the basic analysis:

1. **Sensitivity Analysis**: Test different parameters (lag orders, forecast horizons)

2. **Subperiod Analysis**: Compare pre-crisis vs. crisis vs. post-crisis periods

3. **Frequency Analysis**: Consider frequency-domain spillovers (requires additional packages)

4. **Extended Analysis**: Add more markets or assets to the analysis

5. **Event Studies**: Examine spillovers around specific events

## Getting Help

- Review the main README.md for detailed methodology
- Check function documentation within the R scripts
- Examine example_analysis.R for various use cases
- Review generated plots and tables for insights

## Citation

If you use this code for research, please cite:

- Diebold, F. X., & Yilmaz, K. (2012). Better to give than to receive: Predictive directional measurement of volatility spillovers. *International Journal of Forecasting*, 28(1), 57-66.

- Glosten, L. R., Jagannathan, R., & Runkle, D. E. (1993). On the relation between the expected value and the volatility of the nominal excess return on stocks. *The Journal of Finance*, 48(5), 1779-1801.
