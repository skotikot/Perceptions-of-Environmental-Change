#' -----------------------------------------------------------------------------
#' Project: Perceptions of change
#' Script: Perceptions Ordination (NMDS) Plotting Pipeline
#' Author: Kotikot et al.
#' Date: May 2026
#' -----------------------------------------------------------------------------
#' Purpose:
#' Read post-processed socio-ecological perception matrices, execute Non-Metric 
#' Multidimensional Scaling (NMDS) via `vegan`, rotate configurations against target 
#' vectors, and build a unified 4-panel multi-variate diagnostic grid.
#' -----------------------------------------------------------------------------

# =============================================================================
# 0. Load Required Libraries
# =============================================================================
library(tidyverse)      # Loads core dplyr, tidyr, and ggplot2 structures
library(vegan)          # Advanced community ecology ordination engine
library(ggord)          # ggplot layer wrapper for ordination objects
library(cowplot)        # Publication-grade grid layout compositor

# =============================================================================
# 1. Parameterize File Paths & Metadata Lookups
# =============================================================================
PROCESSED_DIR <- "../Data/Processed/SurveyData"
OUTPUT_DIR    <- "../Data/Figures"

# Named vector to convert experience categories to double numeric indices safely
yrs_income_lookup <- c(
  "< 10"    = 1,
  "11 - 20" = 2,
  "21 - 30" = 3,
  "31 - 40" = 4,
  "> 40"    = 5
)

# =============================================================================
# 2. Modular Data Preparation Helper Function
# =============================================================================

#' Prepare Data Matrix for NMDS Analysis
#' @param file_path Character string directing to target csv source.
#' @param active_cols Vector of strings indicating target evaluation metrics.
#' @param matrix_cols Columns to compress down to numeric indices for vegan.
#' @return A list containing the clean metadata frame and matched numeric matrix.
prepare_ordination_data <- function(file_path, active_cols, matrix_cols) {
  raw_df <- read_csv(file_path, show_col_types = FALSE)
  
  # Filter, clean out corrupted text bits, and normalize numeric index layers
  metadata_df <- raw_df %>%
    dplyr::select(all_of(active_cols)) %>%
    dplyr::mutate(
      yrs_income2 = dplyr::recode(as.character(yrs_income), !!!yrs_income_lookup, .default = NA_real_),
      
      # FIXED: Uses an if_else conditional that only executes if rainC exists in the active selection
      rainC = if ("rainC" %in% colnames(.)) {
        if_else(rainC %in% c("Other\u0085", "Other…", "Other\x85"), NA_character_, rainC)
      } else {
        NULL # Safely ignores if the column is absent from active_cols
      }
    ) %>%
    na.omit()
  
  # Coerce matrix items to clean integers for metric analysis loops
  numeric_matrix <- metadata_df %>%
    dplyr::select(all_of(matrix_cols)) %>%
    lapply(function(x) as.numeric(as.factor(x))) %>%
    as.data.frame()
  
  return(list(meta = metadata_df, mat = numeric_matrix))
}

# =============================================================================
# 3. Execution Loops & Panel Compilations
# =============================================================================
print("Executing multi-variate NMDS configurations...")

# Vector labels dictionaries used across axis outputs
labs_panel_ab <- list(income = 'Income.source', rainC = 'Perceptions', moist = 'Agroclimatic.zone', yrs_income2 = 'Years.in.occupation')
labs_panel_b  <- list(income = 'Income.source', rainV = 'Perceptions', moist = 'Agroclimatic.zone', yrs_income2 = 'Years.in.occupation')
labs_panel_c  <- list(rainC = 'Rain.perceptions', moist = 'Agroclimatic.zone', yrs_income2 = 'Years.in.occupation', ylds = 'Change.in.Yields')
labs_panel_d  <- list(rainC = 'Perceptions.rain', moist = 'Agroclimatic.zone', yrs_income2 = 'Years.in.occupation', pstDeg = 'Pasture.Degradation', drtCh = 'Drought')

# Palette mappings
colors_base   <- c('Decrease' = 'indianred', 'Increase' = 'olivedrab3', 'No change' = 'grey50', 'Variable' = 'orange')

