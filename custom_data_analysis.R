################################################################################
# Custom Data Analysis for Asymmetric Volatility Spillovers
#
# This script provides functions to analyze custom CSV data files
# for asymmetric volatility spillover analysis
################################################################################

source("asymmetric_volatility_spillover.R")

################################################################################
# CUSTOM DATA LOADING
################################################################################

#' Load custom market data from CSV files
#' 
#' @param file_paths character vector of CSV file paths
#' @param date_column name of the date column
#' @param price_columns character vector of column names for prices
#' @param date_format date format string (e.g., "%Y-%m-%d")
#' @return xts object with returns data
load_custom_data <- function(file_paths, 
                             date_column = "Date",
                             price_columns = NULL,
                             date_format = "%Y-%m-%d") {
  
  cat("Loading custom market data...\n")
  
  data_list <- list()
  
  for(i in seq_along(file_paths)) {
    file_path <- file_paths[i]
    
    if(!file.exists(file_path)) {
      cat("Warning: File not found:", file_path, "\n")
      next
    }
    
    cat("Reading:", file_path, "\n")
    
    # Read CSV file
    data <- read.csv(file_path, stringsAsFactors = FALSE)
    
    # Convert date column
    dates <- as.Date(data[[date_column]], format = date_format)
    
    # Extract price columns
    if(is.null(price_columns)) {
      # Use all numeric columns except date
      price_cols <- sapply(data, is.numeric)
      prices <- data[, price_cols, drop = FALSE]
    } else {
      prices <- data[, price_columns, drop = FALSE]
    }
    
    # Create xts object
    prices_xts <- xts(prices, order.by = dates)
    
    # Store in list
    market_name <- tools::file_path_sans_ext(basename(file_path))
    data_list[[market_name]] <- prices_xts
  }
  
  # Merge all data
  if(length(data_list) == 0) {
    stop("No data loaded successfully.")
  }
  
  prices <- do.call(merge, data_list)
  prices <- na.omit(prices)
  
  # Calculate log returns
  returns <- diff(log(prices)) * 100  # Returns in percentage
  returns <- na.omit(returns)
  
  cat("Custom data loaded successfully.\n")
  cat("Sample size:", nrow(returns), "observations\n")
  cat("Markets:", ncol(returns), "\n")
  cat("Date range:", paste(index(returns)[1]), "to", paste(index(returns)[nrow(returns)]), "\n\n")
  
  return(returns)
}

#' Load single CSV file with multiple market columns
#' 
#' @param file_path path to CSV file
#' @param date_column name of the date column
#' @param market_columns character vector of column names for market prices
#' @param date_format date format string
#' @return xts object with returns data
load_single_csv <- function(file_path,
                            date_column = "Date",
                            market_columns,
                            date_format = "%Y-%m-%d") {
  
  cat("Loading data from single CSV file...\n")
  
  if(!file.exists(file_path)) {
    stop("File not found:", file_path)
  }
  
  # Read CSV file
  data <- read.csv(file_path, stringsAsFactors = FALSE)
  
  # Convert date column
  dates <- as.Date(data[[date_column]], format = date_format)
  
  # Extract market columns
  prices <- data[, market_columns, drop = FALSE]
  
  # Create xts object
  prices_xts <- xts(prices, order.by = dates)
  prices_xts <- na.omit(prices_xts)
  
  # Calculate log returns
  returns <- diff(log(prices_xts)) * 100  # Returns in percentage
  returns <- na.omit(returns)
  
  cat("Data loaded successfully.\n")
  cat("Sample size:", nrow(returns), "observations\n")
  cat("Markets:", paste(colnames(returns), collapse = ", "), "\n")
  cat("Date range:", paste(index(returns)[1]), "to", paste(index(returns)[nrow(returns)]), "\n\n")
  
  return(returns)
}

################################################################################
# ASYMMETRY TESTS
################################################################################

#' Test for asymmetric volatility effects
#' 
#' @param gjr_models list of fitted GJR-GARCH models
#' @return data frame with asymmetry test results
test_asymmetric_effects <- function(gjr_models) {
  
  cat("Testing for asymmetric volatility effects (leverage effect)...\n\n")
  
  results <- data.frame(
    Market = character(),
    Gamma = numeric(),
    Std_Error = numeric(),
    T_Statistic = numeric(),
    P_Value = numeric(),
    Significant = character(),
    stringsAsFactors = FALSE
  )
  
  for(name in names(gjr_models)) {
    model <- gjr_models[[name]]
    coef_table <- model@fit$matcoef
    
    # Extract gamma coefficient (asymmetric term)
    if("gamma1" %in% rownames(coef_table)) {
      gamma <- coef_table["gamma1", "Estimate"]
      std_err <- coef_table["gamma1", "Std. Error"]
      t_stat <- coef_table["gamma1", "t value"]
      p_val <- coef_table["gamma1", "Pr(>|t|)"]
      
      significant <- ifelse(p_val < 0.01, "***",
                           ifelse(p_val < 0.05, "**",
                                 ifelse(p_val < 0.1, "*", "")))
      
      results <- rbind(results, data.frame(
        Market = name,
        Gamma = gamma,
        Std_Error = std_err,
        T_Statistic = t_stat,
        P_Value = p_val,
        Significant = significant,
        stringsAsFactors = FALSE
      ))
    }
  }
  
  cat("--- Asymmetry Test Results ---\n")
  cat("Gamma > 0 indicates leverage effect (negative shocks increase volatility more)\n\n")
  print(results)
  cat("\nSignificance codes: 0 '***' 0.01 '**' 0.05 '*' 0.1\n\n")
  
  return(results)
}

