"""
Step-by-Step Tutorial: Asymmetric BEKK Model Analysis
This script walks through each step of the analysis with explanations
"""

import numpy as np
import pandas as pd
from asymmetric_bekk_model import AsymmetricBEKK

print("="*80)
print("STEP-BY-STEP TUTORIAL: ASYMMETRIC BEKK MODEL")
print("="*80)

# =============================================================================
# STEP 1: Generate or Load Data
# =============================================================================
print("\n" + "="*80)
print("STEP 1: DATA PREPARATION")
print("="*80)

print("\nFor this tutorial, we'll use synthetic data.")
print("In real analysis, you would fetch data using fetch_market_data().")

# Generate sample returns
np.random.seed(42)
n_obs = 200  # Number of observations
dates = pd.date_range(start='2020-01-01', periods=n_obs, freq='D')

# Create correlated returns for 3 markets
correlation = np.array([
    [1.0, 0.45, 0.50],  # SP500 correlations with others
    [0.45, 1.0, 0.55],  # SSE correlations with others
    [0.50, 0.55, 1.0]   # TAIEX correlations with others
])

# Generate correlated normal random variables
L = np.linalg.cholesky(correlation)
returns_data = np.zeros((n_obs, 3))

for t in range(n_obs):
    z = np.random.randn(3)
    returns_data[t] = (L @ z) * 0.8  # Base volatility

# Add some volatility clustering
for t in range(10, n_obs):
    if abs(returns_data[t-1]).mean() > 0.5:
        returns_data[t] *= 1.5  # Increase volatility after large shocks

returns = pd.DataFrame(
    returns_data * 100,  # Scale to percentage returns
    index=dates,
    columns=['SP500', 'SSE', 'TAIEX']
)

print(f"\n✓ Data prepared: {returns.shape[0]} observations, {returns.shape[1]} markets")
print("\nFirst few observations:")
print(returns.head())
print("\nSummary statistics:")
print(returns.describe().round(4))

# =============================================================================
# STEP 2: Exploratory Data Analysis
# =============================================================================
print("\n" + "="*80)
print("STEP 2: EXPLORATORY DATA ANALYSIS")
print("="*80)

print("\nUnconditional correlation matrix:")
print(returns.corr().round(4))

print("\nVolatility (standard deviation) by market:")
print(returns.std().round(4))

# =============================================================================
# STEP 3: Initialize the BEKK Model
# =============================================================================
print("\n" + "="*80)
print("STEP 3: MODEL INITIALIZATION")
print("="*80)

model = AsymmetricBEKK(returns)
print(f"\n✓ Asymmetric BEKK model initialized")
print(f"  - Number of assets: {model.n_assets}")
print(f"  - Number of observations: {model.n_obs}")

# Calculate number of parameters
n_C = int(model.n_assets * (model.n_assets + 1) / 2)  # Lower triangular C
n_A = model.n_assets * model.n_assets  # Full A matrix
n_B = model.n_assets * model.n_assets  # Full B matrix  
n_D = model.n_assets * model.n_assets  # Full D matrix
total_params = n_C + n_A + n_B + n_D

print(f"  - Total parameters: {total_params}")
print(f"    • C matrix (constant): {n_C} parameters")
print(f"    • A matrix (shocks): {n_A} parameters")
print(f"    • B matrix (persistence): {n_B} parameters")
print(f"    • D matrix (asymmetric): {n_D} parameters")

# =============================================================================
# STEP 4: Estimate the Model
# =============================================================================
print("\n" + "="*80)
print("STEP 4: MODEL ESTIMATION")
print("="*80)

print("\nEstimating parameters using maximum likelihood...")
print("(This may take a few minutes depending on data size)")
print("\nOptimization method: BFGS")
print("Maximum iterations: 50 (limited for tutorial speed)")

result = model.fit(method='BFGS', maxiter=50)

print(f"\n✓ Optimization completed")
print(f"  - Final log-likelihood: {-result.fun:.4f}")
print(f"  - Function evaluations: {result.nfev}")
print(f"  - Success: {result.success}")

# =============================================================================
# STEP 5: Extract and Interpret Results
# =============================================================================
print("\n" + "="*80)
print("STEP 5: RESULTS INTERPRETATION")
print("="*80)

