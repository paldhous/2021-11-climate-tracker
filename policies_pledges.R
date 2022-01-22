# configuration
should_upload <- as.integer(Sys.getenv("SHOULD_UPLOAD", 0))
project_dir <- Sys.getenv("CLIMATE_TRACKER_DIR", getwd())
setwd(project_dir)

# load required packages
library(tidyverse)
library(aws.s3)
library(DatawRappr)
library(rvest)
library(readxl)
library(httr)

# get datawrapper key
dw_key <- Sys.getenv("DW_KEY")

# CAT data
page <- read_html("https://climateactiontracker.org/global/temperatures/")

link <- page %>%
  html_nodes("a") %>%
  html_attr("href") %>%
  tibble(link = .) %>%
  filter(grepl("xls",link))

download.file(paste0("https://climateactiontracker.org",link$link), 
              destfile = "raw/cat.xlsx")

cat <- read_excel("raw/cat.xlsx",
                  skip = 14) %>%
  head(10) %>% # may need to change the number here
  rename(x1 = `...1`) %>%
  fill(x1) %>%
  mutate(scenario = paste(x1,GtCO2e),
         scenario = str_squish(gsub("NA", "",scenario))) %>%
  select(-x1,-GtCO2e) 

cat <- cat %>%
  mutate_at(1:ncol(cat)-1, as.double) %>%
  pivot_longer(names_to = "year", values_to = "emissions", -scenario) %>%
  mutate(emissions = 1000*emissions) %>%
  pivot_wider(names_from = scenario, values_from = emissions)

# write to file and push to data.buzzfeed.com
write_csv(cat,"csv/policies.csv", na = "")
if (should_upload == 1) {
  put_object(file = "csv/policies.csv", object = "policies.csv", bucket = "data.buzzfeed.com/projects/climate-files")
}

# ping datawrapper chart to update
POST(
  url = "https://api.datawrapper.de/v3/charts/VBth4/data/refresh",
  add_headers(Authorization = paste0("Bearer ",dw_key),
              Accept = "*.*")
)
