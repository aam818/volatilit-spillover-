# Data Directory

Place your return data files in this directory.

## Expected Format

### CSV File (returns.csv)
```csv
Date,US_ret,CN_ret,TW_ret
2010-01-04,0.5234,-0.3421,0.8123
2010-01-05,-0.2341,0.4123,0.1234
...
```

### Column Requirements

- **Date**: Date column in format YYYY-MM-DD
- **US_ret**: US market returns (percentage)
- **CN_ret**: China market returns (percentage)
- **TW_ret**: Taiwan market returns (percentage)

### Data Sources

You can collect data from:

1. **Yahoo Finance** - Use the `load_data.R` script
2. **Bloomberg Terminal** - Export daily returns
3. **CRSP/Compustat** - Academic databases
4. **Your own data** - Ensure it follows the format above

## Sample Data

To generate sample data for testing:

```r
source("load_data.R")
returns <- create_sample_data(n_obs = 3492, n_markets = 3)
saveRDS(returns, "data/returns.rds")
```

## Recommendations

- **Minimum observations**: 500+ for reliable estimates
- **Frequency**: Daily returns recommended
- **Return calculation**: Log returns × 100 for percentage
- **Missing values**: Should be removed or handled before analysis
