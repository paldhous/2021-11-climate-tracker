# configuration
should_upload <- as.integer(Sys.getenv("SHOULD_UPLOAD", 0))
project_dir <- Sys.getenv("CLIMATE_TRACKER_DIR", getwd())
setwd(project_dir)

# load required packages
library(tidyverse)
library(aws.s3)
library(DatawRappr)
library(lubridate)
library(readxl)
library(httr)

# get datawrapper key
dw_key <- Sys.getenv("DW_KEY")

########
# Atmospheric co2

# https://www.esrl.noaa.gov/gmd/ccgg/trends/gl_data.html
global_co2 <- read_csv("https://gml.noaa.gov/webdata/ccgg/trends/co2/co2_mm_gl.csv", comment = "#") %>%
  mutate(date = ymd(paste(year,month,"15"))) %>%
  select(date, average) %>%
  rename(ppm = average) %>%
  mutate(source = "Global average")

mauna_loa_co2 <- read_csv("https://gml.noaa.gov/webdata/ccgg/trends/co2/co2_mm_mlo.csv", comment = "#") %>%
  mutate(date = ymd(paste(year,month,"15"))) %>%
  select(date, average) %>%
  rename(ppm = average) %>%
  mutate(source = "Mauna Loa")

# combine data
atmospheric_co2_monthly <- bind_rows(mauna_loa_co2,global_co2) %>%
  pivot_wider(names_from = "source",values_from = "ppm")

# write data to file
write_csv(atmospheric_co2_monthly, "csv/atmospheric_co2_monthly.csv", na="")
if (should_upload == 1) {
  put_object(file = "csv/atmospheric_co2_monthly.csv", object = "atmospheric_co2_monthly.csv", bucket = "data.buzzfeed.com/projects/climate-files")
}

# ping datawrapper chart to update
POST(
  url = "https://api.datawrapper.de/v3/charts/zUgWD/data/refresh",
  add_headers(Authorization = paste0("Bearer ",dw_key),
              Accept = "*.*")
)

################
# long term data from https://www.ncei.noaa.gov/pub/data/paleo/icecore/antarctica/antarctica2015co2edc.txt
# download.file("https://www.ncei.noaa.gov/pub/data/paleo/icecore/antarctica/antarctica2015co2.xls",destfile = "raw/paleo.xls")

paleo <- read_excel("raw/paleo.xls", 
                    sheet = 3,
                    skip = 14) %>%
  select(1,2)
names(paleo) <- c("bp","ppm")

paleo <- paleo %>%
  mutate(year = 1950 - bp) %>%
  select(year,ppm)

recent <- read_csv("https://gml.noaa.gov/webdata/ccgg/trends/co2/co2_annmean_gl.csv", comment = "#") %>%
  select(1,2) %>%
  rename(ppm = mean)

# combine data
atmospheric_co2_long <- bind_rows(paleo,recent)

# write data to file
write_csv(atmospheric_co2_long, "csv/atmospheric_co2_long.csv", na="")
if (should_upload == 1) {
  put_object(file = "csv/atmospheric_co2_long.csv", object = "atmospheric_co2_long.csv", bucket = "data.buzzfeed.com/projects/climate-files")
}

# ping datawrapper chart to update
POST(
  url = "https://api.datawrapper.de/v3/charts/v6F4z/data/refresh",
  add_headers(Authorization = paste0("Bearer ",dw_key),
              Accept = "*.*")
)


