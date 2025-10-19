"""
Example script using sample data for Asymmetric BEKK Model
This script can be used when internet access is not available
"""

import numpy as np
import pandas as pd
from asymmetric_bekk_model import AsymmetricBEKK, calculate_returns, plot_results, print_spillover_analysis

def generate_sample_market_data():
    """
    Generate sample correlated return data that mimics S&P 500, SSE, and TAIEX behavior.
    This is for demonstration purposes when real data is not accessible.
    """
    np.random.seed(42)
    
    # Number of observations (approximately 5 years of daily data)
    n_obs = 1250
    
    # Generate dates
    dates = pd.date_range(start='2019-01-01', periods=n_obs, freq='B')
    
    # Parameters for correlated returns
    # Correlation structure between markets
    corr_matrix = np.array([
        [1.0, 0.4, 0.5],   # SP500 correlations
        [0.4, 1.0, 0.6],   # SSE correlations
        [0.5, 0.6, 1.0]    # TAIEX correlations
    ])
    
    # Generate correlated normal random variables
    L = np.linalg.cholesky(corr_matrix)
    
    # Base volatilities for each market (annualized)
    base_vols = np.array([0.15, 0.20, 0.18])  # SP500, SSE, TAIEX
    daily_vols = base_vols / np.sqrt(252)
    
    # Generate returns with time-varying volatility
    returns = np.zeros((n_obs, 3))
    
    for t in range(n_obs):
        # Add some volatility clustering
        vol_factor = 1.0 + 0.3 * np.sin(t / 50.0)
        
        # Generate correlated shocks
        z = np.random.randn(3)
        eps = L @ z
        
        # Scale by volatility
        returns[t] = eps * daily_vols * vol_factor
    
    # Create DataFrame
    returns_df = pd.DataFrame(
        returns,
        index=dates[:n_obs],
        columns=['SP500', 'SSE', 'TAIEX']
    )
    
    # Scale to percentage returns
    returns_df = returns_df * 100
    
    print("Sample market data generated:")
    print(f"Date range: {returns_df.index[0]} to {returns_df.index[-1]}")
    print(f"Number of observations: {len(returns_df)}")
    print("\nReturns summary statistics:")
    print(returns_df.describe())
    
    return returns_df


def main():
    """Main execution function using sample data."""
    print("="*70)
    print("ASYMMETRIC BEKK MODEL - EXAMPLE WITH SAMPLE DATA")
    print("Markets: S&P 500, SSE Composite, and TAIEX")
    print("="*70)
    print("\nNote: This example uses simulated data for demonstration.")
    print("For real analysis, use asymmetric_bekk_model.py with live data.\n")
    
    # Generate sample data
    returns = generate_sample_market_data()
    
    # Initialize and fit Asymmetric BEKK model
    print("\n" + "="*70)
    print("FITTING ASYMMETRIC BEKK MODEL")
    print("="*70)
    
    model = AsymmetricBEKK(returns)
    result = model.fit(method='BFGS', maxiter=100)  # Reduced iterations for demo
    
    # Print results
    print_spillover_analysis(model, returns)
    
    # Create visualizations
    print("\nGenerating visualizations...")
    plot_results(returns, model, save_path='bekk_results_sample.png')
    
    print("\n" + "="*70)
    print("ANALYSIS COMPLETE!")
    print("="*70)
    print("\nResults have been saved to 'bekk_results_sample.png'")
    print("\nThis example demonstrates the model with sample data.")
    print("The actual magnitudes and patterns will differ with real market data.")


if __name__ == "__main__":
    main()
