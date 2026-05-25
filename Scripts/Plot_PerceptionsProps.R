#' -----------------------------------------------------------------------------
#' Project: Perceptions of change
#' Script: Community Environmental Perception Multi-Panel Plots
#' Author: Kotikot et al.
#' Date: May 2026
#' -----------------------------------------------------------------------------
#' Purpose:
#' Ingests survey results tracking historical local environmental perceptions,
#' breaks variables into targeted metric panels (Rainfall Amount, Rainfall 
#' Variability, and Yield Outcomes), maps monochrome structural texture grids via 
#' `ggpattern` and stitches panels horizontally.
#' -----------------------------------------------------------------------------

# =============================================================================
# 0. Load Required Libraries
# =============================================================================
library(tidyverse)   # Ingests core dplyr, tidyr, and ggplot2 engines
library(ggpattern)   # Allows geometric fill patterns (texture fills)
library(cowplot)     # Advanced grid canvas arrangement
library(scales)      # Pretty scale breaks parameters

# =============================================================================
# 1. Environment Configurations & Data Ingestion
# =============================================================================
DATA_PATH <- "../Data/Processed/SurveyData"
EXPORT_DIR <- "../Data/Figures"

fl_raw <- read.csv(file.path(DATA_PATH, "Perceptions_props.csv"), stringsAsFactors = FALSE)

# =============================================================================
# 2. Reusable Plot Theme Template (Publication Grade)
# =============================================================================
theme_perceptions <- function() {
  theme_bw(base_size = 14) +
    theme(
      text               = element_text(family = "Cambria"),
      plot.title         = element_text(size = 18, face = "bold", color = "black", margin = margin(b = 10)),
      axis.title.y       = element_text(face = "bold", size = 14, color = "black", margin = margin(r = 10)),
      axis.text.y        = element_text(face = "plain", size = 12, color = "black"),
      axis.text.x        = element_text(face = "plain", size = 12, color = "black"),
      axis.title.x       = element_blank(),
      strip.background   = element_rect(fill = "white", colour = "transparent"),
      strip.text         = element_text(size = 14, face = "bold"),
      panel.background   = element_rect(fill = "white"),
      panel.border       = element_rect(colour = "black", fill = NA, linewidth = 1),
      panel.grid.major   = element_line(linewidth = 0.4, linetype = "dotted", color = "grey70"),
      panel.grid.minor   = element_line(linewidth = 0.4, linetype = "dotted", color = "grey85"),
      legend.title       = element_blank(),
      legend.text        = element_text(size = 11),
      legend.key.size    = unit(0.8, 'cm'),
      legend.position    = "inside",
      legend.background  = element_rect(fill = "transparent", colour = "transparent"),
      plot.margin        = margin(t = 5, r = 5, b = 5, l = 5, unit = "mm")
    )
}

# Standardized baseline response labels for cleaner scales mapping
change_labels <- c("Decrease" = "Decrease", "Increase" = "Increase", "No change" = "No change", "Variable" = "Variable")

# =============================================================================
# 3. Panel A: Rainfall Amount (Standard Greyscale Bars)
# =============================================================================

dat1 <- fl_raw %>% dplyr::filter(Category == "Rainfall amount")

rainAmt <- ggplot(data = dat1, aes(x = Income, y = Value, fill = Change)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.3) +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 8), limits = c(0, 80)) +
  scale_fill_manual(values = c("grey30", "grey50", "grey70", "grey90"), labels = change_labels) +
  labs(title = "A) Rainfall amount", y = "Proportion of respondents (%)") +
  theme_perceptions() +
  theme(legend.position = c(0.22, 0.82))

# =============================================================================
# 4. Panel B: Rainfall Variability (ggpattern Textured Fills)
# =============================================================================

# Tidy pipeline step: Inject explicit fill definitions natively into the dataframe 
# to protect structural geometry alignment during grid compositions
dat2 <- fl_raw %>% 
  dplyr::filter(Category == "Rainfall variability") %>%
  dplyr::mutate(
    fill_color = if_else(Change == "No change & Late ending", "grey70", "white"),
    Change     = factor(Change)
  )



rainVar <- ggplot(data=dat2, aes(x=Income, y=Value))+
  geom_bar_pattern(
    aes(
      pattern = Change,
      pattern_angle = Change
    ),

    pattern_frequency = 9,
    
    fill            = c('white','white','white','white','grey70', 'white',
                        'white','white','white','white','grey70', 'white'), 
    colour          = 'black',
    pattern_spacing = 0.03,#0.005
    stat="identity",
    position="dodge"
  ) +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 8), limits = c(0,80)) +
  scale_pattern_manual(values = c("circle", "stripe", "none", "crosshatch", "none", "weave"))+
  guides(pattern = guide_legend(override.aes = list(fill = c('white','white','white','white','grey70', 'white'))),
         fill = guide_legend(override.aes = list(pattern = "none")))+
  ggtitle("B) Rainfall variability")+
  theme(axis.title=element_text(face = 'bold', size=20),
        axis.text.y = element_text(face = "plain", size=16, color='black'),
        axis.text.x = element_text(face = "plain", size=16, color='black', angle = 0, vjust = 0.5),
        plot.title = element_text(size = 24, face = "bold"),
        strip.text = element_text(size = 20, face='bold'),
        panel.background = element_rect(fill = "white"),
        strip.background = element_rect(fill = "white"),
        panel.grid.major = element_line(size = 0.4,linetype = "dotted",color="grey"),
        legend.title=element_blank(),
        legend.text=element_text(size=14),
        legend.key.size = unit(1, 'cm'),
        plot.margin=grid::unit(c(0,0,0,0), "mm"),
        legend.position = c(0.36, 0.8),
        panel.border = element_rect(colour = "black", fill=NA, size=1),
        panel.grid.minor = element_line(linetype = "dotted", size=0.4))+
  ylab(expression("")) +
  xlab("") 


# =============================================================================
# 5. Panel C: Crop and Pasture Yield Outcomes
# =============================================================================

dat3 <- fl_raw %>% dplyr::filter(Category == "Productivity")

crp <- ggplot(data = dat3, aes(x = Income, y = Value, fill = Change)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", linewidth = 0.3) +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 8), limits = c(0, 80)) +
  scale_fill_manual(values = c("grey30", "grey50", "grey70"), labels = change_labels) +
  labs(title = "C) Crop and pasture yield", y = "") +
  theme_perceptions() +
  theme(legend.position = c(0.22, 0.84))

# =============================================================================
# 6. Grid Layout Assembly & Figure Export
# =============================================================================

# Combine the three panels into a unified multi-plot horizontal matrix via cowplot
final_figure <- cowplot::plot_grid(rainAmt, rainVar, crp, align = "h", nrow = 1)

export_file <- file.path(EXPORT_DIR, "Fig_PerceptionsProps.tiff")

ggsave(
  filename    = export_file, 
  plot        = final_figure,
  units       = "px",
  width       = 8500,
  height      = 4800, 
  dpi         = 600,
  compression = "lzw" # LZW compression preserves text sharpness while reducing repository footprint
)
