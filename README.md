# Volatility Spillover Analysis using Asymmetric BEKK Model

This repository implements an **Asymmetric BEKK (Baba, Engle, Kraft, and Kroner)** model to analyze volatility spillovers between three major financial markets:

- **S&P 500** (US market)
- **SSE Composite Index** (Shanghai Stock Exchange - China)
- **TAIEX** (Taiwan Stock Exchange)

## Overview

The asymmetric BEKK model captures:
- **Volatility spillovers** between markets
- **Asymmetric effects** (leverage effects) where negative shocks have different impacts than positive shocks
- **Time-varying conditional correlations** between markets

## Installation

Install the required dependencies:

```bash
pip install -r requirements.txt
```

## Usage

Run the asymmetric BEKK model analysis:

```bash
python asymmetric_bekk_model.py
```

The script will:
1. Fetch historical data for S&P 500, SSE, and TAIEX
2. Calculate log returns
3. Estimate the asymmetric BEKK model
4. Display spillover analysis results
5. Generate visualizations saved as `bekk_results.png`

## Model Specification

The asymmetric BEKK model specifies the conditional covariance matrix as:

```
H_t = C'C + A' * ε_{t-1} * ε_{t-1}' * A + B' * H_{t-1} * B + D' * η_{t-1} * η_{t-1}' * D
```

Where:
- **C'C**: Constant matrix (intercept)
- **A**: Shock spillover matrix (ARCH effects)
- **B**: Volatility persistence matrix (GARCH effects)
- **D**: Asymmetric effects matrix (leverage effects)
- **η_{t-1}**: Negative shocks (η_{t-1} = ε_{t-1} * I(ε_{t-1} < 0))

## Output

The script provides:

1. **Shock Spillover Matrix (A)**: Shows how shocks in one market affect volatility in others
2. **Volatility Persistence Matrix (B)**: Shows persistence of volatility over time
3. **Asymmetric Effects Matrix (D)**: Shows leverage effects
4. **Conditional Correlations**: Time-varying correlations between markets
5. **Visualizations**: Plots of returns and conditional correlations

## Key Findings to Examine

- **Cross-market shock transmission**: Off-diagonal elements of A matrix
- **Volatility persistence**: Diagonal and off-diagonal elements of B matrix
- **Asymmetric/leverage effects**: D matrix elements
- **Dynamic correlations**: Time-varying conditional correlations plot

## Requirements

- Python 3.7+
- numpy
- pandas
- yfinance
- matplotlib
- scipy

## Academic Context

This analysis is part of BUS 330 research on volatility spillovers between China, US, and Taiwan, with a focus on the tech sector of Taiwan.

## References

- Engle, R. F., & Kroner, K. F. (1995). Multivariate simultaneous generalized ARCH. *Econometric Theory*, 11(1), 122-150.
- Kroner, K. F., & Ng, V. K. (1998). Modeling asymmetric comovements of asset returns. *The Review of Financial Studies*, 11(4), 817-844. 