# Get the estimated matrices
C, A, B, D = model._vec_to_matrices(model.params)

print("\n5.1 SHOCK SPILLOVER MATRIX (A)")
print("-" * 80)
print("\nThis shows how shocks (innovations) in one market affect volatility in others.")
A_df = pd.DataFrame(A, index=['SP500', 'SSE', 'TAIEX'], columns=['SP500', 'SSE', 'TAIEX'])
print(A_df.round(4))

print("\nKey observations:")
print(f"  • SP500 own-shock effect: {A[0,0]:.4f}")
print(f"  • SP500 → SSE spillover: {A[1,0]:.4f}")
print(f"  • SP500 → TAIEX spillover: {A[2,0]:.4f}")

print("\n5.2 VOLATILITY PERSISTENCE MATRIX (B)")
print("-" * 80)
print("\nThis shows how past volatility persists in each market.")
B_df = pd.DataFrame(B, index=['SP500', 'SSE', 'TAIEX'], columns=['SP500', 'SSE', 'TAIEX'])
print(B_df.round(4))

print("\nKey observations:")
print(f"  • SP500 persistence: {B[0,0]:.4f}")
print(f"  • SSE persistence: {B[1,1]:.4f}")
print(f"  • TAIEX persistence: {B[2,2]:.4f}")

print("\n5.3 ASYMMETRIC EFFECTS MATRIX (D)")
print("-" * 80)
print("\nThis captures leverage effects (negative shocks have different impact).")
D_df = pd.DataFrame(D, index=['SP500', 'SSE', 'TAIEX'], columns=['SP500', 'SSE', 'TAIEX'])
print(D_df.round(4))

print("\nInterpretation:")
print("  • Positive values: Negative shocks increase volatility more")
print("  • This is the 'leverage effect' common in financial markets")

# =============================================================================
# STEP 6: Conditional Correlations
# =============================================================================
print("\n" + "="*80)
print("STEP 6: DYNAMIC CORRELATIONS")
print("="*80)

correlations = model.get_conditional_correlations()

print("\nAverage conditional correlations over the sample period:")
avg_corr = np.mean(correlations, axis=0)
avg_corr_df = pd.DataFrame(avg_corr, index=['SP500', 'SSE', 'TAIEX'], 
                           columns=['SP500', 'SSE', 'TAIEX'])
print(avg_corr_df.round(4))

print("\nCorrelation statistics:")
sp_sse_corr = correlations[:, 0, 1]
sp_taiex_corr = correlations[:, 0, 2]
sse_taiex_corr = correlations[:, 1, 2]

print(f"\nSP500-SSE correlation:")
print(f"  Mean: {np.mean(sp_sse_corr):.4f}, Std: {np.std(sp_sse_corr):.4f}")
print(f"  Range: [{np.min(sp_sse_corr):.4f}, {np.max(sp_sse_corr):.4f}]")

print(f"\nSP500-TAIEX correlation:")
print(f"  Mean: {np.mean(sp_taiex_corr):.4f}, Std: {np.std(sp_taiex_corr):.4f}")
print(f"  Range: [{np.min(sp_taiex_corr):.4f}, {np.max(sp_taiex_corr):.4f}]")

print(f"\nSSE-TAIEX correlation:")
print(f"  Mean: {np.mean(sse_taiex_corr):.4f}, Std: {np.std(sse_taiex_corr):.4f}")
print(f"  Range: [{np.min(sse_taiex_corr):.4f}, {np.max(sse_taiex_corr):.4f}]")

# =============================================================================
# SUMMARY
# =============================================================================
print("\n" + "="*80)
print("TUTORIAL COMPLETE!")
print("="*80)

print("\n✓ What we learned:")
print("  1. How to prepare return data for BEKK analysis")
print("  2. How to initialize and estimate an asymmetric BEKK model")
print("  3. How to interpret shock spillovers (A matrix)")
print("  4. How to interpret volatility persistence (B matrix)")
print("  5. How to interpret leverage effects (D matrix)")
print("  6. How to analyze time-varying correlations")

print("\n📚 Next steps:")
print("  • Use real market data with asymmetric_bekk_model.py")
print("  • Experiment with different time periods")
print("  • Analyze specific crisis periods")
print("  • Compare results across different market combinations")
print("  • Generate visualizations with plot_results()")

print("\n" + "="*80)
