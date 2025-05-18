# ---------------------------------------------------------------------------- #
# Landsat-based WUI mapping approach
# ---------------------------------------------------------------------------- #

# Ddeveloped under: R version R-4.4.1

# author: Kira Pfoch (pfoch@wisc.edu)
# date:   May 2025
# corresponding publication: in review

# description:  this script creates a wildland-urban interface (WUI) map based on landsat-based land cover fractions of impervious, woody, and non-woody fractions using threshold criteria.
#               see Pfoch et al. (in reveiw) for details.
#               this code uses data organized UTM 54S (EPGS: 32754) 

# input data: raster files of masked, adjust input path

# output:  raster GeoTiff
#               map of four WUI types and a non-WUI class:
#               0 - non-WUI
#               1 - WUI Intermix (dominant woody vegetation)
#               2 - WUI Interface (dominant woody vegetation)
#               3 - WUI Intermix (dominant non-woody vegetation)
#               4 - WUI Interface (dominant non-woody vegetation)

                                   
# ---------------------------------------------------------------------------- #
# R version R-4.4.1
# ---------------------------------------------------------------------------- #

# Packages
# install.packages(raster)
library(raster)


# ---------------------------------------------------------------------------- #
# import input features
# ---------------------------------------------------------------------------- #

# data input path
in_path = ""
out_path = ""


# ---------------------------------------------------------------------------- #
# Landsat based land cover fraction for 2020
# ---------------------------------------------------------------------------- #

# processing steps

# - pixel with > 20 % water are set to 0 % impervious fractions
# - pixels with 1 % to 20 % impervious fractions are set to 0 % impervious fractions
# - calculate 500m buffer average of impervious fraction


# ---------------------------------------------------------------------------- #
# building density approximated via impervious fractions
# ---------------------------------------------------------------------------- #
#   processing steps: 
#    - pixel with > 20 % water are set to 0 % impervious fractions
#    - pixels with 1 % to 20 % impervious fractions are set to 0% impervious fractions
#    - then calculate 500 m buffer average of impervious fraction
impervious_500m_avg = stack(paste0(in_path, "impervious_500m_avg.tif"))

# ---------------------------------------------------------------------------- #
# intermix vegetation 
# ---------------------------------------------------------------------------- #

#   woody vegetation processing steps: 
#    - pixel with > 20 % water are set to 0 % fractions
#    - pixels with > 30 % impervious fractions are set to 0 % woody fractions (assumed non-natural due to human presence and avoid misclassification of suburbs as intermix)
#    - then calculate 500 m buffer average of woody fraction
woody_500m_avg = stack(paste0(in_path, "woody_500m_avg.tif"))

# ---------------------------------------------------------------------------- #
#   non-woody vegetation processing steps: 
#    - pixel with > 20 % water are set to 0 % fractions
#    - pixels with > 30 % impervious fractions are set to 0 % non-woody fractions (assumed non-natural due to human presence and avoid misclassification of suburbs as intermix)
#    - pixel with identified cropland (for Adeladie via EVI skewness) 0 % fractions
#    - then calculate 500 m buffer average of woody fraction
nonwoody_500m_avg = stack(paste0(in_path, "nonwoody_500m_avg.tif"))


# ---------------------------------------------------------------------------- #
# interface vegetation 
# ---------------------------------------------------------------------------- #

#   woody vegetation processing steps: 
#    - pixel with > 20 % water are set to 0 % fractions
#    - pixels with > 30 % impervious fractions are set to 0 % non-woody fractions (assumed non-natural due to human presence and avoid misclassification of suburbs as intermix)
#    - then find clusters of > 5sqkm with > 50 % woody fraction
#    - buffer indentified clusters by 2400m 
woody_cluster5sqkm_buffer2400m = stack(paste0(in_path, "woody_interface_cluster5sqkm_buffer2400m.tif"))

# ---------------------------------------------------------------------------- #
#   non-woody vegetation processing steps: 
#    - pixel with > 20 % water are set to 0 % fractions
#    - pixels with > 30 % impervious fractions are set to 0 % non-woody fractions (assumed non-natural due to human presence and avoid misclassification of suburbs as intermix)
#    - pixel with identified cropland (for Adeladie via EVI skewness) 0 % fractions
#    - then find clusters of > 5sqkm with > 50 % non-woody fraction
#    - buffer indentified clusters by 2400m 
nonwoody_cluster5sqkm_buffer2400m = stack(paste0(in_path, "nonwoody_interface_cluster5sqkm_buffer2400m.tif"))


# ---------------------------------------------------------------------------- #
# rasters are scaled between 0 to 10,000
# re-scale raster to percentage scale

impervious_500m_avg = impervious_500m_avg/ 100
woody_500m_avg = woody_500m_avg/ 100
nonwoody_500m_avg = nonwoody_500m_avg/ 100


# ---------------------------------------------------------------------------- #

# import water mask
water_mask = stack(paste0(in_path, "wui_water_mask.tif"))

# import landsat footprint mask
landsat_footprint = stack(paste0(in_path, "wui_landsat_footprint_097084_mask.tif"))


# ---------------------------------------------------------------------------- #
# Mapping the WUI
# ---------------------------------------------------------------------------- #

# create empty raster for the WUI map with similar characteristics as the impervious raster
wui_rs = raster(impervious_500m_avg)

# set all raster values to zero
wui_rs = setValues(wui_rs, 0) 


# ---------------------------------------------------------------------------- #
# WUI classification (hierarchical)
# ---------------------------------------------------------------------------- #

# non-woody interface WUI
wui_rs[impervious_500m_avg >= 0.2 & nonwoody_cluster5sqkm_buffer2400m > 0] = 4
# woody interface WUI
wui_rs[impervious_500m_avg >= 0.2 & woody_cluster5sqkm_buffer2400m > 0] = 2

# non-woody intermix WUI
wui_rs[impervious_500m_avg >= 0.2 & nonwoody_500m_avg >= 50] = 3
# woody intermix WUI
wui_rs[impervious_500m_avg >= 0.2 & woody_500m_avg >= 50] = 1


# masked water > 20 %
wui_rs[water_mask > 20] <- NA # water mask
wui_rs[is.na(landsat_footprint)] <- NA # outside of Landsat footprint set values to NA 

plot(wui_rs)


# ---------------------------------------------------------------------------- #
# write WUI classification raster file (GeoTiff)
# ---------------------------------------------------------------------------- #

writeRaster(wui_rs, 
            paste0(out_path, "Landsat_WUI_2020.tif"),
            overwrite = TRUE)

# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #

# for creating a nice map use package tmap
# install.packages("tmap")
library(tmap)

# ---------------------------------------------------------------------------- #
# plot WUI map with tmap package

tm_shape(wui_rs)+
  tm_raster(breaks = c(0, 1, 2, 3, 4),
            style = "cat",
            palette = c("#cccccc",
                        "#ed8100", 
                        "#FFFF00",
                        "#5f5134",
                        "#ae932e"),
            labels = c("Non-WUI","1 = intermix WUI (woody)",
                       "2 = interface WUI (woody)",
                       "3 = intermix WUI (non-woody)",
                       "4 = interface WUI (non-woody)"),
            title = "legend")+
  tm_layout(panel.labels = c("Landsat-based WUI"))+
  tm_layout(legend.position = c("left", "bottom"))



# ---------------------------------------------------------------------------- #
# the end.
# ---------------------------------------------------------------------------- #
