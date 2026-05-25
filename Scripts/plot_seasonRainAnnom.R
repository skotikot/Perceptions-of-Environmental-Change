#' -----------------------------------------------------------------------------
#' Project: Perceptions of change
#' Script: Spatiotemporal Rainfall Anomalies and Seasonal Timing Analytics
#' Author: Kotikot et al.
#' Date: May 2026
#' -----------------------------------------------------------------------------
#' Purpose:
#' Ingests field-based household coordinates and pairs them with multi-temporal 
#' gridded precipitation stacks (Unimodal, Long Rains, Short Rains) via 'terra'.
#' Calculates moving averages for annualized onset/cessation anomalies, 
#' outputting a pannel figure.
#' -----------------------------------------------------------------------------

# =============================================================================
# 0. Load Required Libraries
# =============================================================================
library(sf)         # Modern Simple Features vector manipulation framework
library(terra)      # High-performance grid analytics processing engine
library(tidyverse)  # Aggregates dplyr, tidyr, ggplot2, and readr packages
library(zoo)        # Optimized rolling window calculation matrices
library(patchwork)  # Professional plot layout compositor framework

# =============================================================================
# 1. Environment Configurations & Directory Paths
# =============================================================================
DATA_DIR    <- "../Data/Raw"
PROCESSED   <- "../Data/Processed"
OUTPUT_FIGS <- "../Data/Figures"

# Ingest administrative boundaries natively via sf engine
narok_county <- sf::st_read(file.path(DATA_DIR, "narok_county.shp"), quiet = TRUE)

# =============================================================================
# 2. Survey Ingestion and Vector Cleaning
# =============================================================================
survey_raw <- read.csv(file.path(DATA_DIR, "Survey_data.csv"), check.names = FALSE, stringsAsFactors = FALSE)
households_combined <- survey_raw %>% 
  dplyr::select("Respondent.ID", "x", "y" ) %>% 
  dplyr::mutate(rn = row_number()) # Secure matching identifier indices
households_sf <- sf::st_as_sf(households_combined, coords = c("x", "y"), crs = 4326)

# =============================================================================
# 3. Dynamic Raster Ingestion and Metric Extraction Loop
# =============================================================================

# Metadata lookup mapping grid files to targeted metric variables
raster_configs <- list(
  one_season = list(path = "One_Season_Precip_1982_2020.tif",   label = "Single season"),
  long_rains = list(path = "Long_Season_Precip_1982_2020.tif",   label = "LR season"),
  short_rains = list(path = "Short_Season_Precip_1982_2020.tif", label = "SR season")
)

compiled_anomalies <- data.frame()

cfg_key <- 'long_rains'
for (cfg_key in names(raster_configs)) {
  cfg <- raster_configs[[cfg_key]]
  
  # Load and crop spatial layers using terra
  grid_stack <- terra::rast(file.path(PROCESSED, 'raingAvgs', cfg$path)) %>% terra::crop(narok_county)
  
  # Bilinear cell value extraction mapped across survey locations
  extracted_vals <- terra::extract(grid_stack, households_sf, method = "bilinear") %>%
    dplyr::select(-ID) # Remove default terra lookup ID column
  
  colnames(extracted_vals) <- as.character(1982:(1982 + ncol(extracted_vals) - 1))
  
  # Structural conversion into long-format tidy dataframes
  tidy_anomalies <- cbind(households_combined, extracted_vals) %>%
    tidyr::pivot_longer(cols = matches("^\\d{4}$"), names_to = "Year", values_to = "Raw_Value") %>%
    dplyr::mutate(
      Year   = as.numeric(Year),
      Metric = cfg$label
    ) %>%
    # Calculate localized rolling window means (k = 5) grouped by household row
    dplyr::group_by(rn) %>%
    dplyr::arrange(desc(Year)) %>%
    dplyr::mutate(runMn = zoo::rollmean(Raw_Value, k = 5, fill = NA, align = "left")) %>%
    dplyr::ungroup()
  
  compiled_anomalies <- rbind(compiled_anomalies, tidy_anomalies)
}

