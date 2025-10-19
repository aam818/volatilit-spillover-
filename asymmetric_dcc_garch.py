"""
Asymmetric DCC-GARCH Model Implementation
Uses GJR-GARCH (asymmetric GARCH) for univariate volatility modeling
and DCC for dynamic conditional correlations
"""

import pandas as pd
import numpy as np
from arch import arch_model
from arch.univariate import GARCH, GJR, ConstantMean, Normal
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats


class AsymmetricDCCGARCH:
    def __init__(self, returns_data):
        """
        Initialize Asymmetric DCC-GARCH model
        
        Parameters:
        -----------
        returns_data : pd.DataFrame
            Returns data for US, China, and Taiwan indices
        """
        self.returns = returns_data
        self.univariate_models = {}
        self.standardized_residuals = pd.DataFrame()
        self.conditional_volatility = pd.DataFrame()
        self.dcc_results = {}
        
    def fit_univariate_models(self, p=1, o=1, q=1):
        """
        Fit GJR-GARCH(p,o,q) models for each series
        
        Parameters:
        -----------
        p : int
            GARCH order
        o : int
            Asymmetry order (for GJR-GARCH)
        q : int
            ARCH order
        """
        print("\n" + "="*60)
        print("STEP 1: Fitting Univariate GJR-GARCH Models")
        print("="*60)
        
        for col in self.returns.columns:
            print(f"\nFitting GJR-GARCH({p},{o},{q}) for {col}...")
            
            # Create GJR-GARCH model (asymmetric GARCH)
            model = arch_model(
                self.returns[col], 
                vol='Garch', 
                p=p, 
                o=o, 
                q=q,
                dist='normal'
            )
            
            # Fit model
            res = model.fit(disp='off')
            self.univariate_models[col] = res
            
            # Store standardized residuals
            self.standardized_residuals[col] = res.resid / res.conditional_volatility
            
            # Store conditional volatility
            self.conditional_volatility[col] = res.conditional_volatility
            
            # Print results
            print(f"\nResults for {col}:")
            print(res.summary())
            
        print("\nUnivariatesGARCH models fitted successfully!")
        
    def estimate_dcc(self):
        """
        Estimate DCC parameters using standardized residuals
        """
        print("\n" + "="*60)
        print("STEP 2: Estimating DCC Parameters")
        print("="*60)
        
        # Get standardized residuals
        resid = self.standardized_residuals.values
        T, k = resid.shape
        
        # Calculate unconditional correlation matrix
        R_bar = np.corrcoef(resid.T)
        print(f"\nUnconditional Correlation Matrix:")
        print(pd.DataFrame(R_bar, 
                          index=self.returns.columns, 
                          columns=self.returns.columns))
        
        # Initialize DCC parameters (simple estimation)
        # In practice, these should be estimated via MLE
        alpha_dcc = 0.01
        beta_dcc = 0.95
        
        print(f"\nDCC Parameters (initial estimates):")
        print(f"alpha: {alpha_dcc}")
        print(f"beta: {beta_dcc}")
        
        # Calculate dynamic conditional correlations
        Q = np.zeros((T, k, k))
        R = np.zeros((T, k, k))
        
        # Initialize Q with unconditional correlation
        Q[0] = R_bar
        
        for t in range(1, T):
            # DCC equation: Q_t = (1-alpha-beta)*R_bar + alpha*eps_{t-1}*eps_{t-1}' + beta*Q_{t-1}
            eps_outer = np.outer(resid[t-1], resid[t-1])
            Q[t] = (1 - alpha_dcc - beta_dcc) * R_bar + alpha_dcc * eps_outer + beta_dcc * Q[t-1]
            
            # Normalize to get correlation matrix
            Q_diag_inv_sqrt = np.diag(1.0 / np.sqrt(np.diag(Q[t])))
            R[t] = Q_diag_inv_sqrt @ Q[t] @ Q_diag_inv_sqrt
        
        self.dcc_results['Q'] = Q
        self.dcc_results['R'] = R
        self.dcc_results['R_bar'] = R_bar
        self.dcc_results['alpha'] = alpha_dcc
        self.dcc_results['beta'] = beta_dcc
        
        print("\nDCC estimation completed!")
        
    def analyze_spillovers(self):
        """
        Analyze volatility spillovers between markets
        """
        print("\n" + "="*60)
        print("STEP 3: Analyzing Volatility Spillovers")
        print("="*60)
        
        R = self.dcc_results['R']
        
        # Extract time-varying correlations
        correlations = {
            'US-China': R[:, 0, 1],
            'US-Taiwan': R[:, 0, 2],
            'China-Taiwan': R[:, 1, 2]
        }
        
        corr_df = pd.DataFrame(correlations, index=self.returns.index)
        
        print("\nTime-Varying Correlation Statistics:")
        print(corr_df.describe())
        
        # Calculate average correlations
        print("\n\nAverage Dynamic Conditional Correlations:")
        for pair, values in correlations.items():
            print(f"{pair}: {np.mean(values):.4f}")
        
        # Identify spillover periods (high correlation periods)
        print("\n\nSpillover Analysis:")
        for pair, values in correlations.items():
            high_corr_threshold = np.mean(values) + np.std(values)
            high_corr_periods = np.sum(values > high_corr_threshold)
            pct_high_corr = (high_corr_periods / len(values)) * 100
            print(f"{pair}:")
            print(f"  High correlation periods: {high_corr_periods} ({pct_high_corr:.2f}%)")
            print(f"  Threshold: {high_corr_threshold:.4f}")
        
        return corr_df
    
    def plot_results(self, output_prefix='dcc_garch'):
        """
        Plot model results
        """
        print("\n" + "="*60)
        print("STEP 4: Generating Plots")
        print("="*60)
        
        # Plot 1: Conditional Volatilities
        fig, axes = plt.subplots(3, 1, figsize=(14, 10))
        
        for i, col in enumerate(self.returns.columns):
            axes[i].plot(self.conditional_volatility.index, 
                        self.conditional_volatility[col], 
                        label=f'{col} Volatility', 
                        linewidth=1)
            axes[i].set_title(f'{col} Conditional Volatility (GJR-GARCH)', fontsize=12)
            axes[i].set_ylabel('Volatility (%)')
            axes[i].legend()
            axes[i].grid(True, alpha=0.3)
        
        axes[-1].set_xlabel('Date')
        plt.tight_layout()
        plt.savefig(f'{output_prefix}_volatility.png', dpi=300, bbox_inches='tight')
        print(f"Saved: {output_prefix}_volatility.png")
        plt.close()
        
        # Plot 2: Dynamic Conditional Correlations
        R = self.dcc_results['R']
        correlations = {
            'US-China': R[:, 0, 1],
            'US-Taiwan': R[:, 0, 2],
            'China-Taiwan': R[:, 1, 2]
        }
        
        fig, ax = plt.subplots(figsize=(14, 6))
        
        for pair, values in correlations.items():
            ax.plot(self.returns.index, values, label=pair, linewidth=1.5)
        
        ax.set_title('Dynamic Conditional Correlations (DCC-GARCH)', fontsize=14, fontweight='bold')
        ax.set_xlabel('Date')
        ax.set_ylabel('Correlation')
        ax.legend(loc='best')
        ax.grid(True, alpha=0.3)
        ax.axhline(y=0, color='black', linestyle='--', linewidth=0.8)
        
        plt.tight_layout()
        plt.savefig(f'{output_prefix}_correlations.png', dpi=300, bbox_inches='tight')
        print(f"Saved: {output_prefix}_correlations.png")
        plt.close()
        
        # Plot 3: Correlation Heatmap (average)
        avg_corr_matrix = np.mean(self.dcc_results['R'], axis=0)
        
        fig, ax = plt.subplots(figsize=(8, 6))
        sns.heatmap(avg_corr_matrix, 
                   annot=True, 
                   fmt='.4f',
                   cmap='RdYlBu_r', 
                   center=0,
                   xticklabels=self.returns.columns,
                   yticklabels=self.returns.columns,
                   cbar_kws={'label': 'Correlation'},
                   ax=ax)
        ax.set_title('Average Dynamic Conditional Correlation Matrix', fontsize=14, fontweight='bold')
        plt.tight_layout()
        plt.savefig(f'{output_prefix}_heatmap.png', dpi=300, bbox_inches='tight')
        print(f"Saved: {output_prefix}_heatmap.png")
        plt.close()
        
    def save_results(self, output_prefix='dcc_garch'):
        """
        Save results to CSV files
        """
        # Save conditional volatilities
        self.conditional_volatility.to_csv(f'{output_prefix}_volatility.csv')
        print(f"\nSaved: {output_prefix}_volatility.csv")
        
        # Save dynamic correlations
        R = self.dcc_results['R']
        correlations = pd.DataFrame({
            'US-China': R[:, 0, 1],
            'US-Taiwan': R[:, 0, 2],
            'China-Taiwan': R[:, 1, 2]
        }, index=self.returns.index)
        correlations.to_csv(f'{output_prefix}_correlations.csv')
        print(f"Saved: {output_prefix}_correlations.csv")
        
        # Save model parameters
        with open(f'{output_prefix}_parameters.txt', 'w') as f:
            f.write("="*60 + "\n")
            f.write("ASYMMETRIC DCC-GARCH MODEL PARAMETERS\n")
            f.write("="*60 + "\n\n")
            
            for col, model in self.univariate_models.items():
                f.write(f"\n{col} - GJR-GARCH Parameters:\n")
                f.write(str(model.summary()) + "\n")
                f.write("\n" + "-"*60 + "\n")
            
            f.write(f"\nDCC Parameters:\n")
            f.write(f"alpha: {self.dcc_results['alpha']}\n")
            f.write(f"beta: {self.dcc_results['beta']}\n")
            f.write(f"\nUnconditional Correlation Matrix:\n")
            f.write(str(pd.DataFrame(self.dcc_results['R_bar'], 
                                    index=self.returns.columns,
                                    columns=self.returns.columns)))
        
        print(f"Saved: {output_prefix}_parameters.txt")


if __name__ == "__main__":
    # Example usage
    returns = pd.read_csv('returns.csv', index_col=0, parse_dates=True)
    
    model = AsymmetricDCCGARCH(returns)
    model.fit_univariate_models(p=1, o=1, q=1)
    model.estimate_dcc()
    correlations = model.analyze_spillovers()
    model.plot_results()
    model.save_results()
