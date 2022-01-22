# configuration
should_upload <- as.integer(Sys.getenv("SHOULD_UPLOAD", 0))
project_dir <- Sys.getenv("CLIMATE_TRACKER_DIR", getwd())
setwd(project_dir)

# load required packages
library(tidyverse)
library(aws.s3)
library(DatawRappr)
library(rvest)
library(lubridate)
library(jsonlite)
library(zoo)
library(httr)

# get datawrapper key
dw_key <- Sys.getenv("DW_KEY")

# load U Hawaii data from OWID https://ourworldindata.org/explorers/climate-change?facet=none&country=~OWID_WRL&Metric=Sea+level+rise&Long-run+series%3F=false
hawaii <- fromJSON("https://ourworldindata.org/grapher/data/variables/176329+176327+176328.json?v=4")
hawaii<- hawaii$variables$`176328`
hawaii <- tibble(date = hawaii$years, mm = hawaii$values) %>%
  mutate(date = as.Date(date, origin = "1800-01-01"),
         source = "U. Hawaii")

# load Church and White reconstruction from http://www.cmar.csiro.au/sealevel/sl_data_cmar.html
# download.file("http://www.cmar.csiro.au/sealevel/downloads/church_white_gmsl_2011_up.zip", destfile = "raw/church_white.zip")
# unzip("raw/church_white.zip", exdir = "raw")
church_white <- read_csv("raw/church_white_gmsl_2011_up/CSIRO_Recons_gmsl_mo_2015.csv") %>%
  select(1,2)
names(church_white) <- c("year","mm")
church_white <- church_white %>%
  mutate(date =as.Date(date_decimal(year)),
         month = month(date),
         year = floor(year),
         date = ymd(paste(year,month,"15"))) %>%
  select(date,mm) %>%
  mutate(source = "CSIRO")

church_white_av <- church_white %>%
  filter(date >= "1993-01-01" & date <= "2008-12-31") %>%
  summarize(average = mean(mm))

church_white <- church_white %>%
  mutate(mm = mm - church_white_av$average)

# combine data
sea_level_monthly <- bind_rows(church_white,hawaii) %>%
  pivot_wider(names_from = "source",values_from = "mm") %>%
  arrange(date) %>%
  mutate(`U. Hawaii` = na.approx(`U. Hawaii`, maxgap = 4))

# write data to file
write_csv(sea_level_monthly, "csv/sea_level_monthly.csv", na="")
if (should_upload == 1) {
  put_object(file = "csv/sea_level_monthly.csv", object = "sea_level_monthly.csv", bucket = "data.buzzfeed.com/projects/climate-files")
}

# ping datawrapper chart to update
POST(
  url = "https://api.datawrapper.de/v3/charts/zl3BL/data/refresh",
  add_headers(Authorization = paste0("Bearer ",dw_key),
              Accept = "*.*")
)


#########
sea_level_text <- read_html("https://www.climate.gov/news-features/understanding-climate/climate-change-global-sea-level") %>%
  html_nodes("li") %>%
  html_text() %>%
  as_tibble() %>%
  filter(grepl("since 1880",value)) %>%
  mutate(value = str_extract(string = value,
                             pattern = "(?<=\\().*(?=\\))"),
         value = gsub(" centimeters","",value)) %>%
  separate(value, into = c("value1","value2"), sep = "–")

# big number
sea_level_string <- paste0("document.write('<div class=\"bfn-big-number\" id=\"bfn-big-number-sea-level\"><span class=\"bfn-number-digits\">",
                         sea_level_text$value1,
                         "&#8211;",
                         sea_level_text$value2,
                         " cm",
                         "<span class=\"bfn-number-label\"> of sea level rise</span></div>');")

# write to file and push to data.buzzfeed.com
write(sea_level_string, file = "js/today-sea-level.js", append = FALSE)
if (should_upload == 1) {
  put_object(file = "js/today-sea-level.js", object = "today-sea-level.js", bucket = "data.buzzfeed.com/projects/climate-files")
}