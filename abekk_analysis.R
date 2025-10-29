# =============================================================================
# ASYMMETRIC BEKK MODEL ANALYSIS
# Volatility Spillovers: US, China, Taiwan Tech Sector
# =============================================================================

# Load required packages
required_packages <- c("BEKKs", "xtable", "knitr", "ggplot2", "reshape2", "gridExtra")

# Install missing packages
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

# Load packages
library(BEKKs)      # BEKK estimation
library(xtable)     # LaTeX table generation
library(knitr)      # Report generation
library(ggplot2)    # Visualization
library(reshape2)   # Data manipulation
library(gridExtra)  # Multiple plots

# Set options for output
options(digits = 4)
options(scipen = 999)

# =============================================================================
# DATA VALIDATION
# =============================================================================

if (!exists("returns")) {
  stop("Error: 'returns' object not found in workspace. Please load your data first.")
}

# Convert returns to matrix format
returns_matrix <- as.matrix(returns)

# Get market names from column names
market_names <- colnames(returns_matrix)
if (is.null(market_names)) {
  market_names <- paste0("Market", 1:ncol(returns_matrix))
  colnames(returns_matrix) <- market_names
}

n_markets <- ncol(returns_matrix)

cat("\n================================\n")
cat("ABEKK Model Estimation\n")
cat("================================\n")
cat(sprintf("Number of markets: %d\n", n_markets))
cat(sprintf("Market names: %s\n", paste(market_names, collapse=", ")))
cat(sprintf("Sample size: %d observations\n", nrow(returns_matrix)))
cat("================================\n\n")

# =============================================================================
# DESCRIPTIVE STATISTICS
# =============================================================================

cat("Descriptive Statistics:\n")
desc_stats <- data.frame(
  Market = market_names,
  Mean = apply(returns_matrix, 2, mean, na.rm=TRUE),
  SD = apply(returns_matrix, 2, sd, na.rm=TRUE),
  Min = apply(returns_matrix, 2, min, na.rm=TRUE),
  Max = apply(returns_matrix, 2, max, na.rm=TRUE),
  Skewness = apply(returns_matrix, 2, function(x) {
    n <- length(x)
    m3 <- mean((x - mean(x))^3)
    s3 <- sd(x)^3
    return(m3/s3)
  }),
  Kurtosis = apply(returns_matrix, 2, function(x) {
    n <- length(x)
    m4 <- mean((x - mean(x))^4)
    s4 <- sd(x)^4
    return(m4/s4 - 3)  # Excess kurtosis
  })
)
print(desc_stats)
cat("\n")

# =============================================================================
# MODEL SPECIFICATION
# =============================================================================

cat("Specifying Asymmetric BEKK(1,1,1) Model...\n")
asymmetric_bekk_spec <- bekk_spec(
  model = list(
    type = "bekk",        # Full BEKK specification
    asymmetric = TRUE     # Enable asymmetric effects (leverage)
  ),
  signs = rep(-1, n_markets),  # Negative shocks increase volatility
  init_values = NULL      # Use default starting values
)

cat("Model specification complete.\n")
cat(sprintf("Model type: Asymmetric BEKK(1,1,1)\n"))
cat(sprintf("Asymmetric signs: %s\n", paste(rep(-1, n_markets), collapse=", ")))
cat("\n")

# =============================================================================
# MODEL ESTIMATION
# =============================================================================

cat("Estimating Asymmetric BEKK model...\n")
cat("This may take several minutes depending on sample size...\n\n")

# Estimate the model
asymmetric_bekk_fit <- bekk_fit(
  spec = asymmetric_bekk_spec,
  data = returns_matrix,
  QML_t_ratios = TRUE,    # Calculate exact t-ratios using second derivatives
  max_iter = 100,         # Maximum iterations for optimization
  crit = 1e-9             # Convergence criterion
)

# Check convergence and print summary
cat(sprintf("Log-likelihood: %.4f\n", asymmetric_bekk_fit$log_likelihood))
cat(sprintf("AIC: %.4f\n", asymmetric_bekk_fit$AIC))
cat(sprintf("BIC: %.4f\n\n", asymmetric_bekk_fit$BIC))

