# Volatility Spillover Analysis

BUS 330 - Volatility spillovers between China, US, and Taiwan tech sector

## Project Overview

This repository contains a comprehensive implementation of the Asymmetric BEKK (ABEKK) model for analyzing volatility spillovers between financial markets, with focus on:
- United States market
- China market
- Taiwan tech sector

## Features

- **Asymmetric BEKK(1,1,1) Model**: Captures leverage effects and asymmetric volatility responses
- **Comprehensive Spillover Analysis**: Identifies net transmitters and receivers of volatility
- **Publication-Ready Output**: Automatic generation of LaTeX tables and high-quality figures
- **Interactive HTML Reports**: Easy-to-read results in your browser
- **Flexible Data Loading**: Support for CSV, Excel, Yahoo Finance, and custom data sources

## Quick Start

1. **Install required packages:**
   ```r
   install.packages(c("BEKKs", "xts", "xtable", "knitr", "ggplot2",
                      "reshape2", "gridExtra", "rmarkdown"))
   ```

2. **Load your data:**
   ```r
   source("load_data_example.R")
   returns <- load_from_csv("your_data.csv")  # or use other loading functions
   ```

3. **Run the analysis:**
   ```r
   source("abekk_estimation.R")
   ```

4. **Generate HTML report:**
   ```r
   source("generate_html_report.R")
   ```

5. **View results:**
   - Open `output/abekk_report.html` in your browser
   - LaTeX tables in `output/table_*.tex`
   - Figures in `output/plot_*.png`

## Documentation

- **[QUICK_START.md](QUICK_START.md)** - 5-minute tutorial to get started
- **[README_ABEKK.md](README_ABEKK.md)** - Comprehensive documentation
- **[abekk_estimation.R](abekk_estimation.R)** - Main estimation script
- **[load_data_example.R](load_data_example.R)** - Data loading templates
- **[generate_html_report.R](generate_html_report.R)** - HTML report generator

## Repository Structure

```
volatilit-spillover-/
├── README.md                    # This file
├── QUICK_START.md              # Quick start guide
├── README_ABEKK.md             # Detailed documentation
├── abekk_estimation.R          # Main ABEKK estimation script
├── load_data_example.R         # Data loading functions
├── generate_html_report.R      # HTML report generator
└── output/                     # Generated results (created automatically)
    ├── table_*.tex             # LaTeX tables
    ├── plot_*.png              # Visualizations
    ├── abekk_results.rds       # R results object
    ├── abekk_report.html       # HTML report
    └── abekk_results_complete.tex  # Complete LaTeX document
```

## Key Outputs

### 1. Parameter Estimates
- **ARCH Matrix (A)**: Short-run shock spillovers
- **Asymmetric Matrix (B)**: Leverage effects
- **GARCH Matrix (G)**: Long-run volatility spillovers

### 2. Spillover Analysis
- Total spillover matrix
- Directional spillovers (TO/FROM each market)
- Net spillover indices (transmitters vs receivers)

### 3. Visualizations
- Conditional volatility time series
- Spillover heatmaps
- Directional spillover charts
- Net spillover rankings

### 4. Publication-Ready Output
- LaTeX tables (booktabs format)
- High-resolution PNG figures (300 DPI)
- Complete LaTeX document
- Interactive HTML report

## Example Results Interpretation

The analysis identifies:
- **Which markets are net transmitters** of volatility (source markets)
- **Which markets are net receivers** of volatility (destination markets)
- **Asymmetric effects**: Whether negative shocks have stronger impacts
- **Spillover channels**: ARCH (shocks), GARCH (volatility), Asymmetric (leverage)

## Citation

If you use this code in your research, please cite:

```bibtex
@misc{volatility-spillover-2025,
  title={Asymmetric BEKK Volatility Spillover Analysis},
  author={[Your Name]},
  year={2025},
  howpublished={\url{https://github.com/yourusername/volatilit-spillover-}}
}
```

And the BEKKs package:
```bibtex
@Manual{BEKKs,
  title = {BEKKs: Multivariate Conditional Volatility Modelling and Forecasting},
  author = {Florian Schöne},
  year = {2023},
  note = {R package version 1.4.3}
}
```

## License

This code is provided for academic and research purposes.

## Support

- See [QUICK_START.md](QUICK_START.md) for basic usage
- See [README_ABEKK.md](README_ABEKK.md) for detailed documentation
- Check [load_data_example.R](load_data_example.R) for data loading examples

---

**Course**: BUS 330
**Topic**: Volatility Spillovers - China, US, Taiwan Tech Sector
**Last Updated**: October 29, 2025 
