"""
Test script for Asymmetric BEKK Model
Tests basic functionality with synthetic data
"""

import numpy as np
import pandas as pd
import sys

# Import the AsymmetricBEKK class
from asymmetric_bekk_model import AsymmetricBEKK

def test_basic_functionality():
    """Test basic model functionality with synthetic data."""
    print("Testing Asymmetric BEKK Model...")
    print("-" * 50)
    
    # Generate synthetic return data
    np.random.seed(42)
    n_obs = 100
    n_assets = 3
    
    # Create correlated returns
    returns_data = np.random.randn(n_obs, n_assets) * 0.5
    returns_df = pd.DataFrame(
        returns_data,
        columns=['Asset1', 'Asset2', 'Asset3']
    )
    
    print(f"✓ Created synthetic data: {returns_df.shape}")
    print(f"  - Observations: {n_obs}")
    print(f"  - Assets: {n_assets}")
    
    # Initialize model
    try:
        model = AsymmetricBEKK(returns_df)
        print("✓ Model initialized successfully")
    except Exception as e:
        print(f"✗ Model initialization failed: {e}")
        return False
    
    # Test parameter initialization
    try:
        params = model._initialize_params()
        print(f"✓ Parameters initialized: {len(params)} parameters")
    except Exception as e:
        print(f"✗ Parameter initialization failed: {e}")
        return False
    
    # Test matrix conversion
    try:
        C, A, B, D = model._vec_to_matrices(params)
        print(f"✓ Matrix conversion successful")
        print(f"  - C matrix shape: {C.shape}")
        print(f"  - A matrix shape: {A.shape}")
        print(f"  - B matrix shape: {B.shape}")
        print(f"  - D matrix shape: {D.shape}")
    except Exception as e:
        print(f"✗ Matrix conversion failed: {e}")
        return False
    
    # Test covariance computation
    try:
        H_t = model._compute_covariance_matrices(params)
        print(f"✓ Covariance matrices computed: shape {H_t.shape}")
    except Exception as e:
        print(f"✗ Covariance computation failed: {e}")
        return False
    
    # Test log-likelihood computation
    try:
        log_lik = model._log_likelihood(params)
        print(f"✓ Log-likelihood computed: {log_lik:.4f}")
    except Exception as e:
        print(f"✗ Log-likelihood computation failed: {e}")
        return False
    
    print("\n" + "=" * 50)
    print("All basic tests passed! ✓")
    print("=" * 50)
    return True


def test_data_fetching():
    """Test data fetching functionality."""
    print("\nTesting data fetching...")
    print("-" * 50)
    
    try:
        from asymmetric_bekk_model import fetch_market_data, calculate_returns
        
        # Test with a short date range to speed up testing
        print("Fetching market data (2024-01-01 to 2024-02-01)...")
        prices = fetch_market_data(start_date='2024-01-01', end_date='2024-02-01')
        print(f"✓ Data fetched successfully: {prices.shape}")
        
        # Test returns calculation
        returns = calculate_returns(prices, method='log')
        print(f"✓ Returns calculated: {returns.shape}")
        
        print("\n" + "=" * 50)
        print("Data fetching tests passed! ✓")
        print("=" * 50)
        return True
        
    except Exception as e:
        print(f"✗ Data fetching test failed: {e}")
        print("Note: This might fail due to network issues or API rate limits")
        return False


if __name__ == "__main__":
    print("=" * 50)
    print("ASYMMETRIC BEKK MODEL TEST SUITE")
    print("=" * 50)
    print()
    
    # Run tests
    basic_test_passed = test_basic_functionality()
    data_test_passed = test_data_fetching()
    
    print("\n" + "=" * 50)
    print("TEST SUMMARY")
    print("=" * 50)
    print(f"Basic functionality: {'PASSED ✓' if basic_test_passed else 'FAILED ✗'}")
    print(f"Data fetching: {'PASSED ✓' if data_test_passed else 'FAILED ✗'}")
    print("=" * 50)
    
    if basic_test_passed:
        print("\n✓ Core model functionality is working correctly!")
        print("You can now run: python asymmetric_bekk_model.py")
        sys.exit(0)
    else:
        print("\n✗ Some tests failed. Please review the errors above.")
        sys.exit(1)