# -----------------------------------------------------------------------------
# Panel A: Rainfall Amount and Income Source
# -----------------------------------------------------------------------------
p_a_data <- prepare_ordination_data(
  file_path   = file.path(PROCESSED_DIR, "ordData_allRain.csv"),
  active_cols = c('rainC', 'rainV', 'income', 'yrs_income', 'moist', 'Gender', 'tenure'),
  matrix_cols = c('income', 'rainC', 'moist', 'yrs_income2')
)

ord_a     <- vegan::metaMDS(p_a_data$mat, distance = "bray", autotransform = FALSE, trace = 0)
ord_rot_a <- vegan::MDSrotate(ord_a, p_a_data$meta$income)

gg_a <- ggord(ord_rot_a, p_a_data$meta$rainC, obslab = FALSE, poly = FALSE, vec_lab = labs_panel_ab, sizelab = 10, txt = 4, xlims = c(-0.80, 0.80), ylims = c(-0.60, 0.60))
gg_a$layers[[1]] <- NULL # Strip background layer placeholder

rainAmt <- gg_a + 
  geom_point(data = p_a_data$mat, aes(x = ord_rot_a$points[,1], y = ord_rot_a$points[,2], shape = as.factor(p_a_data$meta$income), colour = as.factor(p_a_data$meta$rainC)), size = 4, alpha = 1) +
  scale_shape_manual(values = c(16, 17), labels = c('Crop farmer', 'Pastoralist')) +
  scale_color_manual(values = colors_base, labels = c('Decrease', 'Increase', 'No change', 'Variable')) +
  annotate("text", x = -0.73, y = 0.55, label = "A)", fontface = "bold", family = "Cambria", size = 6) +
  theme_minimal(base_size = 12) + theme(legend.title = element_blank(), panel.border = element_rect(colour = "black", fill = NA))

# -----------------------------------------------------------------------------
# Panel B: Rainfall Variability and Income Source
# -----------------------------------------------------------------------------
p_b_data <- prepare_ordination_data(
  file_path   = file.path(PROCESSED_DIR, "ordData_allRain.csv"),
  active_cols = c('rainV', 'income', 'moist', 'yrs_income'),
  matrix_cols = c('income', 'rainV', 'moist', 'yrs_income2')
)

ord_b     <- vegan::metaMDS(p_b_data$mat, distance = "bray", autotransform = FALSE, trace = 0)
ord_rot_b <- vegan::MDSrotate(ord_b, p_b_data$meta$income)

gg_b <- ggord(ord_rot_b, p_b_data$meta$rainV, obslab = FALSE, poly = FALSE, vec_lab = labs_panel_b, sizelab = 10, txt = 4, xlims = c(-0.75, 0.75), ylims = c(-0.60, 0.60))
gg_b$layers[[1]] <- NULL

colors_var <- c('indianred', 'olivedrab3', 'orange', 'purple2', 'skyblue', 'grey50')
labels_var <- c('EO, EE', 'LO, EE', 'EO', 'EO, LE', 'LO, LE', 'LO')

rainVar <- gg_b + 
  geom_point(data = p_b_data$mat, aes(x = ord_rot_b$points[,1], y = ord_rot_b$points[,2], shape = as.factor(p_b_data$meta$income), colour = as.factor(p_b_data$meta$rainV)), size = 4, alpha = 1) +
  scale_shape_manual(values = c(16, 17), labels = c('Crop farmer', 'Pastoralist')) +
  scale_color_manual(values = colors_var, labels = labels_var) +
  annotate("text", x = -0.68, y = 0.55, label = "B)", fontface = "bold", family = "Cambria", size = 6) +
  theme_minimal(base_size = 12) + theme(legend.title = element_blank(), panel.border = element_rect(colour = "black", fill = NA))

# -----------------------------------------------------------------------------
# Panel C: Rainfall Amount and Crop Yield
# -----------------------------------------------------------------------------
p_c_data <- prepare_ordination_data(
  file_path   = file.path(PROCESSED_DIR, "ordData5_farmersCropYld.csv"),
  active_cols = c('rainC', 'rainV', 'income', 'yrs_income', 'moist', 'Gender', 'tenure', 'livs', 'ylds'),
  matrix_cols = c('rainC', 'moist', 'yrs_income2', 'livs', 'ylds')
)

