# Volatility Spillover Analysis

BUS 330 - Asymmetric Volatility Spillovers between China, US and Taiwan Technology Sector

## Project Overview

This project analyzes asymmetric volatility spillovers from the US (S&P 500) and China (SSE Composite) markets to Taiwan's technology sector using advanced econometric models:

1. **Asymmetric DCC-GARCH Model**: Uses GJR-GARCH for univariate volatility modeling (captures leverage effects) and Dynamic Conditional Correlation (DCC) for time-varying correlations.

2. **Asymmetric BEKK-GARCH Model**: A multivariate GARCH model that captures asymmetric volatility spillovers and cross-market effects through parameter matrices.

## Features

- Automated data fetching from Yahoo Finance
- Implementation of GJR-GARCH (asymmetric GARCH) models
- Dynamic Conditional Correlation (DCC) estimation
- Asymmetric BEKK-GARCH model with leverage effects
- Comprehensive visualization of results
- Spillover analysis and interpretation

## Installation

### Requirements

- Python 3.8 or higher
- pip package manager

### Setup

1. Clone this repository:
```bash
git clone https://github.com/aam818/volatilit-spillover-.git
cd volatilit-spillover-
```

2. Install required packages:
```bash
pip install -r requirements.txt
```

## Usage

### Quick Start

Run the complete analysis with a single command:

```bash
python main.py
```

This will:
1. Download historical data for S&P 500, SSE Composite, and Taiwan Index
2. Calculate returns
3. Fit Asymmetric DCC-GARCH model
4. Fit Asymmetric BEKK-GARCH model
5. Generate visualizations
6. Save results to CSV and text files

### Individual Components

You can also run individual components:

**Fetch Data Only:**
```bash
python data_fetcher.py
```

**Run DCC-GARCH Only:**
```bash
python asymmetric_dcc_garch.py
```

**Run BEKK-GARCH Only:**
```bash
python asymmetric_bekk_garch.py
```

## Output Files

### Data Files
- `prices.csv`: Historical price data
- `returns.csv`: Log returns data

### DCC-GARCH Results
- `dcc_garch_volatility.csv`: Time-varying conditional volatilities
- `dcc_garch_correlations.csv`: Dynamic conditional correlations
- `dcc_garch_parameters.txt`: Model parameters
- `dcc_garch_volatility.png`: Volatility plot
- `dcc_garch_correlations.png`: Correlation dynamics plot
- `dcc_garch_heatmap.png`: Average correlation heatmap

### BEKK-GARCH Results
- `bekk_garch_volatility.csv`: Conditional volatilities
- `bekk_garch_correlations.csv`: Time-varying correlations
- `bekk_garch_parameters.txt`: Parameter matrices (A, B, G, C)
- `bekk_garch_volatility.png`: Volatility plot
- `bekk_garch_correlations.png`: Correlation dynamics plot
- `bekk_garch_parameters.png`: Parameter matrices visualization

### Summary
- `analysis_summary.txt`: Complete analysis summary and interpretation

## Methodology

### Asymmetric DCC-GARCH

The model consists of two stages:

1. **Univariate Stage**: GJR-GARCH(1,1,1) for each series
   ```
   r_t = μ + ε_t
   ε_t = σ_t * z_t
   σ²_t = ω + α*ε²_{t-1} + γ*I_{t-1}*ε²_{t-1} + β*σ²_{t-1}
   ```
   where I_{t-1} = 1 if ε_{t-1} < 0 (captures asymmetry)

2. **Multivariate Stage**: DCC for time-varying correlations
   ```
   Q_t = (1-α-β)*Q̄ + α*ε_{t-1}*ε'_{t-1} + β*Q_{t-1}
   R_t = diag(Q_t)^{-1/2} * Q_t * diag(Q_t)^{-1/2}
   ```

### Asymmetric BEKK-GARCH

The conditional covariance matrix follows:
```
H_t = C'C + A'*ε_{t-1}*ε'_{t-1}*A + B'*H_{t-1}*B + G'*η_{t-1}*η'_{t-1}*G
```

where:
- C: Constant term (lower triangular)
- A: ARCH effects (innovations impact)
- B: GARCH effects (persistence)
- G: Asymmetric effects (leverage effects)
- η_{t-1}: Negative innovations only

Off-diagonal elements in A, B, and G matrices capture cross-market spillover effects.

## Interpretation Guide

### Volatility Analysis
- Higher volatility indicates greater market uncertainty
- Clustered volatility shows persistence in market turbulence
- Compare volatility patterns across markets

### Correlation Analysis
- Values range from -1 to 1
- Higher positive correlation → markets move together
- Time-varying correlations show changing market integration
- Spikes in correlation may indicate contagion effects

### Spillover Effects (BEKK)
- **Diagonal elements**: Own-market effects
- **Off-diagonal elements**: Cross-market spillovers
- A[i,j]: Impact of market j's innovations on market i's volatility
- G[i,j]: Asymmetric impact (negative shocks from j on i)

### Key Questions to Answer
1. Do US and China markets significantly impact Taiwan tech sector volatility?
2. Are spillover effects symmetric or asymmetric?
3. How do correlations evolve over time?
4. Which market has stronger spillover effects on Taiwan?

## Technical Notes

- **Data Source**: Yahoo Finance (yfinance library)
- **Time Period**: Default is last 5 years (configurable)
- **Frequency**: Daily data
- **Returns**: Log returns in percentage
- **Estimation**: Maximum Likelihood Estimation (MLE)
- **Optimization**: SLSQP method for BEKK model

## Dependencies

- `arch>=6.2.0`: GARCH modeling
- `pandas>=2.0.0`: Data manipulation
- `numpy>=1.24.0`: Numerical computations
- `yfinance>=0.2.18`: Data fetching
- `matplotlib>=3.7.0`: Plotting
- `seaborn>=0.12.0`: Statistical visualization
- `scipy>=1.10.0`: Optimization
- `statsmodels>=0.14.0`: Statistical models

## Troubleshooting

**Issue**: "No data found" error
- **Solution**: Check your internet connection and try again. Some data sources may be temporarily unavailable.

**Issue**: BEKK optimization doesn't converge
- **Solution**: This is normal for complex models. The algorithm will use the best parameters found. You can increase `max_iter` in `main.py` for better convergence.

**Issue**: Memory error
- **Solution**: Reduce the date range or reduce the number of observations.

## References

1. Engle, R. (2002). Dynamic Conditional Correlation. Journal of Business & Economic Statistics.
2. Glosten, L., Jagannathan, R., & Runkle, D. (1993). On the Relation between Expected Value and Volatility of Nominal Excess Return on Stocks. Journal of Finance.
3. Engle, R., & Kroner, K. (1995). Multivariate Simultaneous Generalized ARCH. Econometric Theory.

## License

This project is for educational purposes as part of BUS 330 course.

## Author

BUS 330 Project - Volatility Spillover Analysis
