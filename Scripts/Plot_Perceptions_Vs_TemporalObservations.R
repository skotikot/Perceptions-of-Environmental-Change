# =============================================================================
# Project: Perceptions of change
# Purpose: Extract Multi-Temporal Rainfall Season Anomalies and Generate Perceptions Heatmap
# Author: Kotikot et al.
# Date: May 2026
# =============================================================================

# -----------------------------------------------------------------------------
# 0. Load Required Libraries
# -----------------------------------------------------------------------------
library(sf)           # Modern vector data handling 
library(terra)        # High-performance spatial raster computing engine
library(dplyr)        # Structured data wrangling ecosystem
library(data.table)   # Optimized data frame extensions
library(ComplexHeatmap)
library(circlize)     # Color mapping configuration engine
library(grid)

# -----------------------------------------------------------------------------
# 1. Parameterize Configuration & Working Paths
# -----------------------------------------------------------------------------
DATA_DIR1  <- "../Data/Raw"
DATA_DIR2  <- "../Data/Processed/raingAvgs"
OUTPUT_DIR <- "../Data/Figures"

if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

# Read spatial boundary layer (administrative boundary mask)
narok <- sf::st_read(file.path(DATA_DIR1, "narok_county.shp"), quiet = TRUE)

# -----------------------------------------------------------------------------
# 2. Ingest Household Survey Data & Geospatial Coordinate Registry
# -----------------------------------------------------------------------------
survey_raw <- read.csv(file.path(DATA_DIR1, "Survey_data.csv"), check.names = FALSE, stringsAsFactors = FALSE)

# Isolate spatial location and inject uniform unique key identifiers
households_combined <- survey_raw %>% 
  dplyr::select(x, y, income, dat) %>% 
  dplyr::mutate(rn = row_number())

# Convert table to Simple Features object using geographic CRS coordinate keys
datCombined.sf <- sf::st_as_sf(households_combined, coords = c("x", "y"), crs = 4326)

# -----------------------------------------------------------------------------
# 3. Spatial Raster Extraction Engine (Multi-Seasonal Rainfall Ingestion)
# -----------------------------------------------------------------------------
# Spatially crop multi-layer time-series rasters directly via terra
oneR <- terra::crop(terra::rast(file.path(DATA_DIR2, 'One_Season_Precip_1982_2020.tif')), narok)
LR   <- terra::crop(terra::rast(file.path(DATA_DIR2, 'Long_Season_Precip_1982_2020.tif')), narok)
SR   <- terra::crop(terra::rast(file.path(DATA_DIR2, 'Short_Season_Precip_1982_2020.tif')), narok)

# Extract cell point values intersecting survey locations across timeline (1982-2019)
# terra::extract returns a dataframe with an 'ID' column as its first column
onsetVals     <- terra::extract(oneR, datCombined.sf, method = 'bilinear', fun = 'mean')[, -1]
cessationVals <- terra::extract(LR, datCombined.sf, method = 'bilinear', fun = 'mean')[, -1]
LonsetVals    <- terra::extract(SR, datCombined.sf, method = 'bilinear', fun = 'mean')[, -1]

# Assign matching year names to extracted matrices
year_labels <- paste0("y_", 1982:2019)
colnames(onsetVals)     <- year_labels
colnames(cessationVals) <- year_labels
colnames(LonsetVals)    <- year_labels

# Re-bind spatial identifiers back to extracted numerical data matrices
rainPatTrend_onset     <- cbind(households_combined, onsetVals)
rainPatTrend_cessation <- cbind(households_combined, cessationVals)
rainPatTrend_Lonset    <- cbind(households_combined, LonsetVals)

# Assign structural markers to differentiate seasonal tracking categories
rainPatTrend_onset$metric     <- 'One season'
rainPatTrend_cessation$metric <- 'Long season'
rainPatTrend_Lonset$metric    <- 'Short season'

# Bind all configurations into unified multi-seasonal tracking table
rainPatTrend <- rbind(rainPatTrend_onset, rainPatTrend_cessation, rainPatTrend_Lonset)

# -----------------------------------------------------------------------------
# 4. Data Cleaning & Perception Matrix Transformations
# -----------------------------------------------------------------------------
# Harmonize survey categorical response codes
rainPatTrend <- rainPatTrend %>%
  dplyr::mutate(dat = case_when(
    dat == "Variable (unstable patterns)" ~ "More variable",
    dat == "None (no changes)"           ~ "No change",
    dat == "Decrease"                    ~ "Decreased",
    dat == "Increase"                    ~ "Increased",
    TRUE                                 ~ as.character(dat)
  )) %>%
  # Filter out missing records and specific baseline encoding anomalies
  dplyr::filter(!dat %in% c("Other…", "Other\x85")) %>%
  dplyr::filter(!is.na(y_1982))

# Isolate target sub-population profile: Household Perceptions tracking Decreased Long Season rains
rainPatTrend_filtered <- rainPatTrend %>% 
  dplyr::filter(metric == "Long season" & dat == "Decreased")

# -----------------------------------------------------------------------------
# 5. Extract Values & Prepare Input Arrays for Heatmap Formatting
# -----------------------------------------------------------------------------
# Dynamically extract timeline values based on structural column names
dataSamp <- rainPatTrend_filtered %>% dplyr::select(all_of(year_labels))

# Clean column headers and index names for presentation plotting
colnames(dataSamp) <- as.character(1982:2019)
rownames(dataSamp) <- paste0("HH ", seq_len(nrow(dataSamp)))
rownames(dataSamp) <- NULL

# Scale data: Transpose, calculate Z-scores, then transpose back to format
# standard columns as years and rows as individual households
data.heatmap <- scale(t(dataSamp))

# Define color breaks mapping to Z-Score standard deviations
col_fun = colorRamp2(c(-4, 0, 4), c("red", "white", "blue"))

# -----------------------------------------------------------------------------
# 6. Render High-Resolution ComplexHeatmap Output Canvas
# -----------------------------------------------------------------------------
export_file <- file.path(OUTPUT_DIR, "Fig_rainZscores_heatMap.png")

png(export_file, width = 9.25, height = 2.75, units = "in", res = 600)

heatmap_panel <- Heatmap(
  matrix               = t(data.heatmap),
  col                  = col_fun,
  heatmap_legend_param = list(
    title          = "Standardized anomalies", 
    fontsize       = 18, 
    direction      = "vertical", 
    legend_width   = unit(3, "cm"),
    legend_length  = unit(50, "cm"), 
    labels_gp      = gpar(fontsize = 14), 
    title_position = "leftcenter-rot",
    title_gp       = gpar(fontsize = 14)
  ),
  row_dend_side        = "left",
  column_dend_side     = "top",
  cluster_rows         = FALSE,
  cluster_columns      = FALSE,
  row_names_gp         = gpar(fontsize = 18)
)

# Draw layout array canvas and serialize output plot to disk
draw(heatmap_panel, heatmap_legend_side = "right", show_annotation_legend = TRUE)
dev.off()