ord_c     <- vegan::metaMDS(p_c_data$mat, distance = "bray", autotransform = FALSE, trace = 0)
ord_rot_c <- vegan::MDSrotate(ord_c, p_c_data$meta$ylds)

gg_c <- ggord(ord_rot_c, p_c_data$meta$rainC, obslab = FALSE, poly = FALSE, vec_lab = labs_panel_c, sizelab = 10, txt = 4, xlims = c(-0.65, 0.55), ylims = c(-0.55, 0.55))
gg_c$layers[[1]] <- NULL

crpp <- gg_c + 
  geom_point(data = p_c_data$mat, aes(x = ord_rot_c$points[,1], y = ord_rot_c$points[,2], shape = as.factor(p_c_data$meta$ylds), colour = as.factor(p_c_data$meta$rainC)), size = 4, alpha = 1) +
  scale_shape_manual(values = c(16, 17, 15), labels = c('Decreased', 'Increased', 'No change')) +
  scale_color_manual(values = colors_base, labels = c('Decrease', 'Increase', 'No change', 'Variable')) +
  annotate("text", x = -0.58, y = 0.52, label = "C)", fontface = "bold", family = "Cambria", size = 6) +
  theme_minimal(base_size = 12) + theme(legend.title = element_blank(), panel.border = element_rect(colour = "black", fill = NA))

# -----------------------------------------------------------------------------
# Panel D: Rainfall Amount and Pasture Productivity
# -----------------------------------------------------------------------------
p_d_data <- prepare_ordination_data(
  file_path   = file.path(PROCESSED_DIR, "ordData6_LivsPastYld.csv"),
  active_cols = c('rainC', 'rainV', 'income', 'yrs_income', 'moist', 'Gender', 'tenure', 'landArea', 'pstDeg', 'TempPer_wat', 'drtCh', 'lulcGraz'),
  matrix_cols = c('rainC', 'moist', 'yrs_income2', 'pstDeg', 'drtCh')
)

ord_d     <- vegan::metaMDS(p_d_data$mat, distance = "bray", autotransform = FALSE, trace = 0)
ord_rot_d <- vegan::MDSrotate(ord_d, p_d_data$meta$pstDeg)

gg_d <- ggord(ord_rot_d, p_d_data$meta$rainC, obslab = FALSE, poly = FALSE, vec_lab = labs_panel_d, sizelab = 10, txt = 4, xlims = c(-0.42, 0.65), ylims = c(-0.6, 0.55))
gg_d$layers[[1]] <- NULL

past <- gg_d + 
  geom_point(data = p_d_data$mat, aes(x = ord_rot_d$points[,1], y = ord_rot_d$points[,2], shape = as.factor(p_d_data$meta$pstDeg), colour = as.factor(p_d_data$meta$rainC)), size = 4, alpha = 1) +
  scale_shape_manual(values = c(16, 17), labels = c('Increased', 'Decreased')) +
  scale_color_manual(values = c('indianred', 'olivedrab3',  'orange'),
                     labels = c('Decrease', 'Increase','Variable')) +
  annotate("text", x = -0.34, y = 0.50, label = "D)", fontface = "bold", family = "Cambria", size = 6) +
  theme_minimal(base_size = 12) + theme(legend.title = element_blank(), panel.border = element_rect(colour = "black", fill = NA))

# =============================================================================
# 4. Canvas Arrangement & Matrix Export
# =============================================================================

composite_grid <- cowplot::plot_grid(rainAmt, rainVar, crpp, past, align = "h", nrow = 2)

export_filename <- file.path(OUTPUT_DIR, "ordinationPlots_ComparativeComposite.tiff")

ggsave(
  filename    = export_filename, 
  plot        = composite_grid, 
  units       = "px", 
  width       = 5700, 
  height      = 4750, 
  dpi         = 600, 
  compression = "lzw" # LZW compression protects repository file allocations
)

