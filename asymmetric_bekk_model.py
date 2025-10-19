"""
Asymmetric BEKK Model for Volatility Spillover Analysis
=========================================================

This script implements an asymmetric BEKK (Baba, Engle, Kraft, and Kroner) model
to analyze volatility spillovers between three financial markets:
- S&P 500 (US market)
- SSE Composite Index (Shanghai Stock Exchange - China)
- TAIEX (Taiwan Stock Exchange)

The asymmetric BEKK model captures both volatility spillovers and asymmetric
effects (leverage effects) where negative shocks have different impacts than
positive shocks on volatility.
"""

import numpy as np
import pandas as pd
import yfinance as yf
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
from scipy.optimize import minimize
import warnings
warnings.filterwarnings('ignore')


class AsymmetricBEKK:
    """
    Asymmetric BEKK-GARCH model for multivariate volatility analysis.
    
    The conditional covariance matrix follows:
    H_t = C'C + A' * ε_{t-1} * ε_{t-1}' * A + B' * H_{t-1} * B + D' * η_{t-1} * η_{t-1}' * D
    
    where η_{t-1} = ε_{t-1} * I(ε_{t-1} < 0) captures asymmetric effects.
    """
    
    def __init__(self, returns):
        """
        Initialize the Asymmetric BEKK model.
        
        Parameters:
        -----------
        returns : pd.DataFrame
            DataFrame containing return series for multiple assets
        """
        self.returns = returns
        self.n_assets = returns.shape[1]
        self.n_obs = returns.shape[0]
        self.params = None
        self.H_t = None
        
    def _initialize_params(self):
        """Initialize model parameters."""
        n = self.n_assets
        
        # C matrix (lower triangular)
        C_size = int(n * (n + 1) / 2)
        C_init = np.random.randn(C_size) * 0.1
        
        # A matrix (vectorized)
        A_size = n * n
        A_init = np.random.randn(A_size) * 0.1
        
        # B matrix (vectorized)
        B_size = n * n
        B_init = np.random.randn(B_size) * 0.1
        
        # D matrix (vectorized, for asymmetric effects)
        D_size = n * n
        D_init = np.random.randn(D_size) * 0.05
        
        return np.concatenate([C_init, A_init, B_init, D_init])
    
    def _vec_to_matrices(self, params):
        """Convert parameter vector to matrices."""
        n = self.n_assets
        C_size = int(n * (n + 1) / 2)
        A_size = n * n
        B_size = n * n
        
        # Extract C parameters and construct lower triangular matrix
        C_vec = params[:C_size]
        C = np.zeros((n, n))
        idx = 0
        for i in range(n):
            for j in range(i + 1):
                C[i, j] = C_vec[idx]
                idx += 1
        
        # Extract A, B, D matrices
        A = params[C_size:C_size + A_size].reshape(n, n)
        B = params[C_size + A_size:C_size + A_size + B_size].reshape(n, n)
        D = params[C_size + A_size + B_size:].reshape(n, n)
        
        return C, A, B, D
    
    def _compute_covariance_matrices(self, params):
        """Compute conditional covariance matrices H_t for all time periods."""
        C, A, B, D = self._vec_to_matrices(params)
        
        # Compute C'C (intercept matrix)
        CC = C @ C.T
        
        # Initialize H_t array
        H_t = np.zeros((self.n_obs, self.n_assets, self.n_assets))
        
        # Initialize with unconditional covariance
        H_t[0] = np.cov(self.returns.T)
        
        # Iterate through time
        for t in range(1, self.n_obs):
            eps_prev = self.returns.iloc[t - 1].values.reshape(-1, 1)
            
            # Asymmetric term (negative shocks)
            eta_prev = eps_prev * (eps_prev < 0)
            
            # BEKK equation with asymmetric component
            H_t[t] = (CC + 
                     A.T @ (eps_prev @ eps_prev.T) @ A +
                     B.T @ H_t[t - 1] @ B +
                     D.T @ (eta_prev @ eta_prev.T) @ D)
            
            # Ensure positive definiteness
            eigenvalues = np.linalg.eigvals(H_t[t])
            if np.any(eigenvalues <= 0):
                H_t[t] = H_t[t] + np.eye(self.n_assets) * 1e-6
        
        return H_t
    
    def _log_likelihood(self, params):
        """Compute negative log-likelihood for optimization."""
        try:
            H_t = self._compute_covariance_matrices(params)
            
            log_likelihood = 0
            for t in range(self.n_obs):
                eps_t = self.returns.iloc[t].values
                H_inv = np.linalg.inv(H_t[t])
                
                # Log-likelihood contribution at time t
                log_det_H = np.log(np.linalg.det(H_t[t]))
                quad_form = eps_t @ H_inv @ eps_t
                
                log_likelihood += -0.5 * (log_det_H + quad_form)
            
            return -log_likelihood
        except:
            return 1e10
    
    def fit(self, method='BFGS', maxiter=1000):
        """
        Estimate the Asymmetric BEKK model parameters.
        
        Parameters:
        -----------
        method : str
            Optimization method (default: 'BFGS')
        maxiter : int
            Maximum number of iterations
        """
        print("Initializing Asymmetric BEKK model estimation...")
        print(f"Number of assets: {self.n_assets}")
        print(f"Number of observations: {self.n_obs}")
        
        # Initialize parameters
        initial_params = self._initialize_params()
        
        print("\nStarting optimization...")
        result = minimize(
            self._log_likelihood,
            initial_params,
            method=method,
            options={'maxiter': maxiter, 'disp': True}
        )
        
        if result.success:
            print("\nOptimization converged successfully!")
            self.params = result.x
            self.H_t = self._compute_covariance_matrices(self.params)
            return result
        else:
            print("\nWarning: Optimization did not converge")
            print(f"Message: {result.message}")
            # Still save the best parameters found
            self.params = result.x
            self.H_t = self._compute_covariance_matrices(self.params)
            return result
    
    def get_conditional_correlations(self):
        """Extract conditional correlations from conditional covariances."""
        if self.H_t is None:
            raise ValueError("Model must be fitted first")
        
        correlations = np.zeros_like(self.H_t)
        for t in range(self.n_obs):
            D_t = np.diag(np.sqrt(np.diag(self.H_t[t])))
            D_t_inv = np.linalg.inv(D_t)
            correlations[t] = D_t_inv @ self.H_t[t] @ D_t_inv
        
        return correlations
    
    def get_parameter_matrices(self):
        """
        Get the estimated parameter matrices.
        
        Returns:
        --------
        tuple
            (C, A, B, D) - The four parameter matrices:
            - C: Constant matrix (lower triangular)
            - A: Shock spillover matrix (ARCH effects)
            - B: Volatility persistence matrix (GARCH effects)
            - D: Asymmetric effects matrix (leverage effects)
        """
        if self.params is None:
            raise ValueError("Model must be fitted first")
        return self._vec_to_matrices(self.params)
    
    def get_volatility_spillovers(self):
        """Compute volatility spillover indices."""
        C, A, B, D = self._vec_to_matrices(self.params)
        
        spillover_info = {
            'A_matrix': A,
            'B_matrix': B,
            'D_matrix': D,
            'shock_spillovers': A,
            'volatility_persistence': B,
            'asymmetric_effects': D
        }
        
        return spillover_info


