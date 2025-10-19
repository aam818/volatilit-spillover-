"""
Asymmetric BEKK-GARCH Model Implementation
Implements the asymmetric BEKK model for analyzing volatility spillovers
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.optimize import minimize


class AsymmetricBEKKGARCH:
    def __init__(self, returns_data):
        """
        Initialize Asymmetric BEKK-GARCH model
        
        Parameters:
        -----------
        returns_data : pd.DataFrame
            Returns data for US, China, and Taiwan indices
        """
        self.returns = returns_data.values
        self.returns_df = returns_data
        self.T, self.k = self.returns.shape
        self.params = None
        self.H_t = None
        self.loglikelihood = None
        
    def _initialize_parameters(self):
        """
        Initialize BEKK parameters
        """
        k = self.k
        
        # C matrix (lower triangular)
        C = np.eye(k) * 0.1
        C_lower = C[np.tril_indices(k)]
        
        # A matrix (impacts of lagged squared innovations)
        A = np.eye(k) * 0.1
        
        # B matrix (impacts of lagged conditional variance)
        B = np.eye(k) * 0.85
        
        # G matrix (asymmetric effects - leverage effects)
        G = np.eye(k) * 0.05
        
        # Combine all parameters
        params = np.concatenate([
            C_lower.flatten(),
            A.flatten(),
            B.flatten(),
            G.flatten()
        ])
        
        return params
    
    def _unpack_parameters(self, params):
        """
        Unpack parameter vector into matrices
        """
        k = self.k
        
        # Number of parameters for each component
        n_C = int(k * (k + 1) / 2)
        n_A = k * k
        n_B = k * k
        n_G = k * k
        
        # Extract parameters
        C_lower = params[:n_C]
        A_flat = params[n_C:n_C + n_A]
        B_flat = params[n_C + n_A:n_C + n_A + n_B]
        G_flat = params[n_C + n_A + n_B:n_C + n_A + n_B + n_G]
        
        # Reconstruct C matrix (lower triangular)
        C = np.zeros((k, k))
        C[np.tril_indices(k)] = C_lower
        
        # Reshape A, B, G matrices
        A = A_flat.reshape(k, k)
        B = B_flat.reshape(k, k)
        G = G_flat.reshape(k, k)
        
        return C, A, B, G
    
    def _compute_conditional_covariance(self, params):
        """
        Compute conditional covariance matrices
        
        Returns:
        --------
        H : numpy.ndarray
            Array of conditional covariance matrices (T x k x k)
        """
        C, A, B, G = self._unpack_parameters(params)
        
        # Initialize conditional covariance
        H = np.zeros((self.T, self.k, self.k))
        
        # Unconditional covariance as starting value
        H[0] = np.cov(self.returns.T)
        
        for t in range(1, self.T):
            # Previous innovations
            eps_t_1 = self.returns[t-1].reshape(-1, 1)
            
            # Negative innovations (for asymmetric effects)
            neg_eps_t_1 = np.minimum(eps_t_1, 0)
            
            # BEKK equation with asymmetry:
            # H_t = C'C + A'*eps_{t-1}*eps_{t-1}'*A + B'*H_{t-1}*B + G'*neg_eps_{t-1}*neg_eps_{t-1}'*G
            
            CC = C.T @ C
            AA = A.T @ (eps_t_1 @ eps_t_1.T) @ A
            BB = B.T @ H[t-1] @ B
            GG = G.T @ (neg_eps_t_1 @ neg_eps_t_1.T) @ G
            
            H[t] = CC + AA + BB + GG
            
            # Ensure positive definiteness
            try:
                np.linalg.cholesky(H[t])
            except np.linalg.LinAlgError:
                # If not positive definite, add small value to diagonal
                H[t] = H[t] + np.eye(self.k) * 1e-6
        
        return H
    
    def _log_likelihood(self, params):
        """
        Compute negative log-likelihood for optimization
        """
        try:
            H = self._compute_conditional_covariance(params)
            
            loglik = 0
            for t in range(self.T):
                eps_t = self.returns[t].reshape(-1, 1)
                H_t = H[t]
                
                # Ensure positive definiteness
                eigvals = np.linalg.eigvals(H_t)
                if np.any(eigvals <= 0):
                    return 1e10
                
                # Log likelihood contribution
                sign, logdet = np.linalg.slogdet(H_t)
                if sign <= 0:
                    return 1e10
                
                H_t_inv = np.linalg.inv(H_t)
                loglik += logdet + (eps_t.T @ H_t_inv @ eps_t)[0, 0]
            
            # Return negative log-likelihood for minimization
            return loglik / self.T
            
        except:
            return 1e10
    
    def fit(self, method='SLSQP', max_iter=1000):
        """
        Estimate BEKK model parameters using maximum likelihood
        
        Parameters:
        -----------
        method : str
            Optimization method
        max_iter : int
            Maximum number of iterations
        """
        print("\n" + "="*60)
        print("FITTING ASYMMETRIC BEKK-GARCH MODEL")
        print("="*60)
        
        # Initialize parameters
        params0 = self._initialize_parameters()
        
        print(f"\nOptimization started...")
        print(f"Number of parameters: {len(params0)}")
        print(f"Number of observations: {self.T}")
        print(f"Number of series: {self.k}")
        
        # Optimize
        result = minimize(
            self._log_likelihood,
            params0,
            method=method,
            options={'maxiter': max_iter, 'disp': True}
        )
        
        if result.success:
            print("\n✓ Optimization converged successfully!")
            self.params = result.x
            self.loglikelihood = -result.fun * self.T
            
            # Compute final conditional covariances
            self.H_t = self._compute_conditional_covariance(self.params)
            
            print(f"\nLog-likelihood: {self.loglikelihood:.2f}")
            
        else:
            print("\n✗ Optimization did not converge!")
            print(f"Message: {result.message}")
            # Still use the result even if not fully converged
            self.params = result.x
            self.H_t = self._compute_conditional_covariance(self.params)
            
    def analyze_spillovers(self):
        """
        Analyze volatility spillovers from estimated model
        """
        print("\n" + "="*60)
        print("ANALYZING VOLATILITY SPILLOVERS")
        print("="*60)
        
        if self.params is None:
            print("Model not fitted yet!")
            return
        
        C, A, B, G = self._unpack_parameters(self.params)
        
        print("\n1. Parameter Matrices:")
        print("\nC Matrix (Constant):")
        print(pd.DataFrame(C, 
                          index=self.returns_df.columns, 
                          columns=self.returns_df.columns))
        
        print("\nA Matrix (ARCH effects):")
        print(pd.DataFrame(A, 
                          index=self.returns_df.columns, 
                          columns=self.returns_df.columns))
        
        print("\nB Matrix (GARCH effects):")
        print(pd.DataFrame(B, 
                          index=self.returns_df.columns, 
                          columns=self.returns_df.columns))
        
        print("\nG Matrix (Asymmetric/Leverage effects):")
        print(pd.DataFrame(G, 
                          index=self.returns_df.columns, 
                          columns=self.returns_df.columns))
        
        # Analyze spillover effects
        print("\n2. Spillover Analysis:")
        print("\nOff-diagonal elements indicate spillover effects:")
        
        # From US to others
        print(f"\nUS → China (ARCH): {A[1, 0]:.6f}")
        print(f"US → Taiwan (ARCH): {A[2, 0]:.6f}")
        print(f"US → China (Asymmetric): {G[1, 0]:.6f}")
        print(f"US → Taiwan (Asymmetric): {G[2, 0]:.6f}")
        
        # From China to others
        print(f"\nChina → US (ARCH): {A[0, 1]:.6f}")
        print(f"China → Taiwan (ARCH): {A[2, 1]:.6f}")
        print(f"China → US (Asymmetric): {G[0, 1]:.6f}")
        print(f"China → Taiwan (Asymmetric): {G[2, 1]:.6f}")
        
        # From Taiwan to others
        print(f"\nTaiwan → US (ARCH): {A[0, 2]:.6f}")
        print(f"Taiwan → China (ARCH): {A[1, 2]:.6f}")
        print(f"Taiwan → US (Asymmetric): {G[0, 2]:.6f}")
        print(f"Taiwan → China (Asymmetric): {G[1, 2]:.6f}")
        
        # Extract time-varying correlations
        correlations = self._extract_correlations()
        
        print("\n3. Time-Varying Correlation Statistics:")
        print(correlations.describe())
        
        return correlations
    
    def _extract_correlations(self):
        """
        Extract time-varying correlations from conditional covariances
        """
        T = self.H_t.shape[0]
        correlations = {
            'US-China': np.zeros(T),
            'US-Taiwan': np.zeros(T),
            'China-Taiwan': np.zeros(T)
        }
        
        for t in range(T):
            H = self.H_t[t]
            # Convert covariance to correlation
            D = np.diag(np.sqrt(np.diag(H)))
            D_inv = np.linalg.inv(D)
            R = D_inv @ H @ D_inv
            
            correlations['US-China'][t] = R[0, 1]
            correlations['US-Taiwan'][t] = R[0, 2]
            correlations['China-Taiwan'][t] = R[1, 2]
        
        return pd.DataFrame(correlations, index=self.returns_df.index)
    
    def plot_results(self, output_prefix='bekk_garch'):
        """
        Plot model results
        """
        print("\n" + "="*60)
        print("GENERATING PLOTS")
        print("="*60)
        
        # Extract conditional volatilities
        volatilities = pd.DataFrame(
            {col: np.sqrt(self.H_t[:, i, i]) for i, col in enumerate(self.returns_df.columns)},
            index=self.returns_df.index
        )
        
        # Plot 1: Conditional Volatilities
        fig, axes = plt.subplots(3, 1, figsize=(14, 10))
        
        for i, col in enumerate(self.returns_df.columns):
            axes[i].plot(volatilities.index, volatilities[col], 
                        label=f'{col} Volatility', linewidth=1)
            axes[i].set_title(f'{col} Conditional Volatility (Asymmetric BEKK-GARCH)', fontsize=12)
            axes[i].set_ylabel('Volatility (%)')
            axes[i].legend()
            axes[i].grid(True, alpha=0.3)
        
        axes[-1].set_xlabel('Date')
        plt.tight_layout()
        plt.savefig(f'{output_prefix}_volatility.png', dpi=300, bbox_inches='tight')
        print(f"Saved: {output_prefix}_volatility.png")
        plt.close()
        
        # Plot 2: Dynamic Conditional Correlations
        correlations = self._extract_correlations()
        
        fig, ax = plt.subplots(figsize=(14, 6))
        
        for col in correlations.columns:
            ax.plot(correlations.index, correlations[col], label=col, linewidth=1.5)
        
        ax.set_title('Dynamic Conditional Correlations (Asymmetric BEKK-GARCH)', 
                    fontsize=14, fontweight='bold')
        ax.set_xlabel('Date')
        ax.set_ylabel('Correlation')
        ax.legend(loc='best')
        ax.grid(True, alpha=0.3)
        ax.axhline(y=0, color='black', linestyle='--', linewidth=0.8)
        
        plt.tight_layout()
        plt.savefig(f'{output_prefix}_correlations.png', dpi=300, bbox_inches='tight')
        print(f"Saved: {output_prefix}_correlations.png")
        plt.close()
        
        # Plot 3: Parameter matrices heatmap
        C, A, B, G = self._unpack_parameters(self.params)
        
        fig, axes = plt.subplots(2, 2, figsize=(14, 12))
        
        # A matrix
        sns.heatmap(A, annot=True, fmt='.4f', cmap='RdBu_r', center=0,
                   xticklabels=self.returns_df.columns,
                   yticklabels=self.returns_df.columns,
                   ax=axes[0, 0])
        axes[0, 0].set_title('A Matrix (ARCH Effects)', fontweight='bold')
        
        # B matrix
        sns.heatmap(B, annot=True, fmt='.4f', cmap='RdBu_r', center=0,
                   xticklabels=self.returns_df.columns,
                   yticklabels=self.returns_df.columns,
                   ax=axes[0, 1])
        axes[0, 1].set_title('B Matrix (GARCH Effects)', fontweight='bold')
        
        # G matrix
        sns.heatmap(G, annot=True, fmt='.4f', cmap='RdBu_r', center=0,
                   xticklabels=self.returns_df.columns,
                   yticklabels=self.returns_df.columns,
                   ax=axes[1, 0])
        axes[1, 0].set_title('G Matrix (Asymmetric Effects)', fontweight='bold')
        
        # Average correlation matrix
        avg_corr = np.mean([self.H_t[t] / np.outer(np.sqrt(np.diag(self.H_t[t])), 
                                                    np.sqrt(np.diag(self.H_t[t]))) 
                           for t in range(self.T)], axis=0)
        sns.heatmap(avg_corr, annot=True, fmt='.4f', cmap='RdYlBu_r', center=0,
                   xticklabels=self.returns_df.columns,
                   yticklabels=self.returns_df.columns,
                   ax=axes[1, 1])
        axes[1, 1].set_title('Average Conditional Correlation', fontweight='bold')
        
        plt.tight_layout()
        plt.savefig(f'{output_prefix}_parameters.png', dpi=300, bbox_inches='tight')
        print(f"Saved: {output_prefix}_parameters.png")
        plt.close()
        
    def save_results(self, output_prefix='bekk_garch'):
        """
        Save results to files
        """
        # Save conditional volatilities
        volatilities = pd.DataFrame(
            {col: np.sqrt(self.H_t[:, i, i]) for i, col in enumerate(self.returns_df.columns)},
            index=self.returns_df.index
        )
        volatilities.to_csv(f'{output_prefix}_volatility.csv')
        print(f"\nSaved: {output_prefix}_volatility.csv")
        
        # Save correlations
        correlations = self._extract_correlations()
        correlations.to_csv(f'{output_prefix}_correlations.csv')
        print(f"Saved: {output_prefix}_correlations.csv")
        
        # Save parameters
        C, A, B, G = self._unpack_parameters(self.params)
        
        with open(f'{output_prefix}_parameters.txt', 'w') as f:
            f.write("="*60 + "\n")
            f.write("ASYMMETRIC BEKK-GARCH MODEL PARAMETERS\n")
            f.write("="*60 + "\n\n")
            
            f.write("C Matrix (Constant):\n")
            f.write(str(pd.DataFrame(C, 
                                    index=self.returns_df.columns,
                                    columns=self.returns_df.columns)) + "\n\n")
            
            f.write("A Matrix (ARCH Effects):\n")
            f.write(str(pd.DataFrame(A, 
                                    index=self.returns_df.columns,
                                    columns=self.returns_df.columns)) + "\n\n")
            
            f.write("B Matrix (GARCH Effects):\n")
            f.write(str(pd.DataFrame(B, 
                                    index=self.returns_df.columns,
                                    columns=self.returns_df.columns)) + "\n\n")
            
            f.write("G Matrix (Asymmetric/Leverage Effects):\n")
            f.write(str(pd.DataFrame(G, 
                                    index=self.returns_df.columns,
                                    columns=self.returns_df.columns)) + "\n\n")
            
            f.write(f"Log-likelihood: {self.loglikelihood}\n")
        
        print(f"Saved: {output_prefix}_parameters.txt")


if __name__ == "__main__":
    # Example usage
    returns = pd.read_csv('returns.csv', index_col=0, parse_dates=True)
    
    model = AsymmetricBEKKGARCH(returns)
    model.fit(max_iter=100)  # Reduced iterations for faster computation
    correlations = model.analyze_spillovers()
    model.plot_results()
    model.save_results()
