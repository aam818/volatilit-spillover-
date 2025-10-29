################################################################################
# HTML Report Generator for ABEKK Results
#
# This script generates a comprehensive HTML report of ABEKK model results
# that can be easily viewed in a web browser and shared.
#
# Usage: source("generate_html_report.R")
# Output: output/abekk_report.html
################################################################################

# Load required packages
if (!require("knitr")) install.packages("knitr")
if (!require("rmarkdown")) install.packages("rmarkdown")

library(knitr)
library(rmarkdown)

# ==============================================================================
# Generate HTML Report
# ==============================================================================

generate_abekk_html_report <- function(results_file = "output/abekk_results.rds",
                                       output_file = "output/abekk_report.html") {

  # Check if results file exists
  if (!file.exists(results_file)) {
    stop("Results file not found. Please run abekk_estimation.R first.")
  }

  # Load results
  results <- readRDS(results_file)

  # Create R Markdown content
  rmd_content <- sprintf('
---
title: "Asymmetric BEKK Model Results"
subtitle: "Volatility Spillover Analysis"
date: "`r format(Sys.Date(), \'%%B %%d, %%Y\')`"
output:
  html_document:
    theme: cosmo
    toc: true
    toc_float: true
    toc_depth: 3
    number_sections: true
    code_folding: hide
    df_print: paged
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)
library(knitr)
library(kableExtra)

# Load results
results <- readRDS("%s")
```

# Executive Summary

This report presents the results of an Asymmetric BEKK(1,1,1) model estimated to analyze volatility spillovers between **%s**.

## Key Findings

```{r summary-stats}
summary_df <- data.frame(
  Metric = c("Number of Markets", "Sample Size", "Date Range",
             "Log-Likelihood", "AIC", "BIC"),
  Value = c(
    length(results$data_info$markets),
    results$data_info$n_obs,
    sprintf("%%s to %%s",
            format(results$data_info$date_range[1], "%%Y-%%m-%%d"),
            format(results$data_info$date_range[2], "%%Y-%%m-%%d")),
    sprintf("%%.4f", results$diagnostics$log_likelihood),
    sprintf("%%.4f", results$diagnostics$AIC),
    sprintf("%%.4f", results$diagnostics$BIC)
  )
)

kable(summary_df, col.names = c("Metric", "Value"),
      caption = "Model Summary") %%>%%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE)
```

## Market Spillover Roles

```{r spillover-roles}
spillover_summary <- results$spillover$summary
spillover_summary$Role <- ifelse(spillover_summary$Net_Spillover > 0,
                                  "Net Transmitter",
                                  "Net Receiver")

kable(spillover_summary,
      col.names = c("Market", "Spillovers Received", "Spillovers Transmitted",
                    "Net Spillover", "Role"),
      caption = "Directional Spillover Summary",
      digits = 4) %%>%%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE) %%>%%
  row_spec(which(spillover_summary$Net_Spillover > 0),
           background = "#ffe6e6") %%>%%
  row_spec(which(spillover_summary$Net_Spillover < 0),
           background = "#e6f2ff")
```

<div class="alert alert-info">
**Interpretation**: Markets with positive net spillovers (highlighted in red) are net transmitters of volatility to other markets. Markets with negative net spillovers (highlighted in blue) are net receivers.
</div>

---

# Model Specification

The Asymmetric BEKK(1,1,1) model specifies the conditional covariance matrix as:

$$H_t = C\'C + A\' \\epsilon_{t-1} \\epsilon\'_{t-1} A + G\' H_{t-1} G + B\' \\eta_{t-1} \\eta\'_{t-1} B$$

where:

- $H_t$ is the conditional covariance matrix at time $t$
- $C$ is a lower triangular constant matrix
- $A$ captures **ARCH effects** (short-run shock spillovers)
- $B$ captures **asymmetric effects** (leverage effects)
- $G$ captures **GARCH effects** (long-run volatility persistence)
- $\\epsilon_t$ are the innovations (residuals)
- $\\eta_t = \\min(\\epsilon_t, 0)$ captures negative innovations only

---

# Parameter Estimates

## Constant Matrix (C)

The constant matrix $C$ is a lower triangular matrix representing the baseline level of volatility.

```{r param-C}
kable(results$parameters$C,
      caption = "Constant Matrix (C)",
      digits = 4) %%>%%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE)
