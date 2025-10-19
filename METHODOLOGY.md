# Methodology Documentation

## Asymmetric Volatility Spillover Analysis Framework

This document provides detailed information about the methodology implemented in this repository.

## Table of Contents
1. [Overview](#overview)
2. [Asymmetric Volatility Modeling](#asymmetric-volatility-modeling)
3. [Spillover Index Calculation](#spillover-index-calculation)
4. [Rolling Window Analysis](#rolling-window-analysis)
5. [Statistical Tests](#statistical-tests)
6. [Model Selection](#model-selection)

---

## Overview

The analysis consists of three main stages:

1. **Pre-filtering**: Remove conditional mean and volatility clustering using GJR-GARCH models
2. **Spillover Measurement**: Apply VAR and FEVD to standardized residuals
3. **Dynamic Analysis**: Rolling window estimation to capture time-varying spillovers

---

## Asymmetric Volatility Modeling

### GJR-GARCH Model Specification

The GJR-GARCH(1,1) model (Glosten, Jagannathan, and Runkle, 1993) is used to capture:
- Volatility clustering
- Asymmetric response to shocks (leverage effect)

**Model Equations:**

Mean equation:
```
r_t = μ + φ·r_{t-1} + ε_t
```

Variance equation:
```
σ²_t = ω + (α + γ·I_{t-1})·ε²_{t-1} + β·σ²_{t-1}
```

Where:
- `r_t` is the return at time t
- `ε_t ~ D(0, σ²_t)` is the innovation
- `I_{t-1} = 1` if `ε_{t-1} < 0`, otherwise 0
- `ω > 0`, `α ≥ 0`, `β ≥ 0`, `γ ≥ 0`
- Stationarity: `α + β + γ/2 < 1`

**Asymmetry Interpretation:**
- If `γ > 0`: Negative shocks increase volatility more than positive shocks (leverage effect)
- If `γ = 0`: Model reduces to standard GARCH
- Typical finding: `γ > 0` and statistically significant for equity markets

**Distribution Assumptions:**
The model supports multiple distributions for innovations:
- Normal distribution
- Student's t-distribution (recommended for fat tails)
- Generalized Error Distribution (GED)

### Why GJR-GARCH?

1. **Captures Asymmetry**: Negative returns tend to increase volatility more than positive returns
2. **Better Fit**: Often provides better in-sample and out-of-sample performance for equity returns
3. **Economic Intuition**: Leverage effect reflects risk-return dynamics in equity markets
4. **Flexibility**: Nests standard GARCH as special case when γ = 0

### Standardized Residuals

After fitting GJR-GARCH, we extract standardized residuals:

```
z_t = ε_t / σ_t
```

These residuals should be:
- Zero mean
- Unit variance
- Free from conditional heteroskedasticity
- Used as input for spillover analysis

---

## Spillover Index Calculation

### Diebold-Yilmaz Methodology

The spillover index (Diebold & Yilmaz, 2012) is based on forecast error variance decomposition (FEVD) from VAR models.

### Step 1: VAR Model Estimation

Estimate a VAR(p) model for standardized residuals:

```
z_t = c + Φ_1·z_{t-1} + Φ_2·z_{t-2} + ... + Φ_p·z_{t-p} + u_t
```

Where:
- `z_t` is the N×1 vector of standardized residuals
- `Φ_i` are N×N coefficient matrices
- `u_t ~ N(0, Σ)` are VAR innovations

**Lag Selection:**
- Use information criteria (AIC, BIC, HQ)
- Typical range: 1-4 lags for daily data
- Default: 2 lags (good balance between fit and parsimony)

### Step 2: Forecast Error Variance Decomposition

FEVD decomposes the H-step-ahead forecast error variance of variable i into contributions from shocks to each variable j:

```
θ_{ij}(H) = proportion of H-step forecast error variance in i due to shocks in j
```

**Calculation:**
Using Cholesky decomposition or Generalized FEVD (order-invariant):

```
θ_{ij}(H) = (σ_{jj}^{-1} · Σ_{h=0}^{H-1} (e_i' · A_h · Σ · e_j)²) / (Σ_{h=0}^{H-1} e_i' · A_h · Σ · A_h' · e_i)
```

Where:
- `A_h` are coefficient matrices from MA representation
- `Σ` is VAR innovation covariance matrix
- `σ_{jj}` is variance of shocks to variable j
- `e_i` is selection vector

### Step 3: Spillover Table Construction

Create N×N spillover table where entry (i,j) represents the variance share:

```
Spillover Table:
              |  Market 1  |  Market 2  |  Market 3  |  FROM
--------------+------------+------------+------------+---------
Market 1      |    d₁₁     |    d₁₂     |    d₁₃     |  FROM₁
Market 2      |    d₂₁     |    d₂₂     |    d₂₃     |  FROM₂
Market 3      |    d₃₁     |    d₃₂     |    d₃₃     |  FROM₃
--------------+------------+------------+------------+---------
TO            |    TO₁     |    TO₂     |    TO₃     |
```

**Key Metrics:**

1. **Total Spillover Index (TSI):**
   ```
   TSI = (Σᵢ Σⱼ≠ᵢ θ_{ij}(H)) / (Σᵢ Σⱼ θ_{ij}(H)) × 100
   ```
   - Measures overall connectedness
   - Range: 0-100%
   - Higher values indicate stronger interconnections

2. **Directional Spillovers TO others:**
   ```
   TO_j = (Σᵢ≠ⱼ θ_{ij}(H)) / (Σᵢ Σⱼ θ_{ij}(H)) × 100
   ```
   - How much market j transmits to others
   - Measures transmission role

3. **Directional Spillovers FROM others:**
   ```
   FROM_i = (Σⱼ≠ᵢ θ_{ij}(H)) / (Σᵢ Σⱼ θ_{ij}(H)) × 100
   ```
   - How much market i receives from others
   - Measures receiver role

4. **Net Directional Spillovers:**
   ```
   NET_i = TO_i - FROM_i
   ```
   - Positive: Net transmitter
   - Negative: Net receiver
   - Zero: Balanced transmission/reception

5. **Pairwise Spillovers:**
   ```
   PS_{ij} = θ_{ji}(H) - θ_{ij}(H)
   ```
   - Net spillover from i to j
   - Positive: i transmits more to j than receives

### Forecast Horizon Selection

The forecast horizon H affects spillover measures:
- **Short horizon (H=1-3)**: Captures immediate effects
- **Medium horizon (H=10-12)**: Standard choice, balances short/long-run
- **Long horizon (H=20+)**: Long-run relationships

**Default: H=10** (approximately 2 weeks for daily data)

---

## Rolling Window Analysis

### Time-Varying Spillovers

Rolling window estimation captures dynamic changes in spillovers:

1. **Window Selection:**
   - Fixed width: W observations
   - Typical: W = 200-300 for daily data (≈1 year)
   - Trade-off: Larger W (more stable, less responsive) vs. Smaller W (more responsive, noisier)

2. **Procedure:**
   ```
   For t = W to T:
     Extract data: z[t-W+1:t]
     Estimate VAR(p)
     Calculate FEVD
     Compute spillover indices
     Store results for date t
   ```

3. **Output:**
   - Time series of total spillover index
   - Time series of directional spillovers
   - Time series of net spillovers

### Interpretation

Rolling spillovers reveal:
- **Structural breaks**: Sudden changes in connectedness
- **Crisis episodes**: Spillovers typically increase during crises
- **Market integration**: Long-run trends in connectedness
- **Policy impacts**: Changes following regulatory interventions

---

## Statistical Tests

### 1. Asymmetry Test (Leverage Effect)

**Null Hypothesis:** γ = 0 (no asymmetry)
**Alternative:** γ > 0 (leverage effect present)

**Test Statistic:**
```
t = γ̂ / SE(γ̂)
```

**Interpretation:**
- Reject H₀ if t > critical value (1.96 for 5% level)
- Significant positive γ confirms asymmetric volatility response

### 2. VAR Lag Order Tests

**Methods:**
- AIC: Akaike Information Criterion
- BIC: Bayesian Information Criterion
- HQ: Hannan-Quinn Criterion

**Selection Rule:**
- Choose p that minimizes information criterion
- BIC tends to select more parsimonious models
- AIC may select higher orders

### 3. VAR Stability

**Condition:** All eigenvalues of companion matrix inside unit circle

**Check:**
```r
var_model <- VAR(data, p = 2)
roots <- roots(var_model)
all(roots < 1)  # Should be TRUE
```

### 4. Residual Diagnostics

**Tests:**
1. **Serial Correlation:** Portmanteau test
2. **Normality:** Jarque-Bera test
3. **Heteroskedasticity:** ARCH test

---

## Model Selection

### Choosing Model Specifications

**GJR-GARCH Order:**
- Start with (1,1): Usually sufficient for daily data
- Higher orders rarely improve fit substantially
- Check: AIC, BIC, likelihood ratio tests

**VAR Lag Order:**
- Information criteria: Typically select p = 1-4
- Residual diagnostics: No serial correlation
- Forecast performance: Out-of-sample validation

**Distribution Choice:**
- Normal: Baseline, often inadequate for equity returns
- Student-t: Recommended, captures fat tails
- GED: Alternative, flexible tail behavior

**Forecast Horizon:**
- H = 10: Standard choice
- Sensitivity analysis: Compare H = 5, 10, 15, 20

**Rolling Window Size:**
- W = 250: Approximately 1 year of daily data
- Minimum: At least 100-150 observations
- Maximum: Balance responsiveness and stability

---

## Practical Considerations

### Data Requirements

**Minimum Sample Size:**
- Static analysis: N > 200 observations
- Rolling analysis: N > 500 observations (to allow multiple windows)

**Data Frequency:**
- Daily: Most common, good balance
- Weekly: Less noise, but fewer observations
- Intraday: More data, but microstructure noise

**Missing Values:**
- Handle carefully: Interpolation or omission
- May affect VAR estimation
- Document treatment method

### Computational Aspects

**Estimation Time:**
- Static analysis: Minutes
- Rolling analysis: Can take hours for long series
- Parallel processing: Can speed up rolling estimation

**Memory Requirements:**
- Moderate for static analysis
- Can be large for rolling analysis with many assets

### Robustness Checks

1. **Subsample Analysis:** Split sample, compare results
2. **Alternative Specifications:** Try different lag orders, horizons
3. **Bootstrap Confidence Intervals:** Assess uncertainty
4. **Sensitivity Analysis:** Vary key parameters

---

## References

### Primary References

1. **Diebold, F. X., & Yilmaz, K. (2012).** Better to give than to receive: Predictive directional measurement of volatility spillovers. *International Journal of Forecasting*, 28(1), 57-66.

2. **Glosten, L. R., Jagannathan, R., & Runkle, D. E. (1993).** On the relation between the expected value and the volatility of the nominal excess return on stocks. *The Journal of Finance*, 48(5), 1779-1801.

3. **Diebold, F. X., & Yilmaz, K. (2009).** Measuring financial asset return and volatility spillovers, with application to global equity markets. *The Economic Journal*, 119(534), 158-171.

### Extension References

4. **Baruník, J., & Křehlík, T. (2018).** Measuring the frequency dynamics of financial connectedness and systemic risk. *Journal of Financial Econometrics*, 16(2), 271-296.

5. **Antonakakis, N., Chatziantoniou, I., & Gabauer, D. (2020).** Refined measures of dynamic connectedness based on time-varying parameter vector autoregressions. *Journal of Risk and Financial Management*, 13(4), 84.

### Software References

6. **Pfaff, B. (2008).** VAR, SVAR and SVEC models: Implementation within R package vars. *Journal of Statistical Software*, 27(4), 1-32.

7. **Ghalanos, A. (2020).** rugarch: Univariate GARCH models. R package version 1.4-4.

---

## Appendix: Mathematical Notation

| Symbol | Description |
|--------|-------------|
| r_t | Return at time t |
| ε_t | Innovation/shock at time t |
| σ²_t | Conditional variance at time t |
| z_t | Standardized residual at time t |
| N | Number of markets/variables |
| T | Sample size |
| p | VAR lag order |
| H | Forecast horizon |
| W | Rolling window size |
| θ_{ij}(H) | FEVD: share of H-step forecast error variance in i from j |
| Σ | Variance-covariance matrix |
| Φ_i | VAR coefficient matrix at lag i |

---

## Contact and Support

For questions about the methodology or implementation:
- Review the code documentation in the R scripts
- Check the Quick Start guide for practical usage
- Refer to the primary references for theoretical details
