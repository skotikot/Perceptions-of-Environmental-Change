#' -----------------------------------------------------------------------------
#' Project: Vegetation Stress (Productivity) Analysis
#' Script: Remote Sensing Phenometrics Spatiotemporal Trend Profiling
#' Author: Kotikot et al.
#' Date: May 2026
#' -----------------------------------------------------------------------------
#' Purpose:
#' Ingests multi-temporal raster time-series containing localized EVI/NDVI 
#' phenometrics across three distinct rainfall regimes (Unimodal, Long Rains, Short Rains). 
#' Computes pixel-wise Mann-Kendall trend tests and Sen's Slope indices, masks non-significant 
#' adjustments ($p > 0.1$), and generates divergent geographical maps.
#' -----------------------------------------------------------------------------

# =============================================================================
# 0. Load Required Libraries
# =============================================================================
library(sf)             # Modern Simple Features vector manipulation
library(raster)         # Spatiotemporal raster analysis core matrix handler
library(Kendall)        # Non-parametric Mann-Kendall trend calculations
library(wql)            # Contains Optimized Sen's Slope algorithms (mannKen)
library(ggplot2)        # Core data visualization layout
library(rasterVis)      # Specialized plotting extensions for raster objects
library(metR)           # Advanced thermodynamic and atmospheric plot wrappers

# =============================================================================
# 1. Environment Configurations & Directory Paths
# =============================================================================
SHPS_DIR   <- "../Data/Raw/"
DATA_DIR   <- "../Data/Processed/Phenometrics"
OUTPUT_DIR <- "../Data/Analysis_Outputs"
OUTPUT_FIGS <- "../Data/Figures"

# Read in boundary limits via Simple Features framework
narok_boundary <- sf::st_read(file.path(SHPS_DIR, "narok_county.shp"), quiet = TRUE)

# =============================================================================
# 2. Reusable Modular Ingestion Helper Function
# =============================================================================

#' Load and Deconstruct Phenological GRI Stacks
#' @param pattern Regex lookup string matching the target rainfall season profile.
#' @param directory Relative path directing the data query search.
#' @return A named list containing four separate multi-layer stacks.
load_pheno_stack <- function(pattern, directory) {
  target_files <- list.files(path = directory, pattern = pattern, full.names = TRUE)
  
  if (length(target_files) == 0) {
    stop(paste("Data error: No files matched pattern:", pattern))
  }
  
  # Initialize blank tracking list arrays
  ons_lst <- list(); ofs_lst <- list(); gs_lst  <- list(); evi_lst <- list()
  
  for (i in seq_along(target_files)) {
    metr <- raster::stack(target_files[i])
    
    ons_lst[[i]] <- metr$Onset_Time
    ofs_lst[[i]] <- metr$Offset_Time
    gs_lst[[i]]  <- metr$LengthGS
    evi_lst[[i]] <- metr$TINDVI
  }
  
  return(list(
    Onset  = raster::stack(ons_lst),
    Offset = raster::stack(ofs_lst),
    GS     = raster::stack(gs_lst),
    TINDVI = raster::stack(evi_lst)
  ))
}

# Ingest stacks dynamically across all targeted rainfall regimes
season_R  <- load_pheno_stack("PhenoStack_interp_1R.*.gri$",  DATA_DIR)#unimodal rainfall regime
season_LR <- load_pheno_stack("PhenoStack_interp_LR.*.gri$",  DATA_DIR)#Bi-modal rainfall regime - Long rains
season_SR <- load_pheno_stack("PhenoStack_interp_SR.*.gri$",  DATA_DIR)#Bi-modal rainfall regime - Short rains

# =============================================================================
# 3. Non-Parametric Trend Functions (Mann-Kendall & Sen's Slope)
# =============================================================================

# Pixel-wise Mann-Kendall evaluation function
fun_kendall <- function(x) {
  if (sum(!is.na(x)) <= 11) {
    return(rep(NA, 5)) 
  } else {
    return(unlist(Kendall::MannKendall(x)))
  }
}

# Pixel-wise Sen's Slope calculation function
fun_sens <- function(x) {
  if (sum(!is.na(x)) <= 11) {
    return(rep(NA, 6)) 
  } else {
    return(unlist(wql::mannKen(x)))
  }
}

# =============================================================================
# 4. Processing Pipeline Loop (Trend Calculations & Masking)
# =============================================================================
# Bind data matrices systematically into a continuous list structure
data_stacks <- list(
  season_R$Onset,   season_R$Offset,   season_R$GS,   season_R$TINDVI,
  season_LR$Onset,  season_LR$Offset,  season_LR$GS,  season_LR$TINDVI,
  season_SR$Onset,  season_SR$Offset,  season_SR$GS,  season_SR$TINDVI
)

layer_labels <- c(
  "Onset_Time", "Offset_Time", "LengthGS", "TINDVI",
  "LR Onset_Time", "LR Offset_Time", "LR LengthGS", "LR TINDVI",
  "SR Onset_Time", "SR Offset_Time", "SR LengthGS", "SR TINDVI"
)