# =============================================================================
# 4. Processing Hydrological Julian Date Timings
# =============================================================================
timing_files <- list.files(path = file.path(PROCESSED, "rainTiming"), pattern = "annual", full.names = TRUE)

timing_configs <- list(
  onset       = list(layer = terra::rast(timing_files[4]), label = "Onset",       offset_days = 365,   shift_val = 365, threshold = 200),
  cessation   = list(layer = terra::rast(timing_files[1]), label = "Cessation",   offset_days = 0,   shift_val = 0,   threshold = Inf),
  lr_onset    = list(layer = terra::rast(timing_files[3]), label = "LR onset",    offset_days = 0,   shift_val = 0,   threshold = Inf),
  lr_cessation= list(layer = terra::rast(timing_files[2]), label = "LR cessation", offset_days = 0,   shift_val = 0,   threshold = Inf),
  sr_onset    = list(layer = terra::rast(timing_files[7]), label = "SR onset",    offset_days = 365,   shift_val = 365, threshold = 200),
  sr_cessation= list(layer = terra::rast(timing_files[5]), label = "SR cessation", offset_days = 365, shift_val = 365, threshold = 280)
)

compiled_timings <- data.frame()

for (t_key in names(timing_configs)) {
  t_cfg <- timing_configs[[t_key]]
  
  grid_stack <- terra::crop(t_cfg$layer, narok_county)
  
  # Adjust cross-year Julian thresholds to maintain slope direction stability
  if (t_cfg$threshold != Inf) {
    for (i in 1:terra::nlyr(grid_stack)) {
      layer_vals <- grid_stack[[i]]
      layer_vals[layer_vals < t_cfg$threshold] <- layer_vals[layer_vals < t_cfg$threshold] + t_cfg$offset_days
      grid_stack[[i]] <- layer_vals
    }
  }
  
  extracted_timings <- terra::extract(grid_stack, households_sf, method = "bilinear") %>% dplyr::select(-ID)
  colnames(extracted_timings) <- as.character(1982:(1982 + ncol(extracted_timings) - 1))
  
  tidy_timings <- cbind(households_combined, extracted_timings) %>%
    tidyr::pivot_longer(cols = matches("^\\d{4}$"), names_to = "Year", values_to = "Julian_Date") %>%
    dplyr::mutate(
      Year   = as.numeric(Year),
      Metric = t_cfg$label
    ) %>%
    dplyr::group_by(rn) %>%
    dplyr::arrange(desc(Year)) %>%
    dplyr::mutate(runMn = zoo::rollmean(Julian_Date, k = 5, fill = NA, align = "left")) %>%
    dplyr::ungroup()
  
  compiled_timings <- rbind(compiled_timings, tidy_timings)
}

# =============================================================================
# 5. Core Data Visualization Engine (ggplot2 Layout Modules)
# =============================================================================

# Global presentation theme template
theme_anomalies <- function() {
  theme_bw(base_size = 12) +
    theme(
      text               = element_text(family = "Cambria"),
      strip.background   = element_blank(),
      strip.text         = element_text(size = 14, face = "bold", color = "black"),
      axis.text.x        = element_text(color = "black", size = 11, angle = 40, vjust = 1, hjust = 1),
      axis.text.y        = element_text(color = "black", size = 11),
      axis.title.y       = element_text(size = 12, face = "bold", margin = margin(r = 10)),
      panel.grid.minor   = element_blank(),
      panel.grid.major   = element_line(linewidth = 0.3, color = "grey90"),
      plot.title         = element_blank(),
      plot.margin        = margin(t = 2, r = 5, b = 2, l = 5)
    )
}

