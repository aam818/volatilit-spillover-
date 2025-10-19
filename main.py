"""
Main Script for Asymmetric Volatility Spillover Analysis
Analyzes volatility spillovers from US (S&P 500) and China (SSE) to Taiwan Technology Index
Using Asymmetric DCC-GARCH and Asymmetric BEKK-GARCH models
"""

import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings('ignore')

from data_fetcher import DataFetcher
from asymmetric_dcc_garch import AsymmetricDCCGARCH
from asymmetric_bekk_garch import AsymmetricBEKKGARCH


def print_header(text):
    """Print formatted header"""
    print("\n" + "="*70)
    print(text.center(70))
    print("="*70 + "\n")


def main():
    """
    Main analysis pipeline
    """
    print_header("ASYMMETRIC VOLATILITY SPILLOVER ANALYSIS")
    print("Analyzing spillovers from US (S&P 500) and China (SSE)")
    print("to Taiwan Technology Index")
    print("\nUsing:")
    print("  1. Asymmetric DCC-GARCH Model")
    print("  2. Asymmetric BEKK-GARCH Model")
    
    # Step 1: Fetch Data
    print_header("STEP 1: DATA COLLECTION")
    
    fetcher = DataFetcher(start_date='2019-01-01')  # 5+ years of data
    prices = fetcher.fetch_data()
    returns = fetcher.calculate_returns(prices)
    
    # Save raw data
    fetcher.save_data(prices, 'prices.csv')
    fetcher.save_data(returns, 'returns.csv')
    
    print("\n✓ Data collection completed!")
    
    # Step 2: Asymmetric DCC-GARCH Model
    print_header("STEP 2: ASYMMETRIC DCC-GARCH MODEL")
    
    print("Fitting Asymmetric DCC-GARCH model...")
    print("This model uses GJR-GARCH for univariate volatility (captures asymmetry)")
    print("and DCC for dynamic conditional correlations")
    
    dcc_model = AsymmetricDCCGARCH(returns)
    dcc_model.fit_univariate_models(p=1, o=1, q=1)  # GJR-GARCH(1,1,1)
    dcc_model.estimate_dcc()
    dcc_correlations = dcc_model.analyze_spillovers()
    dcc_model.plot_results(output_prefix='dcc_garch')
    dcc_model.save_results(output_prefix='dcc_garch')
    
    print("\n✓ DCC-GARCH analysis completed!")
    
    # Step 3: Asymmetric BEKK-GARCH Model
    print_header("STEP 3: ASYMMETRIC BEKK-GARCH MODEL")
    
    print("Fitting Asymmetric BEKK-GARCH model...")
    print("This model captures asymmetric volatility spillovers between markets")
    print("Note: This may take several minutes to converge...")
    
    bekk_model = AsymmetricBEKKGARCH(returns)
    bekk_model.fit(max_iter=500)  # May need more iterations for full convergence
    bekk_correlations = bekk_model.analyze_spillovers()
    bekk_model.plot_results(output_prefix='bekk_garch')
    bekk_model.save_results(output_prefix='bekk_garch')
    
    print("\n✓ BEKK-GARCH analysis completed!")
    
    # Step 4: Summary and Comparison
    print_header("STEP 4: SUMMARY AND COMPARISON")
    
    print("\n1. Average Correlations from DCC-GARCH:")
    print(dcc_correlations.mean())
    
    print("\n2. Average Correlations from BEKK-GARCH:")
    print(bekk_correlations.mean())
    
    print("\n3. Key Findings:")
    print("\nDCC-GARCH Results:")
    print(f"  - US-Taiwan correlation: {dcc_correlations['US-Taiwan'].mean():.4f}")
    print(f"  - China-Taiwan correlation: {dcc_correlations['China-Taiwan'].mean():.4f}")
    print(f"  - US-China correlation: {dcc_correlations['US-China'].mean():.4f}")
    
    print("\nBEKK-GARCH Results:")
    print(f"  - US-Taiwan correlation: {bekk_correlations['US-Taiwan'].mean():.4f}")
    print(f"  - China-Taiwan correlation: {bekk_correlations['China-Taiwan'].mean():.4f}")
    print(f"  - US-China correlation: {bekk_correlations['US-China'].mean():.4f}")
    
    # Create summary report
    with open('analysis_summary.txt', 'w') as f:
        f.write("="*70 + "\n")
        f.write("ASYMMETRIC VOLATILITY SPILLOVER ANALYSIS SUMMARY\n")
        f.write("="*70 + "\n\n")
        
        f.write("OBJECTIVE:\n")
        f.write("Analyze asymmetric volatility spillovers from US (S&P 500) and China (SSE)\n")
        f.write("to Taiwan Technology Index\n\n")
        
        f.write("DATA:\n")
        f.write(f"Period: {returns.index[0]} to {returns.index[-1]}\n")
        f.write(f"Observations: {len(returns)}\n")
        f.write(f"Markets: US (S&P 500), China (SSE), Taiwan (Technology Index)\n\n")
        
        f.write("MODELS:\n")
        f.write("1. Asymmetric DCC-GARCH (GJR-GARCH + DCC)\n")
        f.write("2. Asymmetric BEKK-GARCH\n\n")
        
        f.write("RESULTS:\n")
        f.write("\nDCC-GARCH Average Correlations:\n")
        f.write(str(dcc_correlations.mean()) + "\n\n")
        
        f.write("BEKK-GARCH Average Correlations:\n")
        f.write(str(bekk_correlations.mean()) + "\n\n")
        
        f.write("INTERPRETATION:\n")
        f.write("- Higher correlation values indicate stronger co-movement\n")
        f.write("- Asymmetric effects capture leverage effects (bad news impact > good news)\n")
        f.write("- Dynamic correlations show time-varying spillover intensities\n")
        f.write("- Off-diagonal elements in BEKK matrices show cross-market spillovers\n")
    
    print("\n✓ Summary report saved to: analysis_summary.txt")
    
    print_header("ANALYSIS COMPLETE")
    
    print("Output Files Generated:")
    print("\nData Files:")
    print("  - prices.csv")
    print("  - returns.csv")
    print("\nDCC-GARCH Results:")
    print("  - dcc_garch_volatility.csv")
    print("  - dcc_garch_correlations.csv")
    print("  - dcc_garch_parameters.txt")
    print("  - dcc_garch_volatility.png")
    print("  - dcc_garch_correlations.png")
    print("  - dcc_garch_heatmap.png")
    print("\nBEKK-GARCH Results:")
    print("  - bekk_garch_volatility.csv")
    print("  - bekk_garch_correlations.csv")
    print("  - bekk_garch_parameters.txt")
    print("  - bekk_garch_volatility.png")
    print("  - bekk_garch_correlations.png")
    print("  - bekk_garch_parameters.png")
    print("\nSummary:")
    print("  - analysis_summary.txt")
    
    print("\nThank you for using the Volatility Spillover Analysis Tool!")


if __name__ == "__main__":
    main()