```

## ARCH Matrix (A) - Short-run Shock Spillovers

The ARCH matrix $A$ captures how shocks in one market affect volatility in another market.

- **Diagonal elements** $A[i,i]$: How own shocks affect own volatility
- **Off-diagonal elements** $A[i,j]$: How shocks in market $j$ affect volatility in market $i$

```{r param-A}
A_matrix <- results$parameters$A

kable(A_matrix,
      caption = "ARCH Matrix (A) - Parameter Estimates",
      digits = 4) %%>%%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE)
```

### ARCH Effects Heatmap

```{r arch-heatmap, fig.width=8, fig.height=6}
library(ggplot2)
library(reshape2)

A_long <- melt(abs(A_matrix))
colnames(A_long) <- c("To", "From", "Value")

ggplot(A_long, aes(x = From, y = To, fill = Value)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%%.3f", Value)), size = 4) +
  scale_fill_gradient(low = "white", high = "blue",
                      name = "|A[i,j]|") +
  theme_minimal() +
  labs(title = "ARCH Effects (Short-run Shock Spillovers)",
       x = "Shock From", y = "Volatility In") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
```

## Asymmetric Matrix (B) - Leverage Effects

The asymmetric matrix $B$ captures how negative shocks (bad news) affect volatility differently than positive shocks.

- **Diagonal elements** $B[i,i]$: Own-market leverage effects
- **Off-diagonal elements** $B[i,j]$: Asymmetric spillovers from market $j$ to market $i$

```{r param-B}
B_matrix <- results$parameters$B

kable(B_matrix,
      caption = "Asymmetric Matrix (B) - Parameter Estimates",
      digits = 4) %%>%%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE)
```

### Leverage Effects Heatmap

```{r leverage-heatmap, fig.width=8, fig.height=6}
B_long <- melt(abs(B_matrix))
colnames(B_long) <- c("To", "From", "Value")

ggplot(B_long, aes(x = From, y = To, fill = Value)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%%.3f", Value)), size = 4) +
  scale_fill_gradient(low = "white", high = "red",
                      name = "|B[i,j]|") +
  theme_minimal() +
  labs(title = "Asymmetric Effects (Leverage Effects)",
       x = "Negative Shock From", y = "Volatility In") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
```

### Asymmetric vs Symmetric Effects

```{r asymmetry-comparison, fig.width=8, fig.height=6}
# Compare |B| / |A| ratios
asymm_ratio <- abs(B_matrix) / (abs(A_matrix) + 1e-10)
diag(asymm_ratio) <- NA

asymm_long <- melt(asymm_ratio)
asymm_long <- asymm_long[!is.na(asymm_long$value), ]
colnames(asymm_long) <- c("To", "From", "Ratio")

ggplot(asymm_long, aes(x = From, y = To, fill = Ratio)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%%.2f", Ratio)), size = 4) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red",
                       midpoint = 1,
                       name = "|B|/|A|") +
  theme_minimal() +
  labs(title = "Asymmetric-to-Symmetric Ratio",
       subtitle = "Values > 1 indicate stronger asymmetric effects",
       x = "From Market", y = "To Market") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5))
```

## GARCH Matrix (G) - Long-run Volatility Spillovers

The GARCH matrix $G$ captures how past volatility affects current volatility.

- **Diagonal elements** $G[i,i]$: Volatility persistence in market $i$
- **Off-diagonal elements** $G[i,j]$: How volatility in market $j$ affects volatility in market $i$

```{r param-G}
G_matrix <- results$parameters$G