# Sub-plot Generator Function for Code Reusability
build_gam_panel <- function(data, target_metric, label_tag, y_label, is_anomaly = FALSE, y_limits = NULL, y_breaks = NULL, y_labels = NULL) {
  
  panel_data <- data %>% dplyr::filter(Metric == target_metric)
  
  p <- ggplot(panel_data, aes(x = Year, y = if (is_anomaly) scale(Raw_Value) else Julian_Date)) +
    geom_line(aes(group = rn), color = "grey85", linewidth = 0.5, show.legend = FALSE) +
    geom_smooth(method = "gam", formula = y ~ s(x, bs = "cs", fx = TRUE, k = 25), se = TRUE, color = "black", fill = "grey70", alpha = 0.5) +
    annotate("text", label = label_tag, x = 1982, y = if (is_anomaly) 2.6 else max(y_limits) * 0.95, size = 5, fontface = "bold", family = "Cambria", hjust = 0) +
    facet_wrap(~Metric) +
    scale_x_continuous(breaks = seq(1980, 2020, 5), limits = c(1980, 2020)) +
    labs(y = y_label, x = "") +
    theme_anomalies()
  
  if (!is_anomaly) {
    p <- p + scale_y_continuous(breaks = y_breaks, labels = y_labels) + coord_cartesian(ylim = y_limits)
  } else {
    p <- p + coord_cartesian(ylim = c(-2, 3))
  }
  
  return(p)
}

# Row 1: Standardized Precipitation Anomalies
p_anom_unimodal <- build_gam_panel(compiled_anomalies, "Single season", "(A)", "Standardized anomalies", is_anomaly = TRUE)
p_anom_lr       <- build_gam_panel(compiled_anomalies, "LR season",   "(B)", "Standardized anomalies", is_anomaly = TRUE)
p_anom_sr       <- build_gam_panel(compiled_anomalies, "SR season",  "(C)", "Standardized anomalies", is_anomaly = TRUE)

# Rows 2 & 3: Direct Julian Day Rainfall Timing Windows
p_time_onset  <- build_gam_panel(compiled_timings, "Onset",        "(D)", "Day of Year", y_limits = c(200, 600), y_breaks = seq(200, 600, 50), y_labels = c('200','250','300','350','45','95','145','195','245'))
p_time_lronst <- build_gam_panel(compiled_timings, "LR onset",     "(E)", "Day of Year", y_limits = c(25, 160),  y_breaks = seq(25, 160, 25),  y_labels = as.character(seq(25, 160, 25)))
p_time_sronst <- build_gam_panel(compiled_timings, "SR onset",     "(F)", "Day of Year", y_limits = c(200, 600), y_breaks = seq(200, 600, 50), y_labels = c('200','250','300','350','45','95','145','195','245'))
p_time_cess   <- build_gam_panel(compiled_timings, "Cessation",    "(G)", "Day of Year", y_limits = c(40, 220),  y_breaks = seq(40, 220, 30),  y_labels = as.character(seq(40, 220, 30)))
p_time_lrcess <- build_gam_panel(compiled_timings, "LR cessation", "(H)", "Day of Year", y_limits = c(80, 180),  y_breaks = seq(80, 180, 20),  y_labels = as.character(seq(80, 180, 20)))
p_time_srcess <- build_gam_panel(compiled_timings, "SR cessation", "(I)", "Day of Year", y_limits = c(280, 430), y_breaks = seq(280, 430, 50), y_labels = c('280', '330', '15', '65'))


gg <- compiled_timings %>% 
  filter(Metric  == 'SR onset')
# =============================================================================
# 6. Matrix Patchwork Grid Compositing & Export
# =============================================================================
# Combine panels cleanly across a 3x3 matrix layout using Patchwork syntax

final_composite_grid=gridExtra::grid.arrange(p_anom_unimodal , p_anom_lr , p_anom_sr,
  p_time_onset    , p_time_lronst , p_time_sronst,
  p_time_cess     , p_time_lrcess , p_time_srcess, ncol=3)


export_path <- file.path(OUTPUT_FIGS, "Fig_SeasonRainAnnoms.tiff")

ggsave(
  filename    = export_path, 
  plot        = final_composite_grid,
  units       = "px",  width       = 4600,
  height      = 4600, 
  dpi         = 600,
  compression = "lzw" # LZW compression preserves sharp GAM confidence lines without file bloating
)

