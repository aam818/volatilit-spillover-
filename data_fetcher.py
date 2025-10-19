"""
Data Fetcher Module for Volatility Spillover Analysis
Fetches financial data for S&P 500 (US), SSE Composite (China), and Taiwan Technology Index
"""

import yfinance as yf
import pandas as pd
import numpy as np
from datetime import datetime, timedelta


class DataFetcher:
    def __init__(self, start_date=None, end_date=None):
        """
        Initialize DataFetcher with date range
        
        Parameters:
        -----------
        start_date : str or datetime
            Start date for data fetching (default: 5 years ago)
        end_date : str or datetime
            End date for data fetching (default: today)
        """
        if start_date is None:
            start_date = (datetime.now() - timedelta(days=5*365)).strftime('%Y-%m-%d')
        if end_date is None:
            end_date = datetime.now().strftime('%Y-%m-%d')
            
        self.start_date = start_date
        self.end_date = end_date
        
        # Ticker symbols
        self.us_ticker = '^GSPC'  # S&P 500
        self.china_ticker = '000001.SS'  # SSE Composite Index
        self.taiwan_ticker = '^TWII'  # Taiwan Weighted Index (proxy for tech sector)
        
    def fetch_data(self):
        """
        Fetch historical price data for all three indices
        
        Returns:
        --------
        pd.DataFrame
            DataFrame containing adjusted close prices for all three indices
        """
        print(f"Fetching data from {self.start_date} to {self.end_date}")
        
        # Fetch data
        print(f"Downloading S&P 500 ({self.us_ticker})...")
        us_data = yf.download(self.us_ticker, start=self.start_date, end=self.end_date, progress=False)
        
        print(f"Downloading SSE Composite ({self.china_ticker})...")
        china_data = yf.download(self.china_ticker, start=self.start_date, end=self.end_date, progress=False)
        
        print(f"Downloading Taiwan Index ({self.taiwan_ticker})...")
        taiwan_data = yf.download(self.taiwan_ticker, start=self.start_date, end=self.end_date, progress=False)
        
        # Combine data
        data = pd.DataFrame({
            'US': us_data['Adj Close'] if 'Adj Close' in us_data.columns else us_data['Close'],
            'China': china_data['Adj Close'] if 'Adj Close' in china_data.columns else china_data['Close'],
            'Taiwan': taiwan_data['Adj Close'] if 'Adj Close' in taiwan_data.columns else taiwan_data['Close']
        })
        
        # Remove NaN values
        data = data.dropna()
        
        print(f"\nData fetched successfully!")
        print(f"Total observations: {len(data)}")
        print(f"Date range: {data.index[0]} to {data.index[-1]}")
        
        return data
    
    def calculate_returns(self, data):
        """
        Calculate log returns from price data
        
        Parameters:
        -----------
        data : pd.DataFrame
            Price data
            
        Returns:
        --------
        pd.DataFrame
            Log returns
        """
        returns = np.log(data / data.shift(1)) * 100  # Convert to percentage
        returns = returns.dropna()
        
        print(f"\nReturns calculated:")
        print(f"Shape: {returns.shape}")
        print(f"\nDescriptive Statistics:")
        print(returns.describe())
        
        return returns
    
    def save_data(self, data, filename='data.csv'):
        """
        Save data to CSV file
        
        Parameters:
        -----------
        data : pd.DataFrame
            Data to save
        filename : str
            Output filename
        """
        data.to_csv(filename)
        print(f"\nData saved to {filename}")


if __name__ == "__main__":
    # Example usage
    fetcher = DataFetcher()
    prices = fetcher.fetch_data()
    returns = fetcher.calculate_returns(prices)
    
    # Save data
    fetcher.save_data(prices, 'prices.csv')
    fetcher.save_data(returns, 'returns.csv')