def fetch_market_data(start_date='2019-01-01', end_date=None):
    """
    Fetch historical price data for S&P 500, SSE, and TAIEX.
    
    Parameters:
    -----------
    start_date : str
        Start date in 'YYYY-MM-DD' format
    end_date : str
        End date in 'YYYY-MM-DD' format (default: today)
    
    Returns:
    --------
    pd.DataFrame
        DataFrame with adjusted close prices for all three indices
    """
    if end_date is None:
        end_date = datetime.now().strftime('%Y-%m-%d')
    
    print(f"Fetching market data from {start_date} to {end_date}...")
    
    # Ticker symbols
    tickers = {
        'SP500': '^GSPC',      # S&P 500
        'SSE': '000001.SS',    # SSE Composite Index
        'TAIEX': '^TWII'       # Taiwan Stock Exchange Capitalization Weighted Stock Index
    }
    
    # Fetch data
    data = pd.DataFrame()
    for name, ticker in tickers.items():
        print(f"Downloading {name} ({ticker})...")
        df = yf.download(ticker, start=start_date, end=end_date, progress=False)
        data[name] = df['Adj Close']
    
    # Remove any missing values
    data = data.dropna()
    print(f"\nData fetched successfully! Shape: {data.shape}")
    
    return data


def calculate_returns(prices, method='log'):
    """
    Calculate returns from price data.
    
    Parameters:
    -----------
    prices : pd.DataFrame
        DataFrame with price data
    method : str
        'log' for log returns or 'simple' for simple returns
    
    Returns:
    --------
    pd.DataFrame
        DataFrame with return series
    """
    if method == 'log':
        returns = np.log(prices / prices.shift(1))
    else:
        returns = prices.pct_change()
    
    returns = returns.dropna()
    print(f"\nReturns calculated using {method} method")
    print(f"Returns shape: {returns.shape}")
    print("\nReturns summary statistics:")
    print(returns.describe())
    
    return returns


