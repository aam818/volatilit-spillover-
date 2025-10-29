# Asymmetric BEKK (ABEKK) Volatility Spillover Analysis

This repository contains a comprehensive implementation of the Asymmetric BEKK(1,1,1) model for analyzing volatility spillovers between financial markets.

## Overview

The Asymmetric BEKK model extends the standard BEKK framework by incorporating asymmetric effects (leverage effects), allowing negative shocks to have different impacts on volatility compared to positive shocks of the same magnitude.

### Model Equation

The ABEKK(1,1,1) model specifies the conditional covariance matrix as:

```
H_t = C'C + A' ε_{t-1} ε'_{t-1} A + G' H_{t-1} G + B' η_{t-1} η'_{t-1} B
```

Where:
- **H_t**: Conditional covariance matrix at time t
- **C**: Lower triangular constant matrix
- **A**: ARCH matrix (captures short-run shock spillovers)
- **B**: Asymmetric matrix (captures leverage effects and asymmetric spillovers)
- **G**: GARCH matrix (captures long-run volatility persistence and spillovers)
- **ε_t**: Innovation vector (residuals)
- **η_t = min(ε_t, 0)**: Negative innovations only

## Features

### 1. Comprehensive Model Estimation
- Asymmetric BEKK(1,1,1) specification
- Quasi-Maximum Likelihood (QML) estimation
- Exact t-ratios using second derivatives
- Convergence diagnostics

### 2. Spillover Analysis
- **Total spillover matrix**: Combined effects from all channels
- **Directional spillovers**: Spillovers TO and FROM each market
- **Net spillovers**: Identifies net transmitters and receivers
- **Pairwise analysis**: Bilateral spillover relationships

### 3. Parameter Interpretation
- **A[i,j]**: Shock spillover from market j to market i (ARCH effect)
- **B[i,j]**: Asymmetric spillover from market j to market i (leverage effect)
- **G[i,j]**: Volatility spillover from market j to market i (GARCH effect)
- **Diagonal elements**: Own-market effects
- **Off-diagonal elements**: Cross-market spillovers

### 4. Publication-Ready Output

#### LaTeX Tables
- Individual parameter matrices (C, A, B, G)
- Spillover summary table
- Model diagnostics table
- Complete LaTeX document ready for compilation
- Booktabs formatting for professional appearance

#### Visualizations
- Conditional volatility time series
- Spillover heatmap
- Directional spillover bar charts
- Net spillover rankings

### 5. Model Diagnostics
- Log-likelihood, AIC, BIC
- Standardized residual statistics
- Convergence information
- Estimation time

## Installation

### Required R Packages

```r
install.packages(c("BEKKs", "xtable", "knitr", "ggplot2", "reshape2", "gridExtra"))
```

### Package Descriptions
- **BEKKs**: BEKK model estimation
- **xtable**: LaTeX table generation
- **knitr**: Report generation
- **ggplot2**: Visualization
- **reshape2**: Data manipulation
- **gridExtra**: Multiple plot layouts

## Usage

### Step 1: Prepare Your Data

Your returns data should be in one of the following formats:
- `xts` object (recommended)
- `zoo` object
- `ts` object
- `matrix` with dates as rownames

Example data structure:
```r
           US        CN        EU
2020-01-01  0.0015   0.0023   0.0012
2020-01-02 -0.0034   0.0045  -0.0011
2020-01-03  0.0067  -0.0012   0.0034
...
```

### Step 2: Load Your Data

Create a file named `load_data.R`:

```r
# Example: Loading data from CSV
library(xts)

# Read returns data
data <- read.csv("your_returns_data.csv", row.names = 1)

# Convert to xts
dates <- as.Date(rownames(data))
returns <- xts(data, order.by = dates)

# Verify data
head(returns)
str(returns)
```

### Step 3: Run the Analysis

```r
# Load your data
source("load_data.R")

# Run ABEKK estimation
source("abekk_estimation.R")
```

The script will automatically:
1. Estimate the ABEKK model
2. Calculate spillover indices
3. Generate LaTeX tables
4. Create visualizations
5. Save all results

### Step 4: Use the Results

