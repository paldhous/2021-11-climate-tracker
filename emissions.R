# configuration
should_upload <- as.integer(Sys.getenv("SHOULD_UPLOAD", 0))
project_dir <- Sys.getenv("CLIMATE_TRACKER_DIR", getwd())
setwd(project_dir)

# load required packages
library(tidyverse)
library(aws.s3)
library(WDI)
library(countrycode)
library(DatawRappr)
library(httr)

# get datawrapper key
dw_key <- Sys.getenv("DW_KEY")

emissions <- read_csv("https://raw.githubusercontent.com/owid/co2-data/master/owid-co2-data.csv")


##############################
# emissions by country table
country_emissions <- emissions %>%
  mutate(iso_code = gsub("OWID_KOS","XKX", iso_code),
         iso2c = case_when(iso_code == "XKX" ~ "XK",
                           grepl("Micronesia ",country) ~ "FM",
                           grepl("Macao",country) ~ "MO",
                           TRUE ~ countrycode(iso_code, origin = "iso3c", destination = "iso2c"))
  ) %>%
  filter(!grepl("OWID",iso_code) & !is.na(iso2c)) 
  
current_country_emissions <- country_emissions %>%
  mutate(code = paste0(":",tolower(iso2c),":"),
         country = paste(code,country)) %>%
  select(country,co2,cumulative_co2,year) %>%
  group_by(country) %>%
  filter(year == max(year, na.rm = T)) %>%
  select(-year) %>%
  arrange(-cumulative_co2)

# # alt, from manual download
# emissions_2020 <- read_csv("raw/annual-co-emissions-by-region.csv")
# names(emissions_2020) <-c("country","iso3c","year","co2")
# emissions_2020 <- emissions_2020 %>%
#   mutate(co2 = round(co2/10^6,3))
# 
# latest <- emissions_2020 %>%
#   mutate(iso3c = gsub("OWID_KOS","XKX", iso3c),
#          iso2c = case_when(iso3c == "XKX" ~ "XK",
#                            grepl("Micronesia ",country) ~ "FM",
#                            grepl("Macao",country) ~ "MO",
#                            TRUE ~ countrycode(iso3c, origin = "iso3c", destination = "iso2c"))
#   ) %>%
#   filter(!grepl("OWID",iso3c) & !is.na(iso2c))%>%
#   group_by(country) %>%
#   filter(year == max(year, na.rm = T)) %>%
#   select(-year)
# 
# cumulative <- emissions_2020 %>%
#   group_by(country,iso3c) %>%
#   summarize(cumulative_co2 = sum(co2,na.rm = TRUE))
# 
# current_country_emissions <- inner_join(latest,cumulative) %>%
#   mutate(code = paste0(":",tolower(iso2c),":"),
#          country = paste(code,country)) %>%
#   select(country,co2,cumulative_co2) %>%
#   arrange(-cumulative_co2)


write_csv(current_country_emissions, "csv/current_country_emissions.csv", na="")
if (should_upload == 1) {
  put_object(file = "csv/current_country_emissions.csv", object = "current_country_emissions.csv", bucket = "data.buzzfeed.com/projects/climate-files")
}

dw_data_to_chart(current_country_emissions, chart_id = "VBUhm", api_key = dw_key)

###################
# emissions timeline by region
# wdi <-  WDI(country = "all", indicator = "NY.GDP.PCAP.KD", start = 2019, end = 2019, extra = T) %>%
#   select(iso2c,country,region,income)

# emissions <- inner_join(emissions,wdi)
# emissions <- inner_join(emissions,wdi, by = c("iso_code" = "iso3c"))
# 
# world_emissions_timeline <- emissions %>%
#   filter(iso_code == "OWID_WRL" & year >= 1850) %>%
#   select(country,year,co2)


# unique(region_emissions_timeline$country)

region_emissions_timeline <- emissions %>%
  filter(country == "Africa" | country == "Asia" | country == "Europe" | country == "North America" | country == "Oceania" | country == "South America" | country == "International transport") %>%
  group_by(year,country) %>%
  summarize(co2 = sum(co2, na.rm = T)) %>%
  pivot_wider(names_from = country, values_from = co2) %>%
  filter(year >= 1850) 

# # alt, from manual download
# region_emissions_timeline <- emissions_2020 %>%
#   filter(country == "Africa" | country == "Asia" | country == "Europe" | country == "North America" | country == "Oceania" | country == "South America" | country == "International transport") %>%
#   group_by(year,country) %>%
#   summarize(co2 = sum(co2, na.rm = T)) %>%
#   pivot_wider(names_from = country, values_from = co2) %>%
#   filter(year >= 1850) %>%
#   ungroup() %>%
#   relocate(1,4,6,3,8,2,7,5)
  

write_csv(region_emissions_timeline, "csv/region_emissions_timeline.csv", na="")
if (should_upload == 1) {
  put_object(file = "csv/region_emissions_timeline.csv", object = "region_emissions_timeline.csv", bucket = "data.buzzfeed.com/projects/climate-files")
}

# ping datawrapper chart to update
POST(
  url = "https://api.datawrapper.de/v3/charts/iUCnG/data/refresh",
  add_headers(Authorization = paste0("Bearer ",dw_key),
              Accept = "*.*")
)



  