# =============================================================================
# PARAMETER EXTRACTION (CORRECTED)
# =============================================================================

cat("Extracting parameter estimates...\n")

# The BEKKs package stores parameters directly in the fit object
# Access them correctly based on the package structure
if (!is.null(asymmetric_bekk_fit$theta)) {
  # Parameters are stored in theta vector - need to reconstruct matrices
  theta <- asymmetric_bekk_fit$theta

  # For a 3-market ABEKK model, parameters are organized as:
  # C (lower triangular), A (full matrix), B (full matrix), G (full matrix)

  # Calculate number of parameters for each matrix
  n_C <- n_markets * (n_markets + 1) / 2  # Lower triangular
  n_A <- n_markets * n_markets
  n_B <- n_markets * n_markets
  n_G <- n_markets * n_markets

  # Extract C matrix (lower triangular Cholesky factor)
  C_matrix <- matrix(0, n_markets, n_markets)
  idx <- 1
  for (j in 1:n_markets) {
    for (i in j:n_markets) {
      C_matrix[i, j] <- theta[idx]
      idx <- idx + 1
    }
  }

  # Extract A matrix (ARCH effects)
  A_matrix <- matrix(theta[idx:(idx + n_A - 1)], n_markets, n_markets, byrow = TRUE)
  idx <- idx + n_A

  # Extract B matrix (Asymmetric/leverage effects)
  B_matrix <- matrix(theta[idx:(idx + n_B - 1)], n_markets, n_markets, byrow = TRUE)
  idx <- idx + n_B

  # Extract G matrix (GARCH effects)
  G_matrix <- matrix(theta[idx:(idx + n_G - 1)], n_markets, n_markets, byrow = TRUE)

} else {
  stop("Could not extract parameters from model fit. Check BEKKs package version and documentation.")
}

# Add dimension names
rownames(C_matrix) <- colnames(C_matrix) <- market_names
rownames(A_matrix) <- colnames(A_matrix) <- market_names
rownames(B_matrix) <- colnames(B_matrix) <- market_names
rownames(G_matrix) <- colnames(G_matrix) <- market_names

cat("Parameter extraction complete.\n\n")

# =============================================================================
# DISPLAY PARAMETER ESTIMATES
# =============================================================================

cat("\n================================\n")
cat("PARAMETER ESTIMATES\n")
cat("================================\n\n")

cat("Constant Matrix (C):\n")
cat("(Lower triangular Cholesky factor of unconditional covariance)\n")
print(round(C_matrix, 4))
cat("\n")

cat("ARCH Matrix (A):\n")
cat("(Short-run shock spillovers)\n")
cat("A[i,j] measures shock spillover from market j to market i\n")
print(round(A_matrix, 4))
cat("\n")

cat("Asymmetric Matrix (B):\n")
cat("(Negative shock spillovers / Leverage effects)\n")
cat("B[i,j] measures asymmetric spillover from market j to market i\n")
print(round(B_matrix, 4))
cat("\n")

cat("GARCH Matrix (G):\n")
cat("(Long-run volatility persistence and spillovers)\n")
cat("G[i,j] measures volatility spillover from market j to market i\n")
print(round(G_matrix, 4))
cat("\n")

# =============================================================================
# STATISTICAL SIGNIFICANCE
# =============================================================================

cat("================================\n")
cat("STATISTICAL SIGNIFICANCE\n")
cat("================================\n\n")

# Extract t-ratios if available
if (!is.null(asymmetric_bekk_fit$se)) {
  cat("Standard Errors Available\n")
  se <- asymmetric_bekk_fit$se
  t_ratios <- theta / se

  cat(sprintf("Number of significant parameters at 5%% level: %d of %d\n",
              sum(abs(t_ratios) > 1.96), length(t_ratios)))
  cat(sprintf("Number of significant parameters at 1%% level: %d of %d\n\n",
              sum(abs(t_ratios) > 2.58), length(t_ratios)))
} else {
  cat("Standard errors not available in model output.\n\n")
}

