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
│   └── plot_seasonRainAnnom.R                    # Julian calendar onset/cessation trends
│
├── Data/
│   ├── Raw/
│   │   ├── narok_county.shp                      # Administrative boundary shapefile (spatial mask)
│   │   ├── Survey_data.csv                       # Master household registry mapping coordinates (x, y)
│   │   └── Narok_FieldWork_data_cleaned_18May2022_.csv # Formatted baseline socio-ecological survey table
│   │
    ├── Analysis_Outputs/                         # Statistical summary layers and pixel trend matrices
│   └── Processed/
│       ├── SurveyData/
│       │   ├── Perceptions_props.csv             # Proportion tables broken down by categorical environmental metrics - summerized survey data for visualizing proportions among responses
│       │   └── ordData_*.csv                     # Processed perception response matrix for multivariate scaling
│       │
│       ├── raingAvgs/
│       │   ├── One_Season_Precip_1982_2020.tif   # Multi-temporal gridded rainfall stack: Unimodal regime - seasonal rainfall average
│       │   ├── Long_Season_Precip_1982_2020.tif  # Multi-temporal gridded rainfall stack: Long Rains - seasonal rainfall average
│       │   └── Short_Season_Precip_1982_2020.tif # Multi-temporal gridded rainfall stack: Short Rains - seasonal rainfall average
│       │
│       ├── Phenometrics/
│       │   ├── PhenoStack_interp_1R.*.gri/.grd   # Raster pheno-stacks (Onset/Offset/GS/TINDVI) - Unimodal
│       │   ├── PhenoStack_interp_LR.*.gri/.grd   # Raster pheno-stacks (Onset/Offset/GS/TINDVI) - Long Rains
│       │   └── PhenoStack_interp_SR.*.gri/.grd   # Raster pheno-stacks (Onset/Offset/GS/TINDVI) - Short Rains
│       │
│       └── rainTiming/
           └── *annual*.tif                      # Localized Julian day historical onset and cessation layers

```

## Script Breakdown & Execution Pipeline

- `Plot_PerceptionsProps.R`
Purpose: Generates charts mapping local community responses concerning rainfall amount, shifting variance structures, and agricultural yield impacts using ggpattern.

- `cal_plot_NMDS.R`
Purpose: Compels community data into multidimensional distance matrices using Bray-Curtis indices via `vegan::metaMDS`. Rotates configuration coordinates against household income targets to plot a unified 4-panel comparative grid.

- `plot_seasonRainAnnom.R`
Purpose: Extracts pixel-level rainfall histories corresponding to georeferenced survey coordinates using bilinear interpolation. Plots regional anomalies, and onset/cessation shifts.

- `Plot_Perceptions_Vs_TemporalObservations.R`
Purpose: Builds complex heatmaps evaluating households' micro-climatic Z-score anomalies side-by-side with subjective personal reporting arrays.

- `calc_plot_TIEVI_senSlope.R`
Purpose: Iterates over multi-decade pixel grids to run pixel-wise non-parametric time series tests. Masks out change trends where significance levels fall outside $p \le 0.1$, returning geographical maps of landscape change.

## Data Source & Citation

### Associated Zenodo Dataset

**Dataset Title:** Data for: Heterogeneous Perceptions of Rainfall Patterns Among Agropastoral Land Users in Sub-Saharan Africa

DOI: [Insert Zenodo DOI here upon completion of deposit]

Note: Please ensure the unpacked asset structures map precisely onto the directory layouts documented above to avoid working-directory pathway breaks.

## Manuscript Citation

If you use these scripts or data pipelines in your academic work, please cite the original publication:

Kotikot, S. M., Smithwick, E. A. H., Nankaya, R., Gergel, S., Zimmerer, K. S., & Abila, R. (2025). Heterogeneous Perceptions of Rainfall Patterns Among Agropastoral Land Users in Sub-Saharan Africa. Annals of the American Association of Geographers, 115(6), 1286–1308. DOI: 10.1080/24694452.2025.2482899
