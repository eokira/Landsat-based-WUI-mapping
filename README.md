Landsat-based-WUI-mapping

1. System requirements
This code was developed for R (version R-4.4.1) and imports the following packages: raster.

2. Installation guide
The code can be downloaded and immediately used on any machine that satisfies the system requirements and installed R version. There is no install time.

3. Demo
This repository provides a demo inlcuding all required datasets.

Run python3 /directory/map_wui.R Adeladie (Australia) from the demo directorty to execute the script with the demo tile. The resulting wildland-urban interface map will be saved to the wui directory.

The expected runtime is ca. 9 seconds per tile (single-core tested, 2.6 GHz CPU speed).

4. Instructions for use
Intermediate data for other tiles than the demo tiles are currently not available for download due to file sizes. Intermediate building and other land cover data can, however, be re-creatd using basic GIS functionalities (moving window averaging and buffering).
