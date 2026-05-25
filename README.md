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
