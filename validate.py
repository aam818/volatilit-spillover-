"""
Validation Script
Quick tests to ensure all components are working correctly
"""

import sys
import traceback


def test_imports():
    """Test that all required packages can be imported"""
    print("Testing imports...")
    try:
        import pandas as pd
        import numpy as np
        import yfinance as yf
        import matplotlib.pyplot as plt
        import seaborn as sns
        from arch import arch_model
        from scipy.optimize import minimize
        print("✓ All required packages imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Import error: {e}")
        return False


def test_sample_data_generation():
    """Test sample data generation"""
    print("\nTesting sample data generation...")
    try:
        from generate_sample_data import generate_sample_data, generate_sample_prices
        returns = generate_sample_data(n_obs=100, start_date='2024-01-01')
        prices = generate_sample_prices(returns)
        
        assert returns.shape == (100, 3), "Returns shape mismatch"
        assert prices.shape == (100, 3), "Prices shape mismatch"
        assert list(returns.columns) == ['US', 'China', 'Taiwan'], "Column names mismatch"
        
        print("✓ Sample data generation works correctly")
        return True
    except Exception as e:
        print(f"✗ Sample data generation failed: {e}")
        traceback.print_exc()
        return False


def test_dcc_garch():
    """Test DCC-GARCH model"""
    print("\nTesting DCC-GARCH model...")
    try:
        from generate_sample_data import generate_sample_data
        from asymmetric_dcc_garch import AsymmetricDCCGARCH
        
        returns = generate_sample_data(n_obs=100, start_date='2024-01-01')
        model = AsymmetricDCCGARCH(returns)
        model.fit_univariate_models(p=1, o=1, q=1)
        model.estimate_dcc()
        correlations = model.analyze_spillovers()
        
        assert correlations.shape == (100, 3), "Correlations shape mismatch"
        assert all(correlations.columns == ['US-China', 'US-Taiwan', 'China-Taiwan']), "Column names mismatch"
        
        print("✓ DCC-GARCH model works correctly")
        return True
    except Exception as e:
        print(f"✗ DCC-GARCH model failed: {e}")
        traceback.print_exc()
        return False


def test_bekk_garch():
    """Test BEKK-GARCH model"""
    print("\nTesting BEKK-GARCH model...")
    try:
        from generate_sample_data import generate_sample_data
        from asymmetric_bekk_garch import AsymmetricBEKKGARCH
        
        returns = generate_sample_data(n_obs=100, start_date='2024-01-01')
        model = AsymmetricBEKKGARCH(returns)
        model.fit(max_iter=50)  # Reduced iterations for quick test
        correlations = model.analyze_spillovers()
        
        assert correlations.shape == (100, 3), "Correlations shape mismatch"
        assert model.params is not None, "Model parameters not estimated"
        
        print("✓ BEKK-GARCH model works correctly")
        return True
    except Exception as e:
        print(f"✗ BEKK-GARCH model failed: {e}")
        traceback.print_exc()
        return False


def test_data_fetcher():
    """Test data fetcher (may fail due to network restrictions)"""
    print("\nTesting data fetcher...")
    try:
        from data_fetcher import DataFetcher
        
        fetcher = DataFetcher(start_date='2024-01-01', end_date='2024-01-31')
        # Don't actually fetch data as it requires internet
        print("✓ Data fetcher module imported successfully")
        print("  (Actual data fetching not tested due to network restrictions)")
        return True
    except Exception as e:
        print(f"✗ Data fetcher import failed: {e}")
        return False


def run_all_tests():
    """Run all validation tests"""
    print("="*60)
    print("VOLATILITY SPILLOVER ANALYSIS - VALIDATION TESTS")
    print("="*60)
    
    tests = [
        ("Package Imports", test_imports),
        ("Sample Data Generation", test_sample_data_generation),
        ("Data Fetcher", test_data_fetcher),
        ("DCC-GARCH Model", test_dcc_garch),
        ("BEKK-GARCH Model", test_bekk_garch),
    ]
    
    results = []
    for test_name, test_func in tests:
        print("\n" + "-"*60)
        result = test_func()
        results.append((test_name, result))
    
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{status}: {test_name}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! The system is ready to use.")
        return 0
    else:
        print(f"\n⚠ {total - passed} test(s) failed. Please check the errors above.")
        return 1


if __name__ == "__main__":
    exit_code = run_all_tests()
    sys.exit(exit_code)
