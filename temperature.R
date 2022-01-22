# configuration
should_upload <- as.integer(Sys.getenv("SHOULD_UPLOAD", 0))
project_dir <- Sys.getenv("CLIMATE_TRACKER_DIR", getwd())
setwd(project_dir)

# load required packages
library(tidyverse)
library(aws.s3)
library(DatawRappr)
library(lubridate)
library(httr)

# get datawrapper key
dw_key <- Sys.getenv("DW_KEY")
  
# Berkeley Earth data
berkeley_earth <- read_fwf("http://berkeleyearth.lbl.gov/auto/Global/Land_and_Ocean_complete.txt", 
                           comment = "%",
                           fwf_empty(file = "http://berkeleyearth.lbl.gov/auto/Global/Land_and_Ocean_complete.txt", skip = 86)) %>%
  select(1:4) %>%
  tail(-1)

names(berkeley_earth) <- c("year","month","value","uncertainty")
berkeley_earth <- berkeley_earth %>%
  mutate(date = ymd(paste(year,month,"15")))

# remove second dataset
NonNAindex <- which(is.na(berkeley_earth$date))
firstNonNA <- min(NonNAindex)

berkeley_earth <- head(berkeley_earth, firstNonNA-1) %>%
  mutate(source = "Berkeley Earth")

# monthly and yearly data
berkeley_earth_monthly <- berkeley_earth %>%
  select(date,value,source)

berkeley_earth_yearly <- berkeley_earth %>%
  group_by(year,source) %>%
  summarize(value = round(mean(value, na.rm = T),2)) %>%
  filter(year != year(Sys.Date()))
  
# NASA data
nasa <- read_csv("https://data.giss.nasa.gov/gistemp/tabledata_v4/GLB.Ts+dSST.csv", skip = 1)
  
nasa_monthly <- nasa %>%  
  select(1:13) %>%
  mutate_at(c(2:13), as.double) %>%
  pivot_longer(cols = -Year, names_to = "month", values_to = "value") %>%
  filter(!is.na(value)) %>%
  rename(year = Year) %>%
  mutate(date = ymd(paste(year,month,"15")),
         source = "NASA") %>%
  select(value,date,source)

nasa_yearly <- nasa %>%
  select(1,14)
         
names(nasa_yearly) <- c("year","value")         
         
nasa_yearly <- nasa_yearly %>%
  mutate(value = as.double(value)) %>%
  filter(!is.na(value)) %>%
  mutate(source = "NASA") %>%
  select(value,year,source)


# combine data sets  
temp_record_monthly <- bind_rows(berkeley_earth_monthly,nasa_monthly) %>%
  pivot_wider(names_from = "source",values_from = "value")

temp_record_yearly <- bind_rows(berkeley_earth_yearly,nasa_yearly) %>%
  pivot_wider(names_from = "source",values_from = "value")

# write data to files
write_csv(temp_record_monthly, "csv/temp_record_monthly.csv", na="")
if (should_upload == 1) {
  put_object(file = "csv/temp_record_monthly.csv", object = "temp_record_monthly.csv", bucket = "data.buzzfeed.com/projects/climate-files")
}

write_csv(temp_record_yearly, "csv/temp_record_yearly.csv", na="")
if (should_upload == 1) {
  put_object(file = "csv/temp_record_yearly.csv", object = "temp_record_yearly.csv", bucket = "data.buzzfeed.com/projects/climate-files")
}

# ping datawrapper charts to update
POST(
  url = "https://api.datawrapper.de/v3/charts/LaZ2h/data/refresh",
  add_headers(Authorization = paste0("Bearer ",dw_key),
              Accept = "*.*")
)

POST(
  url = "https://api.datawrapper.de/v3/charts/nxo28/data/refresh",
  add_headers(Authorization = paste0("Bearer ",dw_key),
              Accept = "*.*")
)


###########
# big numbers

berkeley_earth_preindustrial <- berkeley_earth_yearly %>%
  filter(year >= 1880 & year <= 1899) %>%
  ungroup() %>%
  summarize(value = mean(value))

berkeley_earth_current <- berkeley_earth_yearly %>%
  ungroup() %>%
  filter(year >= max(year)-4) %>%
  select(value) %>%
  summarize(value = mean(value))

berkeley_earth_warming <- berkeley_earth_current - berkeley_earth_preindustrial

berkeley_earth_warming <- berkeley_earth_warming %>%
  mutate(value = round(value,1))

nasa_preindustrial <- nasa_yearly %>%
  filter(year >= 1880 & year <= 1899) %>%
  ungroup() %>%
  summarize(value = mean(value))

nasa_current <- nasa_yearly %>%
  ungroup() %>%
  filter(year >= max(year)-4) %>%
  select(value) %>%
  summarize(value = mean(value))

nasa_warming <- nasa_current - nasa_preindustrial 

nasa_warming <- nasa_warming %>%
  mutate(value = round(value,1))

warming_text <- case_when(nasa_warming$value == berkeley_earth_warming$value ~ as.character(nasa_warming$value),
                          nasa_warming$value < berkeley_earth_warming$value ~ paste0(nasa_warming$value,"&#8211;", berkeley_earth_warming$value),
                          nasa_warming$value > berkeley_earth_warming$value ~ paste0(berkeley_earth_warming$value,"&#8211;", nasa_warming$value))

warming_string <- paste0("document.write('<div class=\"bfn-big-number\" id=\"bfn-big-number-warming\"><span class=\"bfn-number-digits\">",
                          warming_text,
                         "&#176; C",
                          "<span class=\"bfn-number-label\"> of warming</span></div>');")

# write to file and push to data.buzzfeed.com
write(warming_string, file = "js/today-warming.js", append = FALSE)
if (should_upload == 1) {
  put_object(file = "js/today-warming.js", object = "today-warming.js", bucket = "data.buzzfeed.com/projects/climate-files")
}

