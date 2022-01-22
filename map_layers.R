# configuration
should_upload <- as.integer(Sys.getenv("SHOULD_UPLOAD", 0))
project_dir <- Sys.getenv("CLIMATE_TRACKER_DIR", getwd())
setwd(project_dir)

# load required packages
library(rgdal)
library(tidyverse)
library(R.utils)
library(lubridate)
library(raster)

####################################
# NASA GISTEMP

# load data as raster brick object
download.file("https://data.giss.nasa.gov/pub/gistemp/gistemp1200_GHCNv4_ERSSTv5.nc.gz", destfile = "raw/gistemp.gz")
gunzip("raw/gistemp.gz", destname = "raw/gistemp.nc", overwrite = TRUE)
temperature_monthly <- brick("raw/gistemp.nc")

## create vector to serve as index for calculating annual totals
# we need an index with 12 repeats of an index number for each of the years in the data
n <- year(Sys.Date()) - 1880
y <- year(Sys.Date()) - 1 
num_years <- rep(1:n, each = 12) 

# calculate annual totals, gives  layers one for each year 1880-2019 in the data
temperature_annual <- stackApply(temperature_monthly, indices=num_years, fun=mean)

## convert annual data to spatial polygons data frame, write to GeoJSON
temperature_annual_df <- as(temperature_annual, "SpatialPolygonsDataFrame")
names(temperature_annual_df@data) <- c(as.character(1880:y))

# filter for 1880-present
temperature_annual_df@data <- temperature_annual_df@data %>%
  dplyr::select(1:n)
file.remove("geojson/temperature_annual.geojson")
writeOGR(temperature_annual_df, "geojson/temperature_annual.geojson", layer="temperature", driver="GeoJSON")

## make the map overlay

# calculate change in temperature between the 1951-1980 reference period in the GISTEMP analysis
# and the last 15 years 2004-2018
temperature_diff <- subset(temperature_annual, (n-14):n)
temperature_diff <- calc(temperature_diff, mean, na.rm = TRUE) 

# create a raster object with the same extent but higher resolution
s <- raster(nrow = 1800, ncol = 3600, extent(c(-180, 180, -90, 90))) 
# resample the data using this raster
temperature_diff <- raster::resample(temperature_diff, s, method = "bilinear") 

# write to GeoTIFF
writeRaster(temperature_diff, 
            filename = "geotiff/temperature_diff.tif", 
            format = "GTiff",
            overwrite = TRUE)