#### In Your LaTeX Document

Add to your preamble:
```latex
\usepackage{booktabs}
\usepackage{caption}
\usepackage{float}
```

Include tables:
```latex
\section{Results}

\subsection{ARCH Effects}
\input{output/table_A_matrix.tex}

\subsection{Asymmetric Effects}
\input{output/table_B_matrix.tex}

\subsection{GARCH Effects}
\input{output/table_G_matrix.tex}

\subsection{Total Spillovers}
\input{output/table_spillover.tex}
```

Or compile the complete document:
```bash
cd output
pdflatex abekk_results_complete.tex
```

#### Access Results Programmatically

```r
# Load saved results
results <- readRDS("output/abekk_results.rds")

# Access components
results$parameters$A          # ARCH matrix
results$parameters$B          # Asymmetric matrix
results$parameters$G          # GARCH matrix
results$spillover$matrix      # Total spillover matrix
results$spillover$net         # Net spillover indices
```

## Output Files

After running the analysis, the following files will be created in the `output/` directory:

### LaTeX Tables
- `table_C_matrix.tex` - Constant matrix
- `table_A_matrix.tex` - ARCH matrix (shock spillovers)
- `table_B_matrix.tex` - Asymmetric matrix (leverage effects)
- `table_G_matrix.tex` - GARCH matrix (volatility spillovers)
- `table_spillover.tex` - Total spillover matrix
- `table_summary.tex` - Model summary statistics
- `abekk_results_complete.tex` - Complete LaTeX document

### Visualizations (PNG, 300 DPI)
- `plot_conditional_volatility.png` - Time series of conditional volatilities
- `plot_spillover_heatmap.png` - Heatmap of spillover matrix
- `plot_directional_spillovers.png` - Bar chart of directional spillovers
- `plot_net_spillover.png` - Net spillover rankings

### Data Files
- `abekk_results.rds` - Complete results object (R format)

## Interpreting Results

### 1. Parameter Matrices

#### ARCH Matrix (A)
- **Diagonal elements A[i,i]**: How own shocks affect own volatility
- **Off-diagonal A[i,j]**: How shocks in market j affect volatility in market i
- Captures **short-run** shock transmission

#### Asymmetric Matrix (B)
- **Diagonal elements B[i,i]**: Leverage effects (negative shock impact)
- **Off-diagonal B[i,j]**: Asymmetric spillovers from market j to i
- Positive values indicate negative shocks increase volatility
- Compare |B| vs |A| to assess asymmetry strength

#### GARCH Matrix (G)
- **Diagonal elements G[i,i]**: Volatility persistence in market i
- **Off-diagonal G[i,j]**: How volatility in market j affects volatility in market i
- Captures **long-run** volatility spillovers
- Values close to 1 indicate high persistence

### 2. Spillover Indices

#### Total Spillover
```
Total Spillover[i,j] = |A[i,j]| + |B[i,j]| + |G[i,j]|
```
Measures combined spillover from market j to market i across all channels.

#### Directional Spillovers
- **Spillover TO market i**: Sum of column i (excluding diagonal)
  - Measures total volatility received by market i
- **Spillover FROM market i**: Sum of row i (excluding diagonal)
  - Measures total volatility transmitted by market i

#### Net Spillover
```
Net Spillover[i] = Spillover FROM[i] - Spillover TO[i]
```
- **Positive value**: Market i is a net transmitter of volatility
- **Negative value**: Market i is a net receiver of volatility
- **Zero**: Balanced spillovers

### 3. Statistical Significance

T-ratios are calculated using QML standard errors:
- **|t| > 1.96**: Significant at 5% level
- **|t| > 2.58**: Significant at 1% level
- Check `QML_t_ratios` in the model output

### 4. Model Selection

- **AIC** (Akaike Information Criterion): Lower is better
- **BIC** (Bayesian Information Criterion): Lower is better, penalizes complexity more
- Compare with symmetric BEKK or other models

## Example Interpretation

Suppose you're analyzing three markets: US, China (CN), and Europe (EU).

### Example Results:

