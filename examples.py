"""
Example Usage Script
Demonstrates how to use the volatility spillover analysis tools
"""

import pandas as pd
import numpy as np
from data_fetcher import DataFetcher
from asymmetric_dcc_garch import AsymmetricDCCGARCH
from asymmetric_bekk_garch import AsymmetricBEKKGARCH
from generate_sample_data import generate_sample_data, generate_sample_prices


def example_1_full_analysis():
    """
    Example 1: Complete analysis with data fetching
    """
    print("\n" + "="*60)
    print("EXAMPLE 1: Full Analysis Pipeline")
    print("="*60)
    
    # Step 1: Try to fetch real data, use sample if unavailable
    try:
        print("\nAttempting to fetch real market data...")
        fetcher = DataFetcher(start_date='2020-01-01')
        prices = fetcher.fetch_data()
        returns = fetcher.calculate_returns(prices)
    except Exception as e:
        print(f"\nCould not fetch real data: {e}")
        print("Using sample data for demonstration...")
        returns = generate_sample_data()
        prices = generate_sample_prices(returns)
    
    # Step 2: Run DCC-GARCH
    print("\n" + "-"*60)
    print("Running Asymmetric DCC-GARCH Model...")
    print("-"*60)
    
    dcc_model = AsymmetricDCCGARCH(returns)
    dcc_model.fit_univariate_models(p=1, o=1, q=1)
    dcc_model.estimate_dcc()
    dcc_corr = dcc_model.analyze_spillovers()
    dcc_model.plot_results(output_prefix='example1_dcc')
    dcc_model.save_results(output_prefix='example1_dcc')
    
    # Step 3: Run BEKK-GARCH
    print("\n" + "-"*60)
    print("Running Asymmetric BEKK-GARCH Model...")
    print("-"*60)
    
    bekk_model = AsymmetricBEKKGARCH(returns)
    bekk_model.fit(max_iter=100)
    bekk_corr = bekk_model.analyze_spillovers()
    bekk_model.plot_results(output_prefix='example1_bekk')
    bekk_model.save_results(output_prefix='example1_bekk')
    
    print("\n✓ Example 1 completed!")
    print("Check the 'example1_*' files for results")


def example_2_dcc_only():
    """
    Example 2: DCC-GARCH analysis only
    """
    print("\n" + "="*60)
    print("EXAMPLE 2: DCC-GARCH Only")
    print("="*60)
    
    # Load or generate data
    try:
        returns = pd.read_csv('returns.csv', index_col=0, parse_dates=True)
    except Exception:
        returns = generate_sample_data()
    
    # Run DCC-GARCH
    model = AsymmetricDCCGARCH(returns)
    model.fit_univariate_models(p=1, o=1, q=1)
    model.estimate_dcc()
    correlations = model.analyze_spillovers()
    
    # Print key results
    print("\nAverage Correlations:")
    print(correlations.mean())
    
    print("\nCorrelation Volatility (std):")
    print(correlations.std())
    
    model.plot_results(output_prefix='example2_dcc')
    
    print("\n✓ Example 2 completed!")


def example_3_bekk_only():
    """
    Example 3: BEKK-GARCH analysis only
    """
    print("\n" + "="*60)
    print("EXAMPLE 3: BEKK-GARCH Only")
    print("="*60)
    
    # Load or generate data
    try:
        returns = pd.read_csv('returns.csv', index_col=0, parse_dates=True)
    except Exception:
        returns = generate_sample_data()
    
    # Run BEKK-GARCH
    model = AsymmetricBEKKGARCH(returns)
    model.fit(max_iter=200)
    correlations = model.analyze_spillovers()
    
    # Print key spillover effects
    print("\nSpillover Effects Summary:")
    print("US → Taiwan:", correlations['US-Taiwan'].mean())
    print("China → Taiwan:", correlations['China-Taiwan'].mean())
    
    model.plot_results(output_prefix='example3_bekk')
    
    print("\n✓ Example 3 completed!")


def example_4_custom_data():
    """
    Example 4: Using custom data
    """
    print("\n" + "="*60)
    print("EXAMPLE 4: Custom Data Analysis")
    print("="*60)
    
    # Generate custom sample data
    custom_returns = generate_sample_data(n_obs=500, start_date='2022-01-01')
    
    # Run quick DCC analysis
    model = AsymmetricDCCGARCH(custom_returns)
    model.fit_univariate_models(p=1, o=1, q=1)
    model.estimate_dcc()
    correlations = model.analyze_spillovers()
    
    print("\nCustom Data Results:")
    print(f"Sample size: {len(custom_returns)}")
    print(f"Average US-Taiwan correlation: {correlations['US-Taiwan'].mean():.4f}")
    
    print("\n✓ Example 4 completed!")


def main():
    """
    Run all examples or specific ones
    """
    print("\n" + "="*70)
    print("VOLATILITY SPILLOVER ANALYSIS - USAGE EXAMPLES")
    print("="*70)
    
    print("\nAvailable examples:")
    print("1. Full analysis pipeline (DCC + BEKK)")
    print("2. DCC-GARCH only")
    print("3. BEKK-GARCH only")
    print("4. Custom data analysis")
    print("\nChoose an example to run (1-4), or 'all' to run all examples:")
    print("(In automated mode, running Example 1...)\n")
    
    # For automated execution, run example 1
    example_1_full_analysis()
    
    print("\n" + "="*70)
    print("All examples completed successfully!")
    print("="*70)
    print("\nTo run specific examples, import this module and call:")
    print("  - example_1_full_analysis()")
    print("  - example_2_dcc_only()")
    print("  - example_3_bekk_only()")
    print("  - example_4_custom_data()")


if __name__ == "__main__":
    main()
