################################################################################
# Asymmetric Volatility Spillover Analysis
# Between China, US, and Taiwan (Tech Sector)
#
# This script implements asymmetric volatility spillover analysis using:
# - GJR-GARCH models for asymmetric volatility modeling
# - Diebold-Yilmaz spillover index methodology
# - Rolling window analysis for time-varying spillovers
################################################################################

# Load required libraries
required_packages <- c("rugarch", "rmgarch", "zoo", "xts", "quantmod", 
                       "ggplot2", "reshape2", "gridExtra", "vars")

# Install missing packages
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) {
    cat("Installing missing packages:", paste(new_packages, collapse=", "), "\n")
    install.packages(new_packages, repos='http://cran.rstudio.com/')
  }
}

install_if_missing(required_packages)

# Load libraries
suppressPackageStartupMessages({
  library(rugarch)
  library(rmgarch)
  library(zoo)
  library(xts)
  library(quantmod)
  library(ggplot2)
  library(reshape2)
  library(gridExtra)
  library(vars)
})

################################################################################
# 1. DATA LOADING AND PREPROCESSING
################################################################################

#' Load financial data for China, US, and Taiwan
#' 
#' @param start_date Start date for data download (format: "YYYY-MM-DD")
#' @param end_date End date for data download (format: "YYYY-MM-DD")
#' @return xts object with returns data
load_market_data <- function(start_date = "2015-01-01", 
                              end_date = Sys.Date()) {
  
  cat("Loading market data...\n")
  
  # Define tickers
  # US: S&P 500 Technology Sector (XLK)
  # China: FTSE China 50 Index (FXI) or Shanghai Composite
  # Taiwan: Taiwan Semiconductor (TSM) as proxy for Taiwan tech sector
  
  tickers <- c("XLK", "FXI", "TSM")
  names <- c("US_Tech", "China", "Taiwan_Tech")
  
  # Download data
  data_list <- list()
  
  for(i in seq_along(tickers)) {
    cat("Downloading", tickers[i], "...\n")
    tryCatch({
      data <- getSymbols(tickers[i], src = "yahoo", 
                        from = start_date, to = end_date, 
                        auto.assign = FALSE)
      # Extract adjusted close prices
      prices <- Ad(data)
      colnames(prices) <- names[i]
      data_list[[names[i]]] <- prices
    }, error = function(e) {
      cat("Error downloading", tickers[i], ":", e$message, "\n")
      return(NULL)
    })
  }
  
  # Merge all data
  prices <- do.call(merge, data_list)
  prices <- na.omit(prices)
  
  # Calculate log returns
  returns <- diff(log(prices)) * 100  # Returns in percentage
  returns <- na.omit(returns)
  
  cat("Data loaded successfully.\n")
  cat("Sample size:", nrow(returns), "observations\n")
  cat("Date range:", paste(index(returns)[1]), "to", paste(index(returns)[nrow(returns)]), "\n\n")
  
  return(returns)
}

#' Calculate descriptive statistics
#' 
#' @param returns xts object with returns
#' @return data frame with descriptive statistics
descriptive_statistics <- function(returns) {
  
  stats <- data.frame(
    Mean = apply(returns, 2, mean),
    SD = apply(returns, 2, sd),
    Skewness = apply(returns, 2, function(x) {
      n <- length(x)
      (n * sum((x - mean(x))^3)) / ((n - 1) * (n - 2) * sd(x)^3)
    }),
    Kurtosis = apply(returns, 2, function(x) {
      n <- length(x)
      ((n * (n + 1)) / ((n - 1) * (n - 2) * (n - 3))) * 
        sum((x - mean(x))^4) / sd(x)^4 - 
        (3 * (n - 1)^2) / ((n - 2) * (n - 3))
    }),
    Min = apply(returns, 2, min),
    Max = apply(returns, 2, max)
  )
  
  return(stats)
}

################################################################################
# 2. ASYMMETRIC VOLATILITY MODELING (GJR-GARCH)
################################################################################

#' Estimate GJR-GARCH(1,1) models for each series
#' 
#' @param returns xts object with returns
#' @param distribution Distribution assumption ("norm", "std", "ged")
#' @return list of fitted models
estimate_gjr_garch <- function(returns, distribution = "std") {
  
  cat("Estimating GJR-GARCH(1,1) models...\n")
  
  # Specify GJR-GARCH(1,1) model with asymmetric effect
  spec <- ugarchspec(
    variance.model = list(model = "gjrGARCH", garchOrder = c(1, 1)),
    mean.model = list(armaOrder = c(1, 0), include.mean = TRUE),
    distribution.model = distribution
  )
  
  models <- list()
  
  for(i in 1:ncol(returns)) {
    cat("Fitting model for", colnames(returns)[i], "...\n")
    
    fit <- ugarchfit(spec = spec, data = returns[, i], solver = "hybrid")
    models[[colnames(returns)[i]]] <- fit
    
    # Print summary statistics
    cat("\n--- ", colnames(returns)[i], " ---\n")
    print(fit@fit$matcoef)
    cat("\n")
  }
  
  cat("GJR-GARCH models estimated successfully.\n\n")
  
  return(models)
}

