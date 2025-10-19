# Usage Guide for Asymmetric BEKK Model

## Quick Start

There are three ways to use this asymmetric BEKK model implementation:

### 1. Quick Demo (Fastest)
For a quick demonstration with minimal data:
```bash
python quick_demo.py
```
This runs with 50 observations and limited iterations, completing in seconds.

### 2. Full Example with Sample Data (Recommended for Testing)
For a complete demonstration with simulated data:
```bash
python example_with_sample_data.py
```
This generates realistic sample data for ~5 years and runs full optimization.

### 3. Real Market Data Analysis (Production Use)
For actual analysis with live market data:
```bash
python asymmetric_bekk_model.py
```
This fetches real data from Yahoo Finance for S&P 500, SSE, and TAIEX.

## Installation

```bash
pip install -r requirements.txt
```

Required packages:
- numpy
- pandas
- yfinance
- matplotlib
- scipy

## Model Overview

The Asymmetric BEKK model estimates conditional covariance matrices for multiple assets:

```
H_t = C'C + A'·ε_{t-1}·ε_{t-1}'·A + B'·H_{t-1}·B + D'·η_{t-1}·η_{t-1}'·D
```

Where:
- **H_t**: Conditional covariance matrix at time t
- **C**: Lower triangular constant matrix
- **A**: Shock spillover matrix (ARCH effects)
- **B**: Volatility persistence matrix (GARCH effects)
- **D**: Asymmetric effects matrix (leverage effects)
- **ε_{t-1}**: Innovation vector at time t-1
- **η_{t-1}**: Negative shocks only (η_{t-1} = ε_{t-1} · I(ε_{t-1} < 0))

## Understanding the Output

### 1. Shock Spillover Matrix (A)
Shows how innovations (shocks) in one market affect volatility in others:
- **Diagonal elements**: Own-market ARCH effects
- **Off-diagonal elements**: Cross-market shock transmission

Example interpretation:
- A[SP500, SSE] = 0.15 means shocks in SP500 increase SSE volatility

### 2. Volatility Persistence Matrix (B)
Shows how past volatility affects current volatility:
- **Diagonal elements**: Own-market volatility persistence
- **Off-diagonal elements**: Cross-market volatility spillovers

Large diagonal elements indicate high persistence (slow mean reversion).

### 3. Asymmetric Effects Matrix (D)
Shows leverage effects (asymmetric response to positive vs negative shocks):
- Positive elements: Negative shocks increase volatility more than positive shocks
- This captures the well-known phenomenon that bad news impacts volatility more

### 4. Conditional Correlations
Time-varying correlations between markets:
- Shows how market co-movements change over time
- Useful for portfolio diversification and risk management

## Customization

### Change Date Range
Edit the `start_date` and `end_date` in the fetch_market_data() call:
```python
prices = fetch_market_data(start_date='2020-01-01', end_date='2024-01-01')
```

### Change Markets
Modify the tickers dictionary in the `fetch_market_data()` function:
```python
tickers = {
    'Market1': '^GSPC',
    'Market2': '000001.SS',
    'Market3': '^TWII'
}
```

### Optimization Settings
Adjust the fitting parameters:
```python
model.fit(method='BFGS', maxiter=1000)  # Increase for more thorough optimization
```

Available methods: 'BFGS', 'L-BFGS-B', 'Nelder-Mead', 'Powell'

## Testing

Run the test suite to verify installation:
```bash
python test_bekk.py
```

This tests:
- Model initialization
- Parameter handling
- Covariance computation
- Log-likelihood calculation
- Data fetching (if network available)

## Troubleshooting

### Network Issues
If data fetching fails due to network restrictions:
- Use `example_with_sample_data.py` instead
- Or download data manually and modify the script

### Convergence Issues
If optimization doesn't converge:
- Increase `maxiter` parameter
- Try different optimization methods
- Ensure you have enough data (at least 100-200 observations)
- Check for outliers or data quality issues

### Memory Issues
For very large datasets:
- Reduce the date range
- Use fewer assets
- Increase available memory

## Academic References

1. Engle, R. F., & Kroner, K. F. (1995). Multivariate simultaneous generalized ARCH. *Econometric Theory*, 11(1), 122-150.

2. Kroner, K. F., & Ng, V. K. (1998). Modeling asymmetric comovements of asset returns. *The Review of Financial Studies*, 11(4), 817-844.

3. Cappiello, L., Engle, R. F., & Sheppard, K. (2006). Asymmetric dynamics in the correlations of global equity and bond returns. *Journal of Financial Econometrics*, 4(4), 537-572.

## Support

For issues or questions:
1. Check this usage guide
2. Review the test suite output
3. Examine the example scripts
4. Verify data quality and parameters

## Notes

- The model requires numerical optimization which can take time
- Results are sensitive to initialization and data quality
- Ensure sufficient data (minimum 100+ observations recommended)
- The asymmetric component captures leverage effects common in financial markets