# =============================================================================
# VOLATILITY SPILLOVER ANALYSIS
# =============================================================================

cat("================================\n")
cat("VOLATILITY SPILLOVER ANALYSIS\n")
cat("================================\n\n")

# Calculate total spillover effects
spillover_matrix <- abs(A_matrix) + abs(B_matrix) + abs(G_matrix)
diag(spillover_matrix) <- 0  # Remove own effects

cat("Total Spillover Matrix:\n")
cat("(Sum of absolute values: |A| + |B| + |G|)\n")
print(round(spillover_matrix, 4))
cat("\n")

# Directional spillovers
spillover_to <- rowSums(spillover_matrix)   # Spillovers TO each market
spillover_from <- colSums(spillover_matrix) # Spillovers FROM each market
net_spillover <- spillover_from - spillover_to  # Net spillover

spillover_summary <- data.frame(
  Market = market_names,
  Spillover_TO = round(spillover_to, 4),
  Spillover_FROM = round(spillover_from, 4),
  Net_Spillover = round(net_spillover, 4)
)

cat("Directional Spillover Summary:\n")
print(spillover_summary)
cat("\n")

# Identify spillover direction
for (i in 1:n_markets) {
  if (net_spillover[i] > 0) {
    cat(sprintf("%s is a NET TRANSMITTER of volatility (%.4f)\n",
                market_names[i], net_spillover[i]))
  } else if (net_spillover[i] < 0) {
    cat(sprintf("%s is a NET RECEIVER of volatility (%.4f)\n",
                market_names[i], net_spillover[i]))
  } else {
    cat(sprintf("%s has BALANCED spillovers\n", market_names[i]))
  }
}
cat("\n")

# Pairwise spillover analysis
cat("Pairwise Spillover Analysis:\n")
for (i in 1:(n_markets-1)) {
  for (j in (i+1):n_markets) {
    spill_ij <- spillover_matrix[i,j]  # From j to i
    spill_ji <- spillover_matrix[j,i]  # From i to j
    cat(sprintf("%s <-> %s: %.4f (TO %s) vs %.4f (TO %s)\n",
                market_names[i], market_names[j],
                spill_ji, market_names[j],
                spill_ij, market_names[i]))
  }
}
cat("\n")

# =============================================================================
# ASYMMETRIC (LEVERAGE) EFFECTS
# =============================================================================

cat("================================\n")
cat("ASYMMETRIC (LEVERAGE) EFFECTS\n")
cat("================================\n\n")

# Compare symmetric (A) vs asymmetric (B) effects
asymmetric_ratio <- abs(B_matrix) / (abs(A_matrix) + 1e-10)  # Avoid division by zero
diag(asymmetric_ratio) <- NA  # Remove diagonal

cat("Asymmetric-to-Symmetric Ratio (|B|/|A|):\n")
cat("(Values > 1 indicate stronger asymmetric effects)\n")
print(round(asymmetric_ratio, 4))
cat("\n")

# Diagonal elements show own-market leverage effects
cat("Own-market leverage effects:\n")
cat("(Diagonal elements of B matrix)\n")
for (i in 1:n_markets) {
  cat(sprintf("%s: %.4f\n", market_names[i], B_matrix[i,i]))
}
cat("\n")

# =============================================================================
# MODEL DIAGNOSTICS
# =============================================================================

cat("================================\n")
cat("MODEL DIAGNOSTICS\n")
cat("================================\n\n")

# Extract standardized residuals if available
if (!is.null(asymmetric_bekk_fit$std_resid)) {
  std_resid <- asymmetric_bekk_fit$std_resid

  cat("Standardized Residuals Statistics:\n")
  resid_stats <- data.frame(
    Market = market_names,
    Mean = apply(std_resid, 2, mean, na.rm=TRUE),
    SD = apply(std_resid, 2, sd, na.rm=TRUE),
    Skewness = apply(std_resid, 2, function(x) {
      m3 <- mean((x - mean(x))^3)
      s3 <- sd(x)^3
      return(m3/s3)
    }),
    Kurtosis = apply(std_resid, 2, function(x) {
      m4 <- mean((x - mean(x))^4)
      s4 <- sd(x)^4
      return(m4/s4 - 3)
    })
  )
  print(resid_stats)
  cat("\n")
} else {
  cat("Standardized residuals not available in model output.\n\n")
}