#' Extract standardized residuals from GJR-GARCH models
#' 
#' @param models list of fitted GJR-GARCH models
#' @param returns xts object with original returns
#' @return xts object with standardized residuals
extract_standardized_residuals <- function(models, returns) {
  
  residuals_list <- list()
  
  for(name in names(models)) {
    resid <- residuals(models[[name]], standardize = TRUE)
    residuals_list[[name]] <- resid
  }
  
  # Merge into xts object
  std_residuals <- do.call(merge, residuals_list)
  colnames(std_residuals) <- names(models)
  
  return(std_residuals)
}

################################################################################
# 3. SPILLOVER INDEX CALCULATION (DIEBOLD-YILMAZ METHODOLOGY)
################################################################################

#' Calculate spillover index using VAR and forecast error variance decomposition
#' 
#' @param data xts object with standardized residuals or returns
#' @param lag_order VAR lag order
#' @param n_ahead Forecast horizon for variance decomposition
#' @return list with spillover table and indices
calculate_spillover_index <- function(data, lag_order = 2, n_ahead = 10) {
  
  cat("Calculating spillover index...\n")
  cat("VAR lag order:", lag_order, "\n")
  cat("Forecast horizon:", n_ahead, "\n\n")
  
  # Convert to data frame for VAR estimation
  data_df <- as.data.frame(data)
  
  # Estimate VAR model
  var_model <- VAR(data_df, p = lag_order, type = "const")
  
  # Forecast error variance decomposition
  fevd <- fevd(var_model, n.ahead = n_ahead)
  
  # Extract FEVD values at horizon n_ahead
  n_vars <- ncol(data)
  spillover_table <- matrix(0, nrow = n_vars, ncol = n_vars)
  
  for(i in 1:n_vars) {
    spillover_table[i, ] <- fevd[[i]][n_ahead, ]
  }
  
  rownames(spillover_table) <- colnames(data)
  colnames(spillover_table) <- colnames(data)
  
  # Calculate spillover indices
  
  # Total spillover index
  total_spillover <- (sum(spillover_table) - sum(diag(spillover_table))) / sum(spillover_table) * 100
  
  # Directional spillovers TO others
  to_spillovers <- (colSums(spillover_table) - diag(spillover_table)) / sum(spillover_table) * 100
  
  # Directional spillovers FROM others
  from_spillovers <- (rowSums(spillover_table) - diag(spillover_table)) / sum(spillover_table) * 100
  
  # Net spillovers
  net_spillovers <- to_spillovers - from_spillovers
  
  # Create summary table
  spillover_table_pct <- spillover_table / rowSums(spillover_table) * 100
  
  # Add FROM column
  spillover_table_pct <- cbind(spillover_table_pct, FROM = from_spillovers)
  
  # Add TO row
  spillover_table_pct <- rbind(spillover_table_pct, TO = c(to_spillovers, NA))
  
  # Add NET row
  spillover_table_pct <- rbind(spillover_table_pct, NET = c(net_spillovers, NA))
  
  cat("--- Spillover Table (%) ---\n")
  print(round(spillover_table_pct, 2))
  cat("\nTotal Spillover Index:", round(total_spillover, 2), "%\n\n")
  
  return(list(
    spillover_table = spillover_table_pct,
    total_spillover = total_spillover,
    to_spillovers = to_spillovers,
    from_spillovers = from_spillovers,
    net_spillovers = net_spillovers,
    var_model = var_model
  ))
}

################################################################################
# 4. ROLLING WINDOW SPILLOVER ANALYSIS
################################################################################

