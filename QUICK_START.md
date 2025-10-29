# Quick Start Guide - ABEKK Analysis

This is a 5-minute quick start guide to run your first ABEKK volatility spillover analysis.

## Prerequisites

Ensure you have R installed (version 4.0 or higher recommended).

## Step-by-Step Guide

### Step 1: Install Required Packages (First Time Only)

Open R or RStudio and run:

```r
install.packages(c("BEKKs", "xts", "xtable", "knitr", "ggplot2",
                   "reshape2", "gridExtra", "rmarkdown", "kableExtra"))
```

This will take 2-3 minutes.

### Step 2: Prepare Your Data

Your data should be returns (NOT prices) in one of these formats:

**Option A: CSV File**
```
Date,US,CN,EU
2020-01-01,0.0015,0.0023,0.0012
2020-01-02,-0.0034,0.0045,-0.0011
2020-01-03,0.0067,-0.0012,0.0034
...
```

**Option B: Create Sample Data for Testing**
```r
# Load the data example script
source("load_data_example.R")

# Create sample data (1000 observations, 3 markets)
returns <- create_sample_data(n_obs = 1000, n_markets = 3)
```

**Option C: Load Your Own CSV**
```r
source("load_data_example.R")
returns <- load_from_csv("path/to/your/data.csv", date_column = 1)
```

### Step 3: Run the Analysis

```r
# Simply run the ABEKK estimation script
source("abekk_estimation.R")
```

This will:
- Estimate the ABEKK model (may take 2-10 minutes depending on data size)
- Calculate spillover indices
- Generate LaTeX tables
- Create visualizations
- Save all results

### Step 4: View Results

**Option 1: Generate HTML Report (Recommended for First Time)**
```r
source("generate_html_report.R")
```

Then open `output/abekk_report.html` in your web browser.

**Option 2: Check Console Output**

The script prints comprehensive results to the console, including:
- Parameter estimates
- Spillover matrix
- Net transmitters/receivers
- Model diagnostics

**Option 3: Access Saved Files**

Check the `output/` directory:
- `table_*.tex` - LaTeX tables for your paper
- `plot_*.png` - High-resolution figures
- `abekk_results.rds` - Complete results object

### Step 5: Use Results in Your Paper

**LaTeX Integration:**

Add to your LaTeX preamble:
```latex
\usepackage{booktabs}
```

Include tables in your document:
```latex
\section{Results}

\subsection{ARCH Effects}
\input{output/table_A_matrix.tex}

\subsection{Asymmetric Effects}
\input{output/table_B_matrix.tex}

\subsection{Spillovers}
\input{output/table_spillover.tex}
```

**Or use the complete document:**
```bash
cd output
pdflatex abekk_results_complete.tex
```

## Complete Example Workflow

```r
# 1. Load data loading functions
source("load_data_example.R")

# 2. Create sample data (or load your own)
returns <- create_sample_data(n_obs = 1000, n_markets = 3)

# 3. Check data quality
check_data_quality(returns)

# 4. Run ABEKK estimation
source("abekk_estimation.R")

# 5. Generate HTML report
source("generate_html_report.R")

# 6. Open output/abekk_report.html in your browser
```

## Customization

### Change Market Names

```r
# After loading data, rename columns
colnames(returns) <- c("US", "China", "Europe")
```

### Adjust Model Specification

Edit `abekk_estimation.R` around line 90:

```r
asymmetric_bekk_spec <- bekk_spec(
  model = list(
    type = "bekk",
    asymmetric = TRUE
  ),
  signs = c(-1, -1, -1),  # Change signs if needed
  init_values = NULL
)
```

### Change Estimation Settings

Edit `abekk_estimation.R` around line 105:

```r
asymmetric_bekk_fit <- bekk_fit(
  spec = asymmetric_bekk_spec,
  data = returns_matrix,
  QML_t_ratios = TRUE,
  max_iter = 200,    # Increase if convergence issues
  crit = 1e-10       # Tighten convergence criterion
)
```

## Troubleshooting

### "returns object not found"
Make sure you create/load the returns object before running `abekk_estimation.R`

### Convergence failure
- Try increasing `max_iter` to 200 or 300
- Try `init_values = "random"` in `bekk_spec()`
- Check for outliers in your data

### Very slow estimation
- Normal for large systems (4+ markets)
- Be patient - can take 5-15 minutes
- Consider running overnight for 5+ markets

### LaTeX tables won't compile
- Ensure `\usepackage{booktabs}` in preamble
- Try compiling with `pdflatex` instead of `latex`

## Need More Help?

- **Detailed documentation**: See `README_ABEKK.md`
- **Data loading examples**: See `load_data_example.R`
- **Understanding results**: Open `output/abekk_report.html` for detailed interpretation

## Example Real-World Application

Analyzing US-China-Europe stock market spillovers:

```r
# Load data functions
source("load_data_example.R")

# Download data from Yahoo Finance
symbols <- c("^GSPC", "000001.SS", "^STOXX50E")
returns <- load_from_yahoo(symbols, "2015-01-01", "2023-12-31")

# Rename for clarity
colnames(returns) <- c("US", "China", "Europe")

# Run analysis
source("abekk_estimation.R")

# Generate report
source("generate_html_report.R")
```

Results will tell you:
- Which market transmits the most volatility
- How shocks propagate across markets
- Whether negative shocks have stronger effects
- Long-run vs short-run spillover patterns

---

**That's it! You're ready to analyze volatility spillovers.**

For publication-quality results, see the detailed documentation in `README_ABEKK.md`.