kable(G_matrix,
      caption = "GARCH Matrix (G) - Parameter Estimates",
      digits = 4) %%>%%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE)
```

### GARCH Effects Heatmap

```{r garch-heatmap, fig.width=8, fig.height=6}
G_long <- melt(abs(G_matrix))
colnames(G_long) <- c("To", "From", "Value")

ggplot(G_long, aes(x = From, y = To, fill = Value)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%%.3f", Value)), size = 4) +
  scale_fill_gradient(low = "white", high = "green",
                      name = "|G[i,j]|") +
  theme_minimal() +
  labs(title = "GARCH Effects (Long-run Volatility Spillovers)",
       x = "Volatility From", y = "Volatility In") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
```

---

# Spillover Analysis

## Total Spillover Matrix

The total spillover from market $j$ to market $i$ is computed as:
$$\\text{Spillover}[i,j] = |A[i,j]| + |B[i,j]| + |G[i,j]|$$

```{r spillover-matrix}
spillover_matrix <- results$spillover$matrix

kable(spillover_matrix,
      caption = "Total Volatility Spillover Matrix",
      digits = 4) %%>%%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE)
```

### Spillover Network Visualization

```{r spillover-network, fig.width=10, fig.height=8}
spillover_long <- melt(spillover_matrix)
spillover_long <- spillover_long[spillover_long$value > 0, ]
colnames(spillover_long) <- c("To", "From", "Spillover")

ggplot(spillover_long, aes(x = From, y = To, fill = Spillover)) +
  geom_tile(color = "white", size = 1.5) +
  geom_text(aes(label = sprintf("%%.3f", Spillover)), size = 5, fontface = "bold") +
  scale_fill_gradient2(low = "white", mid = "yellow", high = "red",
                       midpoint = median(spillover_long$Spillover),
                       name = "Total\\nSpillover") +
  theme_minimal() +
  labs(title = "Volatility Spillover Network",
       subtitle = "Combined effects from all channels (ARCH + Asymmetric + GARCH)",
       x = "Spillover From", y = "Spillover To") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
        plot.subtitle = element_text(hjust = 0.5, size = 12),
        axis.text = element_text(size = 12),
        legend.title = element_text(size = 10))
```

## Directional Spillovers

```{r directional-spillovers, fig.width=10, fig.height=6}
spillover_df <- data.frame(
  Market = rep(results$data_info$markets, 2),
  Direction = rep(c("Received", "Transmitted"), each = length(results$data_info$markets)),
  Value = c(results$spillover$to, results$spillover$from)
)

ggplot(spillover_df, aes(x = Market, y = Value, fill = Direction)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  theme_bw() +
  labs(title = "Directional Volatility Spillovers by Market",
       x = "Market", y = "Spillover Magnitude") +
  scale_fill_manual(values = c("Received" = "steelblue", "Transmitted" = "coral")) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
        legend.position = "bottom",
        axis.text.x = element_text(angle = 45, hjust = 1))
```

## Net Spillovers

Net spillover is computed as: **Transmitted - Received**

- **Positive values**: Net transmitter of volatility
- **Negative values**: Net receiver of volatility

```{r net-spillovers, fig.width=10, fig.height=6}
net_df <- data.frame(
  Market = results$data_info$markets,
  Net_Spillover = results$spillover$net,
  Type = ifelse(results$spillover$net > 0, "Transmitter", "Receiver")
)

ggplot(net_df, aes(x = reorder(Market, Net_Spillover),
                   y = Net_Spillover, fill = Type)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  theme_bw() +
  labs(title = "Net Volatility Spillover by Market",
       x = "Market", y = "Net Spillover (Transmitted - Received)") +
  scale_fill_manual(values = c("Transmitter" = "coral", "Receiver" = "steelblue")) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", size = 1) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
        legend.position = "bottom",
        axis.text.y = element_text(size = 12))