#' Calculate rolling window spillover indices
#' 
#' @param data xts object with standardized residuals or returns
#' @param window_size Rolling window size (number of observations)
#' @param lag_order VAR lag order
#' @param n_ahead Forecast horizon for variance decomposition
#' @return xts object with rolling spillover indices
rolling_spillover_analysis <- function(data, window_size = 250, 
                                       lag_order = 2, n_ahead = 10) {
  
  cat("Calculating rolling window spillover indices...\n")
  cat("Window size:", window_size, "observations\n")
  cat("This may take a while...\n\n")
  
  n_obs <- nrow(data)
  n_windows <- n_obs - window_size + 1
  
  # Initialize storage
  total_spillovers <- numeric(n_windows)
  dates <- index(data)[window_size:n_obs]
  
  # Progress bar
  pb <- txtProgressBar(min = 0, max = n_windows, style = 3)
  
  for(i in 1:n_windows) {
    # Extract window data
    window_data <- data[i:(i + window_size - 1), ]
    
    tryCatch({
      # Calculate spillover index for this window
      spillover_result <- calculate_spillover_index(
        window_data, 
        lag_order = lag_order, 
        n_ahead = n_ahead
      )
      
      total_spillovers[i] <- spillover_result$total_spillover
      
    }, error = function(e) {
      total_spillovers[i] <- NA
    })
    
    setTxtProgressBar(pb, i)
  }
  
  close(pb)
  
  # Create xts object
  rolling_spillovers <- xts(total_spillovers, order.by = dates)
  colnames(rolling_spillovers) <- "Total_Spillover"
  
  cat("\nRolling window analysis completed.\n\n")
  
  return(rolling_spillovers)
}

################################################################################
# 5. VISUALIZATION FUNCTIONS
################################################################################

#' Plot time series of returns
#' 
#' @param returns xts object with returns
#' @return ggplot object
plot_returns <- function(returns) {
  
  # Convert to long format
  returns_df <- data.frame(
    Date = rep(index(returns), ncol(returns)),
    Market = rep(colnames(returns), each = nrow(returns)),
    Return = as.vector(returns)
  )
  
  p <- ggplot(returns_df, aes(x = Date, y = Return, color = Market)) +
    geom_line(alpha = 0.7) +
    facet_wrap(~Market, ncol = 1, scales = "free_y") +
    theme_minimal() +
    labs(title = "Returns Over Time",
         x = "Date",
         y = "Return (%)") +
    theme(legend.position = "bottom")
  
  return(p)
}

#' Plot conditional volatility from GJR-GARCH models
#' 
#' @param models list of fitted GJR-GARCH models
#' @return ggplot object
plot_conditional_volatility <- function(models) {
  
  # Extract conditional volatility
  vol_list <- list()
  
  for(name in names(models)) {
    vol <- sigma(models[[name]])
    vol_list[[name]] <- xts(vol, order.by = index(vol))
  }
  
  vol_xts <- do.call(merge, vol_list)
  colnames(vol_xts) <- names(models)
  
  # Convert to long format
  vol_df <- data.frame(
    Date = rep(index(vol_xts), ncol(vol_xts)),
    Market = rep(colnames(vol_xts), each = nrow(vol_xts)),
    Volatility = as.vector(vol_xts)
  )
  
  p <- ggplot(vol_df, aes(x = Date, y = Volatility, color = Market)) +
    geom_line(alpha = 0.7) +
    facet_wrap(~Market, ncol = 1, scales = "free_y") +
    theme_minimal() +
    labs(title = "Conditional Volatility from GJR-GARCH Models",
         x = "Date",
         y = "Conditional Volatility") +
    theme(legend.position = "bottom")
  
  return(p)
}

#' Plot spillover network diagram
#' 
#' @param spillover_result spillover result from calculate_spillover_index
#' @return ggplot object
plot_spillover_network <- function(spillover_result) {
  
  # Extract directional spillovers
  to_spillovers <- spillover_result$to_spillovers
  from_spillovers <- spillover_result$from_spillovers
  net_spillovers <- spillover_result$net_spillovers
  
  # Create data frame
  spillover_df <- data.frame(
    Market = names(to_spillovers),
    To = to_spillovers,
    From = from_spillovers,
    Net = net_spillovers
  )
  
  # Reshape for plotting
  spillover_long <- melt(spillover_df, id.vars = "Market")
  
  p <- ggplot(spillover_long, aes(x = Market, y = value, fill = variable)) +
    geom_bar(stat = "identity", position = "dodge") +
    theme_minimal() +
    labs(title = "Directional Volatility Spillovers",
         x = "Market",
         y = "Spillover Index (%)",
         fill = "Direction") +
    theme(legend.position = "bottom") +
    scale_fill_brewer(palette = "Set2")
  
  return(p)
}

