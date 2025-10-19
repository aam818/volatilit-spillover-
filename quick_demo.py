"""
Quick demo of Asymmetric BEKK Model with minimal data
"""

import numpy as np
import pandas as pd
from asymmetric_bekk_model import AsymmetricBEKK

def quick_demo():
    """Quick demonstration with small dataset."""
    print("="*70)
    print("ASYMMETRIC BEKK MODEL - QUICK DEMO")
    print("="*70)
    
    # Generate small sample data
    np.random.seed(42)
    n_obs = 50  # Small sample for quick demo
    
    dates = pd.date_range(start='2024-01-01', periods=n_obs, freq='D')
    
    # Generate correlated returns
    corr_matrix = np.array([
        [1.0, 0.4, 0.5],
        [0.4, 1.0, 0.6],
        [0.5, 0.6, 1.0]
    ])
    
    L = np.linalg.cholesky(corr_matrix)
    returns = np.zeros((n_obs, 3))
    
    for t in range(n_obs):
        z = np.random.randn(3)
        returns[t] = (L @ z) * 0.5
    
    returns_df = pd.DataFrame(
        returns * 100,
        index=dates,
        columns=['SP500', 'SSE', 'TAIEX']
    )
    
    print(f"\nGenerated {n_obs} observations for 3 markets")
    print("\nReturns summary:")
    print(returns_df.describe().round(4))
    
    # Initialize model
    print("\n" + "="*70)
    print("FITTING ASYMMETRIC BEKK MODEL")
    print("="*70)
    
    model = AsymmetricBEKK(returns_df)
    
    # Quick fit with few iterations
    print("\nRunning optimization (limited iterations for demo)...")
    result = model.fit(method='BFGS', maxiter=5)
    
    # Show parameter structure
    print("\n" + "="*70)
    print("MODEL STRUCTURE")
    print("="*70)
    
    C, A, B, D = model._vec_to_matrices(model.params)
    
    print("\nShock Spillover Matrix (A):")
    print(pd.DataFrame(A, index=['SP500', 'SSE', 'TAIEX'], 
                      columns=['SP500', 'SSE', 'TAIEX']).round(4))
    
    print("\nVolatility Persistence Matrix (B):")
    print(pd.DataFrame(B, index=['SP500', 'SSE', 'TAIEX'], 
                      columns=['SP500', 'SSE', 'TAIEX']).round(4))
    
    print("\nAsymmetric Effects Matrix (D):")
    print(pd.DataFrame(D, index=['SP500', 'SSE', 'TAIEX'], 
                      columns=['SP500', 'SSE', 'TAIEX']).round(4))
    
    print("\n" + "="*70)
    print("DEMO COMPLETE!")
    print("="*70)
    print("\nNote: This is a minimal demo with limited data and iterations.")
    print("For full analysis, use asymmetric_bekk_model.py or example_with_sample_data.py")


if __name__ == "__main__":
    quick_demo()