def plot_results(returns, model, save_path=None):
    """
    Create visualizations of the results.
    
    Parameters:
    -----------
    returns : pd.DataFrame
        Return series
    model : AsymmetricBEKK
        Fitted BEKK model
    save_path : str
        Path to save plots (optional)
    """
    # Get conditional correlations
    correlations = model.get_conditional_correlations()
    
    # Create figure with subplots
    fig, axes = plt.subplots(3, 2, figsize=(15, 12))
    fig.suptitle('Asymmetric BEKK Model Results: S&P 500, SSE, and TAIEX', 
                 fontsize=16, fontweight='bold')
    
    # Plot returns
    for idx, col in enumerate(returns.columns):
        axes[idx, 0].plot(returns.index, returns[col], linewidth=0.5)
        axes[idx, 0].set_title(f'{col} Returns', fontweight='bold')
        axes[idx, 0].set_ylabel('Returns')
        axes[idx, 0].grid(True, alpha=0.3)
    
    # Plot conditional correlations
    asset_pairs = [
        (0, 1, 'SP500-SSE'),
        (0, 2, 'SP500-TAIEX'),
        (1, 2, 'SSE-TAIEX')
    ]
    
    for idx, (i, j, label) in enumerate(asset_pairs):
        corr_series = correlations[:, i, j]
        axes[idx, 1].plot(returns.index, corr_series, linewidth=1)
        axes[idx, 1].set_title(f'Conditional Correlation: {label}', fontweight='bold')
        axes[idx, 1].set_ylabel('Correlation')
        axes[idx, 1].axhline(y=0, color='r', linestyle='--', alpha=0.3)
        axes[idx, 1].grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        print(f"\nPlot saved to {save_path}")
    
    plt.show()
    
    return fig


def print_spillover_analysis(model, returns):
    """
    Print detailed spillover analysis results.
    
    Parameters:
    -----------
    model : AsymmetricBEKK
        Fitted BEKK model
    returns : pd.DataFrame
        Return series
    """
    spillovers = model.get_volatility_spillovers()
    asset_names = returns.columns.tolist()
    
    print("\n" + "="*70)
    print("VOLATILITY SPILLOVER ANALYSIS RESULTS")
    print("="*70)
    
    print("\n1. SHOCK SPILLOVER MATRIX (A):")
    print("-" * 70)
    A_df = pd.DataFrame(spillovers['A_matrix'], 
                       index=asset_names, 
                       columns=asset_names)
    print(A_df.round(4))
    print("\nInterpretation: Shows how shocks in one market affect volatility in others")
    
    print("\n2. VOLATILITY PERSISTENCE MATRIX (B):")
    print("-" * 70)
    B_df = pd.DataFrame(spillovers['B_matrix'], 
                       index=asset_names, 
                       columns=asset_names)
    print(B_df.round(4))
    print("\nInterpretation: Shows persistence of volatility over time")
    
    print("\n3. ASYMMETRIC EFFECTS MATRIX (D):")
    print("-" * 70)
    D_df = pd.DataFrame(spillovers['D_matrix'], 
                       index=asset_names, 
                       columns=asset_names)
    print(D_df.round(4))
    print("\nInterpretation: Shows leverage effects (negative shocks have different impact)")
    
    print("\n4. AVERAGE CONDITIONAL CORRELATIONS:")
    print("-" * 70)
    correlations = model.get_conditional_correlations()
    avg_corr = np.mean(correlations, axis=0)
    avg_corr_df = pd.DataFrame(avg_corr, 
                               index=asset_names, 
                               columns=asset_names)
    print(avg_corr_df.round(4))
    
    print("\n" + "="*70)


def main():
    """Main execution function."""
    print("="*70)
    print("ASYMMETRIC BEKK MODEL FOR VOLATILITY SPILLOVER ANALYSIS")
    print("Markets: S&P 500, SSE Composite, and TAIEX")
    print("="*70)
    
    # Fetch data
    prices = fetch_market_data(start_date='2019-01-01')
    
    # Calculate returns
    returns = calculate_returns(prices, method='log')
    
    # Scale returns by 100 for numerical stability
    returns = returns * 100
    
    # Initialize and fit Asymmetric BEKK model
    print("\n" + "="*70)
    print("FITTING ASYMMETRIC BEKK MODEL")
    print("="*70)
    
    model = AsymmetricBEKK(returns)
    result = model.fit(method='BFGS', maxiter=500)
    
    # Print results
    print_spillover_analysis(model, returns)
    
    # Create visualizations
    print("\nGenerating visualizations...")
    plot_results(returns, model, save_path='bekk_results.png')
    
    print("\n" + "="*70)
    print("ANALYSIS COMPLETE!")
    print("="*70)
    print("\nResults have been saved to 'bekk_results.png'")
    print("The analysis shows volatility spillovers between the three markets.")
    print("\nKey findings to examine:")
    print("1. Cross-market shock transmission (off-diagonal elements of A matrix)")
    print("2. Volatility persistence (B matrix)")
    print("3. Asymmetric/leverage effects (D matrix)")
    print("4. Time-varying conditional correlations")


if __name__ == "__main__":
    main()
