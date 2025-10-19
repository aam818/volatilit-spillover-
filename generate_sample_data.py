"""
Generate Sample Data for Volatility Spillover Analysis
Creates realistic synthetic data when live data cannot be fetched
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta


def generate_sample_data(n_obs=1260, start_date='2020-01-01'):
    """
    Generate sample returns data that mimics real financial returns
    
    Parameters:
    -----------
    n_obs : int
        Number of observations (default: 1260, approximately 5 years of trading days)
    start_date : str
        Start date for the data
        
    Returns:
    --------
    pd.DataFrame
        Sample returns data for US, China, and Taiwan
    """
    np.random.seed(42)  # For reproducibility
    
    # Generate dates (business days)
    dates = pd.bdate_range(start=start_date, periods=n_obs)
    
    # Correlation structure
    corr_us_china = 0.45
    corr_us_taiwan = 0.55
    corr_china_taiwan = 0.50
    
    # Create correlation matrix
    corr_matrix = np.array([
        [1.0, corr_us_china, corr_us_taiwan],
        [corr_us_china, 1.0, corr_china_taiwan],
        [corr_us_taiwan, corr_china_taiwan, 1.0]
    ])
    
    # Generate correlated innovations using Cholesky decomposition
    L = np.linalg.cholesky(corr_matrix)
    
    # Initialize arrays
    returns = np.zeros((n_obs, 3))
    
    # GARCH parameters
    omega = np.array([0.01, 0.015, 0.012])
    alpha = np.array([0.08, 0.10, 0.09])
    gamma = np.array([0.05, 0.06, 0.055])  # Asymmetry parameter
    beta = np.array([0.88, 0.85, 0.87])
    
    # Initial conditional variance
    h = np.array([0.8**2, 1.0**2, 0.9**2])
    
    for t in range(n_obs):
        # Generate correlated standard normal innovations
        z = np.random.randn(3)
        eps_std = L @ z
        
        # Generate returns with time-varying volatility
        volatility = np.sqrt(h)
        returns[t] = volatility * eps_std
        
        # Update volatility for next period using GJR-GARCH
        # h_t = omega + alpha * eps^2_{t-1} + gamma * I_{eps<0} * eps^2_{t-1} + beta * h_{t-1}
        eps_squared = returns[t]**2
        indicator = (returns[t] < 0).astype(float)
        h = omega + alpha * eps_squared + gamma * indicator * eps_squared + beta * h
        
        # Ensure h stays positive and bounded
        h = np.clip(h, 0.01, 10.0)
    
    # Add some crisis periods (increase volatility)
    crisis_periods = [(200, 240), (600, 630), (1000, 1030)]
    
    for start, end in crisis_periods:
        if end <= n_obs:
            returns[start:end] *= 1.3
    
    # Create DataFrame
    df = pd.DataFrame(
        returns,
        index=dates,
        columns=['US', 'China', 'Taiwan']
    )
    
    print("Sample data generated successfully!")
    print(f"Shape: {df.shape}")
    print(f"Date range: {df.index[0]} to {df.index[-1]}")
    print("\nDescriptive Statistics:")
    print(df.describe())
    print("\nCorrelation Matrix:")
    print(df.corr())
    
    return df


def generate_sample_prices(returns_data, initial_price=1000):
    """
    Convert returns to price levels
    
    Parameters:
    -----------
    returns_data : pd.DataFrame
        Returns data
    initial_price : float
        Initial price level
        
    Returns:
    --------
    pd.DataFrame
        Price data
    """
    # Convert percentage returns to decimal returns (returns are in %)
    decimal_returns = returns_data / 100
    
    # Clip extreme values to prevent overflow
    decimal_returns = decimal_returns.clip(-0.5, 0.5)
    
    # Generate prices using cumulative product
    prices = initial_price * (1 + decimal_returns).cumprod()
    
    return prices


if __name__ == "__main__":
    # Generate sample data
    returns = generate_sample_data()
    prices = generate_sample_prices(returns)
    
    # Save data
    prices.to_csv('prices.csv')
    returns.to_csv('returns.csv')
    
    print("\nData saved to:")
    print("  - prices.csv")
    print("  - returns.csv")