```

---

# Model Diagnostics

## Information Criteria

```{r diagnostics}
diag_df <- data.frame(
  Criterion = c("Log-Likelihood", "AIC", "BIC"),
  Value = c(
    results$diagnostics$log_likelihood,
    results$diagnostics$AIC,
    results$diagnostics$BIC
  )
)

kable(diag_df,
      caption = "Model Selection Criteria",
      digits = 4) %%>%%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE)
```

<div class="alert alert-info">
**Note**: Lower AIC and BIC values indicate better model fit. Compare these values with alternative model specifications (e.g., symmetric BEKK, diagonal BEKK) to select the best model.
</div>

---

# Interpretation Guide

## Parameter Matrices

### ARCH Matrix (A)
- Captures **immediate shock transmission** between markets
- $A[i,j]$ measures how a shock in market $j$ affects volatility in market $i$ **in the short run**
- Large off-diagonal elements indicate strong **shock spillovers**

### Asymmetric Matrix (B)
- Captures **leverage effects** (asymmetric response to negative shocks)
- $B[i,j]$ measures how **negative shocks** in market $j$ affect volatility in market $i$
- Positive diagonal elements confirm the **leverage effect** (bad news increases volatility more than good news)
- Large values indicate strong **asymmetric spillovers**

### GARCH Matrix (G)
- Captures **volatility persistence** and **long-run volatility spillovers**
- $G[i,i]$ measures how persistent volatility is in market $i$
- Values close to 1 indicate **high volatility persistence**
- Off-diagonal elements show **cross-market volatility transmission**

## Spillover Indices

### Total Spillover
Combines effects from all three channels: $|A[i,j]| + |B[i,j]| + |G[i,j]|$

### Directional Spillovers
- **Spillover TO**: Total volatility received by a market from all others
- **Spillover FROM**: Total volatility transmitted by a market to all others

### Net Spillover
- **Net = FROM - TO**
- Positive: Market is a **net transmitter** (source of volatility)
- Negative: Market is a **net receiver** (absorbs volatility)

---

# Appendix: Technical Details

## Model Estimation

- **Method**: Quasi-Maximum Likelihood (QML)
- **Optimization**: BFGS algorithm
- **Convergence criterion**: 1e-9
- **Standard errors**: Robust QML standard errors

## Software

- **R Version**: `r R.version.string`
- **Package BEKKs**: Used for model estimation
- **Date**: `r Sys.Date()`

---

<div class="alert alert-success">
**Analysis Complete**: This report was automatically generated from ABEKK model results.
For questions or to reproduce this analysis, refer to the source code in `abekk_estimation.R`.
</div>

<style>
.alert {
  padding: 15px;
  margin-bottom: 20px;
  border: 1px solid transparent;
  border-radius: 4px;
}
.alert-info {
  color: #31708f;
  background-color: #d9edf7;
  border-color: #bce8f1;
}
.alert-success {
  color: #3c763d;
  background-color: #dff0d8;
  border-color: #d6e9c6;
}
</style>
', results_file, paste(results$data_info$markets, collapse = ", "))

  # Write R Markdown file
  rmd_file <- tempfile(fileext = ".Rmd")
  writeLines(rmd_content, rmd_file)

  # Render to HTML
  cat("Generating HTML report...\n")
  rmarkdown::render(rmd_file,
                   output_file = basename(output_file),
                   output_dir = dirname(output_file),
                   quiet = TRUE)

  cat(sprintf("\nHTML report generated: %s\n", output_file))
  cat("Open in browser to view the results.\n")

  return(invisible(output_file))
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

# Generate the report
if (file.exists("output/abekk_results.rds")) {
  generate_abekk_html_report()
} else {
  cat("Results file not found.\n")
  cat("Please run abekk_estimation.R first to generate results.\n")
}