all_slopes_list <- list()
sig_slopes_list <- list()

for (y in seq_along(data_stacks)) {
  current_stack <- data_stacks[[y]]
  
  # Run cell-wise Sen's slope models across stacked periods
  sen_output <- raster::calc(current_stack, fun = fun_sens)
  
  # Isolate p-values (Layer 3) and extract slope values (Layer 1)
  pval_layer <- sen_output$layer.3
  slope_layer <- sen_output$layer.1
  
  # Build strict significance mask layer (90% confidence threshold)
  pval_mask <- pval_layer
  pval_mask[pval_mask > 0.1] <- NA
  
  # Apply significance constraints to isolate targeted shifts
  sig_slope <- slope_layer
  sig_slope[is.na(pval_mask)] <- NA
  
  # Archive outputs to lists using assigned string keys
  all_slopes_list[[y]] <- slope_layer
  sig_slopes_list[[y]] <- sig_slope
  
  names(all_slopes_list)[y] <- paste0("Slope_", layer_labels[y])
  names(sig_slopes_list)[y] <- paste0("SigSlope_", layer_labels[y])
}

# Stack outputs into structural layers
slopes_stack     <- raster::stack(all_slopes_list)
sig_slopes_stack <- raster::stack(sig_slopes_list)

# Archive raster outputs locally onto the file system
# raster::writeRaster(slopes_stack,     filename = file.path(OUTPUT_DIR, "EVI_metric_Slopes.tif"),     overwrite = TRUE)
# raster::writeRaster(sig_slopes_stack, filename = file.path(OUTPUT_DIR, "EVI_metric_sig_Slopes_Final.tif"), overwrite = TRUE)

# =============================================================================
# 5. Data Visualization (ggplot2 Matrix) - Read in the archived outputs for plotting
# =============================================================================
# Isolate significant total integrated EVI values across all three seasons
# Explicitly uses name keys to safely secure layers instead of shifting numeric slices
sig_slopes_stack <- stack(paste0(DATA_DIR, "/EVI_metric_sig_Slopes.gri"))
visualization_stack <- sig_slopes_stack[[c("layer.1.4", "layer.1.8", "layer.1.12")]]

# Clamp values to uniform maximum limits to prevent out-of-bounds legend stretches
visualization_stack[visualization_stack > 0.1]  <- 0.1
visualization_stack[visualization_stack < -0.1] <- -0.1

# Structure clean map panel labels
map_panel_labels <- c(
  "layer.1.4"    = "TI EVI (Unimodal)",
  "layer.1.8" = "TI EVI (Long Rains)",
  "layer.1.12" = "TI EVI (Short Rains)"
)

# Render map output canvas using specialized gplot methods
pheno_trends_map <- rasterVis::gplot(visualization_stack) + 
  geom_tile(aes(fill = value)) +
  
  # Divide map outputs across 3 horizontal panels
  facet_wrap(~ variable, ncol = 3, labeller = as_labeller(map_panel_labels)) +
  
  # Overlay administrative boundaries natively from sf objects (Removes legacy sp dependency)
  geom_sf(data = narok_boundary, fill = "transparent", color = "grey30", linewidth = 0.4, inherit.aes = FALSE) +
  
  # Set divergent green-to-brown visualization parameters
  metR::scale_fill_divergent(
    midpoint  = 0, 
    low       = "brown4", 
    mid       = "white", 
    high      = "darkgreen", 
    limits    = c(-0.1, 0.1), 
    na.value  = "transparent"
  ) +
  coord_sf() +
  theme_bw(base_size = 14) +
  theme(
    text               = element_text(family = "Cambria"),
    strip.background   = element_blank(),
    strip.text         = element_text(size = 14, color = "black", face = "bold"),
    
    # Grid panel lines and tick cleanups
    panel.grid.major   = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.border       = element_blank(),
    axis.title         = element_blank(),
    axis.text          = element_blank(),
    axis.ticks         = element_blank(),
    
    # Legend formatting attributes (Bottom horizontal distribution alignment)
    legend.position    = "bottom",
    legend.title       = element_blank(),
    legend.text        = element_text(size = 11),
    legend.key.height  = unit(0.25, "cm"), 
    legend.key.width   = unit(1.8, "cm"),
    
    # Canvas properties
    plot.background    = element_rect(fill = "white", color = NA),
    panel.background   = element_rect(fill = "white", color = NA),
    plot.margin        = margin(t = 2, r = 2, b = 2, l = 2, unit = "mm")
  )
pheno_trends_map
# =============================================================================
# 6. High-Resolution Output File Export
# =============================================================================
export_img_path <- file.path(OUTPUT_DIR, "Fig_TI_EVI_SensSlope_Trends.tiff")

ggsave(
  filename    = export_img_path, 
  plot        = pheno_trends_map,
  units       = "px",
  width       = 3600,
  height      = 2400, 
  dpi         = 500,
  compression = "lzw" # LZW compression minimizes final repository footprint storage parameters
)