# Information criteria
cat("Information Criteria:\n")
cat(sprintf("Log-Likelihood: %.4f\n", asymmetric_bekk_fit$log_likelihood))
cat(sprintf("AIC: %.4f\n", asymmetric_bekk_fit$AIC))
cat(sprintf("BIC: %.4f\n", asymmetric_bekk_fit$BIC))
cat("\n")

# =============================================================================
# GENERATE OUTPUT DIRECTORY
# =============================================================================

# Create output directory if it doesn't exist
if (!dir.exists("output")) {
  dir.create("output")
  cat("Created output directory\n\n")
}

# =============================================================================
# LATEX TABLES GENERATION
# =============================================================================

cat("================================\n")
cat("GENERATING LATEX TABLES\n")
cat("================================\n\n")

# Function to create LaTeX table for a matrix
create_latex_matrix <- function(mat, caption, label, digits = 4) {
  mat_rounded <- round(mat, digits)
  xtab <- xtable(mat_rounded,
                 caption = caption,
                 label = label,
                 align = c("l", rep("r", ncol(mat))))
  return(xtab)
}

# Generate LaTeX tables for each parameter matrix
latex_C <- create_latex_matrix(C_matrix,
                               "Constant Matrix (C) - ABEKK Model",
                               "tab:bekk_C")

latex_A <- create_latex_matrix(A_matrix,
                               "ARCH Matrix (A) - Short-run Shock Spillovers",
                               "tab:bekk_A")

latex_B <- create_latex_matrix(B_matrix,
                               "Asymmetric Matrix (B) - Leverage Effects",
                               "tab:bekk_B")

latex_G <- create_latex_matrix(G_matrix,
                               "GARCH Matrix (G) - Long-run Volatility Spillovers",
                               "tab:bekk_G")

latex_spillover <- create_latex_matrix(spillover_matrix,
                                       "Total Volatility Spillover Matrix",
                                       "tab:bekk_spillover")

# Create summary statistics table
summary_table <- data.frame(
  Statistic = c("Log-Likelihood", "AIC", "BIC", "Observations", "Parameters"),
  Value = c(asymmetric_bekk_fit$log_likelihood,
            asymmetric_bekk_fit$AIC,
            asymmetric_bekk_fit$BIC,
            nrow(returns_matrix),
            length(theta))
)

latex_summary <- xtable(summary_table,
                        caption = "ABEKK Model Summary Statistics",
                        label = "tab:bekk_summary",
                        align = c("l", "l", "r"),
                        digits = c(0, 0, 4))

# Save LaTeX tables to files
cat("Saving LaTeX tables to files...\n")

print(latex_C, file = "output/table_C_matrix.tex",
      include.rownames = TRUE, include.colnames = TRUE,
      caption.placement = "top", booktabs = TRUE)

print(latex_A, file = "output/table_A_matrix.tex",
      include.rownames = TRUE, include.colnames = TRUE,
      caption.placement = "top", booktabs = TRUE)

print(latex_B, file = "output/table_B_matrix.tex",
      include.rownames = TRUE, include.colnames = TRUE,
      caption.placement = "top", booktabs = TRUE)

print(latex_G, file = "output/table_G_matrix.tex",
      include.rownames = TRUE, include.colnames = TRUE,
      caption.placement = "top", booktabs = TRUE)

print(latex_spillover, file = "output/table_spillover.tex",
      include.rownames = TRUE, include.colnames = TRUE,
      caption.placement = "top", booktabs = TRUE)

print(latex_summary, file = "output/table_summary.tex",
      include.rownames = FALSE, include.colnames = TRUE,
      caption.placement = "top", booktabs = TRUE)

