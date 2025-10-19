# Project Summary: Asymmetric BEKK Model Implementation

## Overview
This repository implements an **Asymmetric BEKK (Baba, Engle, Kraft, and Kroner) GARCH model** for analyzing volatility spillovers between three major financial markets:
- **S&P 500** (United States)
- **SSE Composite Index** (China - Shanghai Stock Exchange)
- **TAIEX** (Taiwan Stock Exchange)

## Academic Context
This implementation is designed for **BUS 330** research on volatility spillovers between China, US, and Taiwan, with particular focus on the technology sector.

## What is the Asymmetric BEKK Model?

The asymmetric BEKK model is a multivariate GARCH (Generalized Autoregressive Conditional Heteroskedasticity) model that captures:

1. **Volatility Clustering**: Periods of high/low volatility tend to cluster together
2. **Volatility Spillovers**: How shocks in one market affect volatility in other markets
3. **Asymmetric Effects**: Negative shocks (bad news) have different impacts than positive shocks (good news) - known as leverage effects
4. **Dynamic Correlations**: How market correlations change over time

### Model Specification
The conditional covariance matrix H_t follows:

```
H_t = C'C + A' * ε_{t-1} * ε_{t-1}' * A + B' * H_{t-1} * B + D' * η_{t-1} * η_{t-1}' * D
```

Where:
- **C**: Lower triangular constant matrix
- **A**: Shock spillover matrix (captures ARCH effects)
- **B**: Volatility persistence matrix (captures GARCH effects)
- **D**: Asymmetric effects matrix (captures leverage effects)
- **ε_{t-1}**: Innovation vector (shocks) at time t-1
- **η_{t-1}**: Negative innovations only (η_{t-1} = ε_{t-1} · I(ε_{t-1} < 0))

## Files in This Repository

### Main Implementation
- **`asymmetric_bekk_model.py`** (440 lines)
  - Core `AsymmetricBEKK` class
  - Data fetching from Yahoo Finance
  - Maximum likelihood estimation
  - Spillover analysis
  - Visualization functions

### Examples and Demos
- **`quick_demo.py`** - Fast demonstration (30 sec runtime)
- **`tutorial.py`** - Step-by-step walkthrough with explanations
- **`example_with_sample_data.py`** - Full analysis with synthetic data

### Testing and Validation
- **`test_bekk.py`** - Comprehensive test suite

### Documentation
- **`README.md`** - Project overview and quick start
- **`USAGE.md`** - Detailed usage guide
- **`SUMMARY.md`** - This file

### Configuration
- **`requirements.txt`** - Python dependencies
- **`.gitignore`** - Files to exclude from git

## Key Features

### 1. Complete Asymmetric BEKK Implementation
- Mathematically rigorous implementation following Kroner & Ng (1998)
- Maximum likelihood estimation via BFGS optimization
- Proper handling of matrix constraints (positive definiteness)

### 2. Automatic Data Fetching
- Fetches historical data from Yahoo Finance
- Handles three market indices automatically
- Calculates log returns

### 3. Comprehensive Analysis Output
- **A Matrix**: Shows shock spillover effects between markets
- **B Matrix**: Shows volatility persistence and cross-market effects
- **D Matrix**: Shows asymmetric (leverage) effects
- **Conditional Correlations**: Time-varying correlation matrices
- **Visualizations**: Plots of returns and dynamic correlations

### 4. Multiple Usage Modes
Choose based on your needs:
- Real-time data analysis
- Historical data analysis
- Quick testing with synthetic data
- Educational/tutorial mode

## Installation and Usage

### Quick Start
```bash
# Install dependencies
pip install -r requirements.txt

# Run quick demo (fastest)
python quick_demo.py

# Run with real data
python asymmetric_bekk_model.py
```

### Requirements
- Python 3.7 or higher
- numpy >= 1.21.0
- pandas >= 1.3.0
- yfinance >= 0.2.0
- matplotlib >= 3.4.0
- scipy >= 1.7.0