```
Spillover Matrix:
         US     CN     EU
US     0.000  0.234  0.189
CN     0.345  0.000  0.156
EU     0.278  0.198  0.000

Net Spillovers:
US: -0.101 (Net Receiver)
CN:  0.145 (Net Transmitter)
EU: -0.044 (Net Receiver)
```

### Interpretation:

1. **China is a net transmitter** of volatility (0.145)
   - Chinese market shocks significantly affect US and EU markets
   - Spillover from CN to US (0.345) is the strongest bilateral relationship

2. **US is a net receiver** (-0.101)
   - Despite being large, US receives more volatility than it transmits
   - Particularly sensitive to Chinese market developments

3. **Strongest spillover channel**: CN → US (0.345)
   - Chinese shocks have the largest impact on US volatility
   - Could be due to trade linkages, policy spillovers, or investor sentiment

4. **Bidirectional effects**: US ↔ CN
   - US → CN: 0.234
   - CN → US: 0.345
   - Asymmetric relationship with stronger CN → US transmission

## Advanced Usage

### Comparing Models

```r
# Estimate symmetric BEKK for comparison
symmetric_spec <- bekk_spec(
  model = list(type = "bekk", asymmetric = FALSE)
)
symmetric_fit <- bekk_fit(symmetric_spec, returns_matrix)

# Compare information criteria
cat("Asymmetric AIC:", asymmetric_bekk_fit$AIC, "\n")
cat("Symmetric AIC:", symmetric_fit$AIC, "\n")

# Lower AIC indicates better fit
```

### Subsample Analysis

```r
# Crisis period analysis
crisis_returns <- returns["2008-01-01/2009-12-31"]
source("abekk_estimation.R")  # Will use crisis_returns

# Post-crisis period
postcrisis_returns <- returns["2010-01-01/2020-12-31"]
source("abekk_estimation.R")
```

### Robustness Checks

```r
# Try different starting values
asymmetric_bekk_spec <- bekk_spec(
  model = list(type = "bekk", asymmetric = TRUE),
  signs = c(-1, -1, -1),
  init_values = "random"  # Random initialization
)

# Increase maximum iterations
asymmetric_bekk_fit <- bekk_fit(
  spec = asymmetric_bekk_spec,
  data = returns_matrix,
  max_iter = 200,  # More iterations
  crit = 1e-10     # Tighter convergence
)
```

## Troubleshooting

### Common Issues

1. **Convergence Failure**
   - Try different starting values: `init_values = "random"`
   - Increase max iterations: `max_iter = 200`
   - Check data for outliers or missing values

2. **Negative Eigenvalues in H_t**
   - Model may be misspecified
   - Try simpler specification (e.g., diagonal BEKK)
   - Check for data quality issues

3. **Very Long Estimation Time**
   - Normal for large systems (>4 markets)
   - Consider diagonal or scalar BEKK for initial exploration
   - Use parallel computing if available

4. **LaTeX Tables Not Compiling**
   - Ensure `\usepackage{booktabs}` in preamble
   - Check for special characters in market names
   - Try compiling with `pdflatex` instead of `latex`

## Citations

If you use this code in your research, please cite:

1. The BEKKs package:
   ```
   Schöne, F. (2023). BEKKs: Multivariate Conditional Volatility Modelling and Forecasting.
   R package version 1.4.3.
   ```

2. Original BEKK papers:
   ```
   Engle, R. F., & Kroner, K. F. (1995). Multivariate simultaneous generalized ARCH.
   Econometric Theory, 11(1), 122-150.

   Kroner, K. F., & Ng, V. K. (1998). Modeling asymmetric comovements of asset returns.
   Review of Financial Studies, 11(4), 817-844.
   ```

## Additional Resources

- [BEKKs Package Documentation](https://cran.r-project.org/package=BEKKs)
- [Multivariate GARCH Models](https://www.federalreserve.gov/econres/feds/multivariate-garch-models.htm)
- [Volatility Spillover Analysis](https://onlinelibrary.wiley.com/doi/abs/10.1002/jae.842)

## License

This code is provided as-is for academic and research purposes.

## Contact

For questions or issues, please open an issue in this repository.

---

**Last Updated**: October 29, 2025