cat("LaTeX tables saved to output/ directory\n\n")

# =============================================================================
# VISUALIZATIONS
# =============================================================================

cat("================================\n")
cat("CREATING VISUALIZATIONS\n")
cat("================================\n\n")

# Plot 1: Conditional volatilities
if (!is.null(asymmetric_bekk_fit$H_t)) {
  cat("Generating conditional volatility plot...\n")

  # Extract conditional standard deviations
  H_array <- asymmetric_bekk_fit$H_t
  n_obs <- dim(H_array)[3]

  # Create data frame with time index
  vol_data <- data.frame(
    Time = 1:n_obs
  )

  for (i in 1:n_markets) {
    vol_data[[market_names[i]]] <- sqrt(H_array[i, i, ])
  }

  # Reshape for ggplot
  vol_long <- reshape2::melt(vol_data, id.vars = "Time",
                             variable.name = "Market",
                             value.name = "Volatility")

  # Create volatility plot
  p1 <- ggplot(vol_long, aes(x = Time, y = Volatility, color = Market)) +
    geom_line(linewidth = 0.7) +
    theme_bw() +
    labs(title = "Conditional Volatility (ABEKK Model)",
         x = "Time", y = "Conditional Volatility") +
    theme(legend.position = "bottom",
          plot.title = element_text(hjust = 0.5, face = "bold"))

  ggsave("output/plot_conditional_volatility.png", p1,
         width = 10, height = 6, dpi = 300)
  cat("Saved: output/plot_conditional_volatility.png\n")
}

# Plot 2: Spillover heatmap
cat("Generating spillover heatmap...\n")
spillover_long <- reshape2::melt(spillover_matrix)
colnames(spillover_long) <- c("To", "From", "Spillover")