## Interpreting Results

### Shock Spillover Matrix (A)
- **Diagonal elements**: How own-market shocks affect own volatility
- **Off-diagonal A[i,j]**: How shocks in market j affect volatility in market i
- Larger absolute values indicate stronger spillover effects

Example: If A[SSE, SP500] = 0.25, then a 1% shock in S&P 500 leads to increased volatility in SSE.

### Volatility Persistence Matrix (B)
- **Diagonal elements**: How persistent volatility is in each market
- **Off-diagonal B[i,j]**: How volatility in market j affects volatility in market i
- Values close to 1 indicate high persistence (slow mean reversion)

### Asymmetric Effects Matrix (D)
- **Positive values**: Negative shocks increase volatility more than positive shocks
- This captures the "leverage effect" common in equity markets
- Particularly important for risk management and option pricing

### Conditional Correlations
- Show how market co-movements change over time
- Important for portfolio diversification
- Tend to increase during crisis periods

## Academic References

1. **Engle, R. F., & Kroner, K. F. (1995)**. Multivariate simultaneous generalized ARCH. *Econometric Theory*, 11(1), 122-150.
   - Original BEKK model specification

2. **Kroner, K. F., & Ng, V. K. (1998)**. Modeling asymmetric comovements of asset returns. *The Review of Financial Studies*, 11(4), 817-844.
   - Asymmetric BEKK model extension

3. **Cappiello, L., Engle, R. F., & Sheppard, K. (2006)**. Asymmetric dynamics in the correlations of global equity and bond returns. *Journal of Financial Econometrics*, 4(4), 537-572.
   - Applications to international markets

## Technical Details

### Parameter Estimation
- Method: Maximum Likelihood Estimation (MLE)
- Optimization: BFGS (Broyden-Fletcher-Goldfarb-Shanno) algorithm
- Constraint handling: Ensures positive definite covariance matrices
- Initial values: Random initialization with bounds

### Number of Parameters
For 3 assets:
- C matrix: 6 parameters (lower triangular)
- A matrix: 9 parameters (full matrix)
- B matrix: 9 parameters (full matrix)
- D matrix: 9 parameters (full matrix)
- **Total: 33 parameters**

### Computational Complexity
- Time complexity: O(n²·T) where n=assets, T=observations
- Typical runtime: 5-30 minutes depending on data size and iterations
- Quick demo: <1 minute with limited iterations

## Limitations and Considerations

1. **Computational Intensity**: Requires substantial computation for large datasets
2. **Convergence**: May require multiple runs with different starting values
3. **Data Requirements**: Needs sufficient observations (minimum 100-200 recommended)
4. **Synchronous Data**: Assumes all markets trade simultaneously (time zone issues)
5. **Parameter Stability**: Results can be sensitive to the sample period

## Future Enhancements

Potential extensions not currently implemented:
- Rolling window estimation
- Forecast evaluation metrics
- Additional diagnostic tests
- Multivariate portmanteau tests
- Out-of-sample forecasting
- Alternative optimization algorithms
- Parallel processing for speed

## Testing

All core functionality has been tested:
- ✓ Model initialization
- ✓ Parameter handling and conversion
- ✓ Covariance matrix computation
- ✓ Log-likelihood calculation
- ✓ Matrix operations
- ✓ Public API methods

Run tests: `python test_bekk.py`

## Citation

If you use this code in your research, please cite:
```
Asymmetric BEKK Model Implementation for Volatility Spillover Analysis
Repository: https://github.com/aam818/volatilit-spillover-
Year: 2024
```

## License

This implementation is provided for educational and research purposes.

## Support

For questions or issues:
1. Review the USAGE.md documentation
2. Check the tutorial.py for examples
3. Run test_bekk.py to verify installation
4. Examine the code comments for technical details

---

**Note**: This implementation is designed for academic research and educational purposes. While mathematically rigorous, it should be thoroughly validated before use in production trading or risk management systems.