################################################################################
# ADVANCED SPILLOVER METRICS
################################################################################

#' Calculate pairwise spillovers between markets
#' 
#' @param spillover_result spillover result from calculate_spillover_index
#' @return data frame with pairwise spillover measures
pairwise_spillovers <- function(spillover_result) {
  
  spillover_table <- spillover_result$spillover_table
  n_markets <- nrow(spillover_table) - 2  # Exclude TO and NET rows
  
  markets <- rownames(spillover_table)[1:n_markets]
  
  pairwise_results <- data.frame(
    From = character(),
    To = character(),
    Spillover = numeric(),
    stringsAsFactors = FALSE
  )
  
  for(i in 1:n_markets) {
    for(j in 1:n_markets) {
      if(i != j) {
        from_market <- markets[i]
        to_market <- markets[j]
        spillover_value <- spillover_table[to_market, from_market]
        
        pairwise_results <- rbind(pairwise_results, data.frame(
          From = from_market,
          To = to_market,
          Spillover = spillover_value,
          stringsAsFactors = FALSE
        ))
      }
    }
  }
  
  cat("--- Pairwise Directional Spillovers ---\n")
  print(pairwise_results)
  cat("\n")
  
  return(pairwise_results)
}

#' Calculate net pairwise spillovers
#' 
#' @param spillover_result spillover result from calculate_spillover_index
#' @return data frame with net pairwise spillovers
net_pairwise_spillovers <- function(spillover_result) {
  
  pairwise <- pairwise_spillovers(spillover_result)
  
  # Calculate net spillovers for each pair
  markets <- unique(c(pairwise$From, pairwise$To))
  
  net_results <- data.frame(
    Market_A = character(),
    Market_B = character(),
    Net_Spillover_A_to_B = numeric(),
    Interpretation = character(),
    stringsAsFactors = FALSE
  )
  
  for(i in 1:(length(markets)-1)) {
    for(j in (i+1):length(markets)) {
      market_a <- markets[i]
      market_b <- markets[j]
      
      # Spillover from A to B
      spillover_a_to_b <- pairwise[pairwise$From == market_a & pairwise$To == market_b, "Spillover"]
      # Spillover from B to A
      spillover_b_to_a <- pairwise[pairwise$From == market_b & pairwise$To == market_a, "Spillover"]
      
      net_spillover <- spillover_a_to_b - spillover_b_to_a
      
      interpretation <- ifelse(
        net_spillover > 0,
        paste(market_a, "→", market_b),
        paste(market_b, "→", market_a)
      )
      
      net_results <- rbind(net_results, data.frame(
        Market_A = market_a,
        Market_B = market_b,
        Net_Spillover_A_to_B = net_spillover,
        Interpretation = interpretation,
        stringsAsFactors = FALSE
      ))
    }
  }
  
  cat("--- Net Pairwise Spillovers ---\n")
  cat("Positive: A transmits more to B; Negative: B transmits more to A\n\n")
  print(net_results)
  cat("\n")
  
  return(net_results)
}

################################################################################
# EXPORT AND REPORTING
################################################################################