#' Plot rolling spillover indices
#' 
#' @param rolling_spillovers xts object with rolling spillovers
#' @return ggplot object
plot_rolling_spillovers <- function(rolling_spillovers) {
  
  rolling_df <- data.frame(
    Date = index(rolling_spillovers),
    Spillover = as.vector(rolling_spillovers)
  )
  
  p <- ggplot(rolling_df, aes(x = Date, y = Spillover)) +
    geom_line(color = "blue", size = 0.8) +
    theme_minimal() +
    labs(title = "Rolling Window Total Spillover Index",
         x = "Date",
         y = "Total Spillover Index (%)") +
    geom_hline(yintercept = mean(rolling_df$Spillover, na.rm = TRUE), 
               linetype = "dashed", color = "red")
  
  return(p)
}

################################################################################
# 6. MAIN ANALYSIS FUNCTION
################################################################################

#' Run complete asymmetric volatility spillover analysis
#' 
#' @param start_date Start date for data download
#' @param end_date End date for data download
#' @param lag_order VAR lag order
#' @param n_ahead Forecast horizon
#' @param window_size Rolling window size
#' @param run_rolling Whether to run rolling window analysis
#' @return list with all results
run_spillover_analysis <- function(start_date = "2015-01-01",
                                   end_date = Sys.Date(),
                                   lag_order = 2,
                                   n_ahead = 10,
                                   window_size = 250,
                                   run_rolling = TRUE) {
  
  cat("================================================================================\n")
  cat("ASYMMETRIC VOLATILITY SPILLOVER ANALYSIS\n")
  cat("China, US, and Taiwan (Tech Sector)\n")
  cat("================================================================================\n\n")
  
  # Step 1: Load data
  returns <- load_market_data(start_date, end_date)
  
  # Step 2: Descriptive statistics
  cat("--- Descriptive Statistics ---\n")
  desc_stats <- descriptive_statistics(returns)
  print(round(desc_stats, 4))
  cat("\n")
  
  # Step 3: Estimate GJR-GARCH models
  gjr_models <- estimate_gjr_garch(returns, distribution = "std")
  
  # Step 4: Extract standardized residuals
  std_residuals <- extract_standardized_residuals(gjr_models, returns)
  
  # Step 5: Calculate spillover index
  spillover_result <- calculate_spillover_index(
    std_residuals, 
    lag_order = lag_order, 
    n_ahead = n_ahead
  )
  
  # Step 6: Rolling window analysis (optional)
  rolling_spillovers <- NULL
  if(run_rolling) {
    rolling_spillovers <- rolling_spillover_analysis(
      std_residuals,
      window_size = window_size,
      lag_order = lag_order,
      n_ahead = n_ahead
    )
  }
  
  # Step 7: Generate plots
  cat("Generating plots...\n")
  
  p1 <- plot_returns(returns)
  p2 <- plot_conditional_volatility(gjr_models)
  p3 <- plot_spillover_network(spillover_result)
  
  plots <- list(
    returns_plot = p1,
    volatility_plot = p2,
    spillover_plot = p3
  )
  
  if(!is.null(rolling_spillovers)) {
    p4 <- plot_rolling_spillovers(rolling_spillovers)
    plots$rolling_spillover_plot <- p4
  }
  
  cat("Plots generated successfully.\n\n")
  
  # Return all results
  results <- list(
    returns = returns,
    descriptive_stats = desc_stats,
    gjr_models = gjr_models,
    std_residuals = std_residuals,
    spillover_result = spillover_result,
    rolling_spillovers = rolling_spillovers,
    plots = plots
  )
  
  cat("================================================================================\n")
  cat("ANALYSIS COMPLETED SUCCESSFULLY\n")
  cat("================================================================================\n\n")
  
  return(results)
}

################################################################################
# 7. EXAMPLE USAGE
################################################################################

# Run the analysis
if(interactive()) {
  cat("Starting asymmetric volatility spillover analysis...\n\n")
  
  # Run analysis with default parameters
  results <- run_spillover_analysis(
    start_date = "2015-01-01",
    end_date = Sys.Date(),
    lag_order = 2,
    n_ahead = 10,
    window_size = 250,
    run_rolling = TRUE
  )
  
  # Display plots
  print(results$plots$returns_plot)
  print(results$plots$volatility_plot)
  print(results$plots$spillover_plot)
  
  if(!is.null(results$plots$rolling_spillover_plot)) {
    print(results$plots$rolling_spillover_plot)
  }
  
  # Save results
  cat("\nSaving results...\n")
  saveRDS(results, file = "spillover_results.rds")
  
  # Export spillover table to CSV
  write.csv(results$spillover_result$spillover_table, 
            file = "spillover_table.csv")
  
  cat("Results saved successfully.\n")
  cat("- spillover_results.rds: Complete results object\n")
  cat("- spillover_table.csv: Spillover table in CSV format\n\n")
}