p2 <- ggplot(spillover_long, aes(x = From, y = To, fill = Spillover)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.3f", Spillover)), size = 4) +
  scale_fill_gradient2(low = "white", high = "red",
                       midpoint = median(spillover_long$Spillover),
                       name = "Total\nSpillover") +
  theme_minimal() +
  labs(title = "Volatility Spillover Matrix (ABEKK)",
       x = "Spillover From", y = "Spillover To") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("output/plot_spillover_heatmap.png", p2,
       width = 8, height = 7, dpi = 300)
cat("Saved: output/plot_spillover_heatmap.png\n")

# Plot 3: Directional spillovers
cat("Generating directional spillovers plot...\n")
spillover_df <- data.frame(
  Market = rep(market_names, 2),
  Direction = rep(c("Received", "Transmitted"), each = n_markets),
  Value = c(spillover_to, spillover_from)
)

p3 <- ggplot(spillover_df, aes(x = Market, y = Value, fill = Direction)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_bw() +
  labs(title = "Directional Volatility Spillovers",
       x = "Market", y = "Spillover Magnitude") +
  scale_fill_manual(values = c("Received" = "steelblue",
                               "Transmitted" = "coral")) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        legend.position = "bottom")

ggsave("output/plot_directional_spillovers.png", p3,
       width = 10, height = 6, dpi = 300)
cat("Saved: output/plot_directional_spillovers.png\n")

# Plot 4: Net spillover chart
cat("Generating net spillover chart...\n")
net_df <- data.frame(
  Market = market_names,
  Net_Spillover = net_spillover,
  Type = ifelse(net_spillover > 0, "Transmitter", "Receiver")
)

p4 <- ggplot(net_df, aes(x = reorder(Market, Net_Spillover),
                         y = Net_Spillover, fill = Type)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  theme_bw() +
  labs(title = "Net Volatility Spillover by Market",
       x = "Market", y = "Net Spillover (Transmitted - Received)") +
  scale_fill_manual(values = c("Transmitter" = "coral",
                               "Receiver" = "steelblue")) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        legend.position = "bottom")

ggsave("output/plot_net_spillover.png", p4,
       width = 8, height = 6, dpi = 300)
cat("Saved: output/plot_net_spillover.png\n")

cat("\nAll visualizations saved to output/ directory\n\n")

# =============================================================================
# SAVE RESULTS TO RDS FILE
# =============================================================================

cat("================================\n")
cat("SAVING RESULTS\n")
cat("================================\n\n")

# Save all results to RDS file for later use
results <- list(
  model_fit = asymmetric_bekk_fit,
  parameters = list(
    C = C_matrix,
    A = A_matrix,
    B = B_matrix,
    G = G_matrix
  ),
  spillover = list(
    matrix = spillover_matrix,
    to = spillover_to,
    from = spillover_from,
    net = net_spillover,
    summary = spillover_summary
  ),
  diagnostics = list(
    log_likelihood = asymmetric_bekk_fit$log_likelihood,
    AIC = asymmetric_bekk_fit$AIC,
    BIC = asymmetric_bekk_fit$BIC
  ),
  data_info = list(
    markets = market_names,
    n_obs = nrow(returns_matrix)
  )
)

saveRDS(results, "output/abekk_results.rds")
cat("Results saved to: output/abekk_results.rds\n")
cat("Load with: results <- readRDS('output/abekk_results.rds')\n\n")

# =============================================================================
# SUMMARY FOR PAPER
# =============================================================================

cat("\n================================\n")
cat("SUMMARY FOR PAPER\n")
cat("================================\n\n")

cat("Model Specification:\n")
cat("- Type: Asymmetric BEKK(1,1,1)\n")
cat(sprintf("- Markets: %s\n", paste(market_names, collapse=", ")))
cat(sprintf("- Sample size: %d observations\n", nrow(returns_matrix)))
cat(sprintf("- Log-likelihood: %.4f\n", asymmetric_bekk_fit$log_likelihood))
cat(sprintf("- AIC: %.4f\n", asymmetric_bekk_fit$AIC))
cat(sprintf("- BIC: %.4f\n\n", asymmetric_bekk_fit$BIC))

cat("Key Findings:\n")
for (i in 1:n_markets) {
  cat(sprintf("- %s: %s (net spillover: %.4f)\n",
              market_names[i],
              ifelse(net_spillover[i] > 0, "Net transmitter", "Net receiver"),
              net_spillover[i]))
}
cat("\n")

cat("Strongest Spillovers:\n")
spillover_vec <- as.vector(spillover_matrix)
spillover_indices <- which(spillover_vec > 0)
if (length(spillover_indices) > 0) {
  spillover_vec_nonzero <- spillover_vec[spillover_indices]
  top_n <- min(5, length(spillover_vec_nonzero))
  top_idx <- order(spillover_vec_nonzero, decreasing = TRUE)[1:top_n]

  for (k in top_idx) {
    idx_in_matrix <- spillover_indices[k]
    row_idx <- ((idx_in_matrix - 1) %% n_markets) + 1
    col_idx <- ((idx_in_matrix - 1) %/% n_markets) + 1
    cat(sprintf("- %s → %s: %.4f\n",
                market_names[col_idx],
                market_names[row_idx],
                spillover_matrix[row_idx, col_idx]))
  }
}
cat("\n")

cat("================================\n")
cat("ANALYSIS COMPLETE\n")
cat("================================\n\n")

cat("Output files created in 'output/' directory:\n")
cat("  LaTeX Tables:\n")
cat("    - table_C_matrix.tex\n")
cat("    - table_A_matrix.tex\n")
cat("    - table_B_matrix.tex\n")
cat("    - table_G_matrix.tex\n")
cat("    - table_spillover.tex\n")
cat("    - table_summary.tex\n\n")

cat("  Visualizations:\n")
cat("    - plot_conditional_volatility.png\n")
cat("    - plot_spillover_heatmap.png\n")
cat("    - plot_directional_spillovers.png\n")
cat("    - plot_net_spillover.png\n\n")

cat("  Data:\n")
cat("    - abekk_results.rds\n\n")

cat("To use LaTeX tables in your paper:\n")
cat("1. Add to preamble: \\usepackage{booktabs}\n")
cat("2. Include table: \\input{output/table_A_matrix.tex}\n\n")