#' Generate comprehensive report
#' 
#' @param results results object from run_spillover_analysis
#' @param output_dir directory to save outputs
#' @return NULL (saves files to disk)
generate_report <- function(results, output_dir = "spillover_results") {
  
  # Create output directory
  if(!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  cat("Generating comprehensive report...\n")
  cat("Output directory:", output_dir, "\n\n")
  
  # Save descriptive statistics
  write.csv(results$descriptive_stats, 
            file = file.path(output_dir, "descriptive_statistics.csv"))
  
  # Save spillover table
  write.csv(results$spillover_result$spillover_table, 
            file = file.path(output_dir, "spillover_table.csv"))
  
  # Save GJR-GARCH coefficients
  garch_coefs <- data.frame()
  for(name in names(results$gjr_models)) {
    coefs <- as.data.frame(results$gjr_models[[name]]@fit$matcoef)
    coefs$Market <- name
    coefs$Parameter <- rownames(coefs)
    garch_coefs <- rbind(garch_coefs, coefs)
  }
  write.csv(garch_coefs, 
            file = file.path(output_dir, "garch_coefficients.csv"),
            row.names = FALSE)
  
  # Test asymmetric effects
  asymmetry_tests <- test_asymmetric_effects(results$gjr_models)
  write.csv(asymmetry_tests, 
            file = file.path(output_dir, "asymmetry_tests.csv"),
            row.names = FALSE)
  
  # Calculate pairwise spillovers
  pairwise <- pairwise_spillovers(results$spillover_result)
  write.csv(pairwise, 
            file = file.path(output_dir, "pairwise_spillovers.csv"),
            row.names = FALSE)
  
  # Calculate net pairwise spillovers
  net_pairwise <- net_pairwise_spillovers(results$spillover_result)
  write.csv(net_pairwise, 
            file = file.path(output_dir, "net_pairwise_spillovers.csv"),
            row.names = FALSE)
  
  # Save rolling spillovers
  if(!is.null(results$rolling_spillovers)) {
    rolling_df <- data.frame(
      Date = index(results$rolling_spillovers),
      Total_Spillover = as.vector(results$rolling_spillovers)
    )
    write.csv(rolling_df, 
              file = file.path(output_dir, "rolling_spillovers.csv"),
              row.names = FALSE)
  }
  
  # Save plots
  ggsave(filename = file.path(output_dir, "returns_plot.png"), 
         plot = results$plots$returns_plot, 
         width = 10, height = 8)
  
  ggsave(filename = file.path(output_dir, "volatility_plot.png"), 
         plot = results$plots$volatility_plot, 
         width = 10, height = 8)
  
  ggsave(filename = file.path(output_dir, "spillover_plot.png"), 
         plot = results$plots$spillover_plot, 
         width = 10, height = 6)
  
  if(!is.null(results$plots$rolling_spillover_plot)) {
    ggsave(filename = file.path(output_dir, "rolling_spillover_plot.png"), 
           plot = results$plots$rolling_spillover_plot, 
           width = 10, height = 6)
  }
  
  # Save complete results object
  saveRDS(results, file = file.path(output_dir, "complete_results.rds"))
  
  cat("Report generated successfully!\n")
  cat("Files saved in:", output_dir, "\n\n")
  cat("Generated files:\n")
  cat("- descriptive_statistics.csv\n")
  cat("- spillover_table.csv\n")
  cat("- garch_coefficients.csv\n")
  cat("- asymmetry_tests.csv\n")
  cat("- pairwise_spillovers.csv\n")
  cat("- net_pairwise_spillovers.csv\n")
  if(!is.null(results$rolling_spillovers)) {
    cat("- rolling_spillovers.csv\n")
  }
  cat("- returns_plot.png\n")
  cat("- volatility_plot.png\n")
  cat("- spillover_plot.png\n")
  if(!is.null(results$plots$rolling_spillover_plot)) {
    cat("- rolling_spillover_plot.png\n")
  }
  cat("- complete_results.rds\n\n")
  
  return(invisible(NULL))
}

################################################################################
# EXAMPLE: CUSTOM DATA ANALYSIS
################################################################################

#' Example function to analyze custom data
#' 
#' @param file_path path to CSV file with market data
#' @param date_column name of date column
#' @param market_columns character vector of market column names
#' @param output_dir output directory for results
#' @return results list
analyze_custom_data <- function(file_path,
                               date_column = "Date",
                               market_columns = c("US_Tech", "China", "Taiwan_Tech"),
                               output_dir = "custom_spillover_results") {
  
  cat("================================================================================\n")
  cat("CUSTOM DATA ASYMMETRIC VOLATILITY SPILLOVER ANALYSIS\n")
  cat("================================================================================\n\n")
  
  # Load custom data
  returns <- load_single_csv(
    file_path = file_path,
    date_column = date_column,
    market_columns = market_columns
  )
  
  # Descriptive statistics
  cat("--- Descriptive Statistics ---\n")
  desc_stats <- descriptive_statistics(returns)
  print(round(desc_stats, 4))
  cat("\n")
  
  # Estimate GJR-GARCH models
  gjr_models <- estimate_gjr_garch(returns, distribution = "std")
  
  # Test asymmetric effects
  asymmetry_tests <- test_asymmetric_effects(gjr_models)
  
  # Extract standardized residuals
  std_residuals <- extract_standardized_residuals(gjr_models, returns)
  
  # Calculate spillover index
  spillover_result <- calculate_spillover_index(std_residuals, lag_order = 2, n_ahead = 10)
  
  # Pairwise analysis
  pairwise <- pairwise_spillovers(spillover_result)
  net_pairwise <- net_pairwise_spillovers(spillover_result)
  
  # Generate plots
  cat("Generating plots...\n")
  p1 <- plot_returns(returns)
  p2 <- plot_conditional_volatility(gjr_models)
  p3 <- plot_spillover_network(spillover_result)
  
  plots <- list(
    returns_plot = p1,
    volatility_plot = p2,
    spillover_plot = p3
  )
  
  # Compile results
  results <- list(
    returns = returns,
    descriptive_stats = desc_stats,
    gjr_models = gjr_models,
    asymmetry_tests = asymmetry_tests,
    std_residuals = std_residuals,
    spillover_result = spillover_result,
    pairwise_spillovers = pairwise,
    net_pairwise_spillovers = net_pairwise,
    plots = plots
  )
  
  # Generate report
  generate_report(results, output_dir = output_dir)
  
  cat("================================================================================\n")
  cat("CUSTOM DATA ANALYSIS COMPLETED SUCCESSFULLY\n")
  cat("================================================================================\n\n")
  
  return(results)
}
