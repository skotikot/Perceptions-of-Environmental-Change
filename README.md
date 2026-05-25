# Heterogeneous Perceptions of Rainfall Patterns Among Agropastoral Land Users in Sub-Saharan Africa

This repository contains the replication code and processing pipelines for the spatio-temporal socio-ecological data analysis featured in **Kotikot et al. (2025), Annals of the American Association of Geographers**. 

The code provided here integrates household survey microdata with multi-temporal gridded remote sensing precipitation stacks and vegetation phenometrics to examine the disparities between localized environmental realities and community perceptions of change.

---

## Directory Structure

To run the analysis scripts successfully, organize your local project root folder (`/`) using the structure below. Ground-truth tabular data, spatial boundary shapefiles, and gridded rasters should be retrieved from the accompanying **Zenodo Dataset** and unzipped into the `/Data` directory before execution.

```tree

├── Scripts/
│   ├── cal_plot_NMDS.R                           # Socio-ecological perception Ordination (NMDS) plotting pipeline
│   ├── calc_plot_TIEVI_senSlope.R                # Phenometrics trend calculation (Mann-Kendall & Sen's Slope)
│   ├── Plot_Perceptions_Vs_TemporalObservations.R# Multi-seasonal rainfall anomaly extraction & household heatmap
│   ├── Plot_PerceptionsProps.R                   # Community perceptions proportional multi-panel charts
│   └── plot_seasonRainAnnom.R                    # Julian calendar onset/cessation trends and GAM smoothing
│
├── Data/
│   ├── Raw/
│   │   ├── narok_county.shp                      # Administrative boundary shapefile (spatial mask)
│   │   ├── Survey_data.csv                       # Master household registry mapping coordinates (x, y)
│   │   └── Narok_FieldWork_data_cleaned_18May2022_.csv # Formatted baseline socio-ecological survey table
│   │
│   └── Processed/
│       ├── SurveyData/
│       │   ├── Perceptions_props.csv             # Proportion tables broken down by categorical environmental metrics
│       │   └── ordData_allRain.csv               # Processed perception response matrix for multivariate scaling
│       │
│       ├── raingAvgs/
│       │   ├── One_Season_Precip_1982_2020.tif   # Multi-temporal gridded rainfall stack: Unimodal regime
│       │   ├── Long_Season_Precip_1982_2020.tif  # Multi-temporal gridded rainfall stack: Long Rains
│       │   └── Short_Season_Precip_1982_2020.tif # Multi-temporal gridded rainfall stack: Short Rains
│       │
│       ├── Phenometrics/
│       │   ├── PhenoStack_interp_1R.*.gri/.grd   # Raster pheno-stacks (Onset/Offset/GS/TINDVI) - Unimodal
│       │   ├── PhenoStack_interp_LR.*.gri/.grd   # Raster pheno-stacks (Onset/Offset/GS/TINDVI) - Long Rains
│       │   └── PhenoStack_interp_SR.*.gri/.grd   # Raster pheno-stacks (Onset/Offset/GS/TINDVI) - Short Rains
│       │
│       └── rainTiming/
│           └── *annual*.tif                      # Localized Julian day historical onset and cessation layers
│
└── Outputs/
    ├── Analysis_Outputs/                         # Statistical summary layers and pixel trend matrices
    └── Figures/                                  # High-resolution, publication-ready visualization exports
```

## Script Breakdown & Execution Pipeline

- `Plot_PerceptionsProps.R`
Purpose: Generates charts mapping local community responses concerning rainfall amount, shifting variance structures, and agricultural yield impacts using ggpattern.
Expected Input: Data/Processed/SurveyData/Perceptions_props.csv
Output: Data/Figures/Fig_PerceptionsProps.tiff

- `cal_plot_NMDS.R`
Purpose: Compels community data into multidimensional distance matrices using Bray-Curtis indices via vegan::metaMDS. Rotates configuration coordinates against household income targets to plot a unified 4-panel diagnostic grid.
Expected Input: Data/Processed/SurveyData/ordData_allRain.csv
Output: Multivariate diagnostic ordination plots.

- `plot_seasonRainAnnom.R`
Purpose: Extracts pixel-level rainfall histories corresponding to georeferenced survey coordinates using bilinear interpolation. Employs 5-year rolling windows to plot regional onset/cessation shifts.
Expected Input: Data/Raw/, Data/Processed/raingAvgs/, and Data/Processed/rainTiming/
Output: Integrated 3x3 temporal anomalies composite grid.

- `Plot_Perceptions_Vs_TemporalObservations.R`
Purpose: Builds complex heatmaps evaluating households' micro-climatic Z-score anomalies side-by-side with subjective personal reporting arrays.Expected Input: Data/Raw/Survey_data.csv, Data/Processed/raingAvgs/*.tifOutput: Data/Figures/Fig_rainZscores_heatMap.png

- `calc_plot_TIEVI_senSlope.R`
Purpose: Iterates over multi-decade pixel grids to run pixel-wise non-parametric time series tests. Masks out change trends where significance levels fall outside $p \le 0.1$, returning geographical maps of landscape change.Expected Input: Data/Processed/Phenometrics/Output: Data/Figures/Fig_TI_EVI_SensSlope_Trends.tiff
