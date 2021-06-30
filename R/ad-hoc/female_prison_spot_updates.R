library(tidyverse)
library(behindbarstools)
source("R/utilities.R")

OLD_FAC_INFO <- read_fac_info()

female_ids <- c(60, 2168, 517, 941, 1158)

updated_fac_info <- OLD_FAC_INFO %>%
    mutate(Gender = ifelse(Facility.ID %in% female_ids, "Female", Gender)) %>% 
    rows_update(tibble(Facility.ID = 411,
                       HIFLD.ID	 = "10004453", 
                       Address = "414 VALLEY HART ROAD", 
                       City = "HARTWELL", 
                       Zipcode = "30643", 
                       Latitude = 34.31194,
                       Longitude = -82.93828, 
                       County = "HART", 
                       County.FIPS = "13147")) %>% 
    rows_update(tibble(Facility.ID = 1024,
                       HIFLD.ID	 = "10003607", 
                       Address = "440 MCKENZIE ST", 
                       City = "NEW ENGLAND", 
                       Zipcode = "58647", 
                       Latitude = 46.53541,
                       Longitude = -102.8672, 
                       County = "HETTINGER", 
                       County.FIPS	= "38041")) %>% 
    rows_update(tibble(Facility.ID = 1299,
                       HIFLD.ID	 = "10002897", 
                       Address = "5509 ATTWATER AVE", 
                       City = "DICKINSON", 
                       Zipcode = "77539", 
                       Latitude = 29.4264,
                       Longitude = -94.98153, 
                       County = "GALVESTON", 
                       County.FIPS	= "48167")) %>% 
    rows_update(tibble(Facility.ID = 1581,
                       HIFLD.ID	 = "10001575", 
                       Address = "2841 RIVER RD", 
                       City = "GOOCHLAND", 
                       Zipcode = "23063", 
                       Latitude =  37.67421,
                       Longitude = -77.89122, 
                       County = "GOOCHLAND", 
                       County.FIPS	= "51075")) %>% 
    rows_update(tibble(Facility.ID = 413,
                       Address = "8662 U.S. HWY 301 NORTH", 
                       City = "CLAXTON", 
                       Zipcode = "30417", 
                       Latitude =  32.179347,
                       Longitude = -81.8948173, 
                       County = "EVANS", 
                       County.FIPS	= "13109")) %>% 
    rows_update(tibble(Facility.ID = 593,
                       Address = "230 RIVER RD", 
                       City = "WINDHAM", 
                       Zipcode = "04062", 
                       Latitude =  43.8955041,
                       Longitude = -70.1032762, 
                       County = "CUMBERLAND", 
                       County.FIPS	= "23005")) %>% 
    rows_update(tibble(Facility.ID = 1248,
                       Address = "3881 STEWARTS LANE", 
                       City = "NASHVILLE", 
                       Zipcode = "37243", 
                       Latitude =  36.19362,
                       Longitude = -86.85957, 
                       County = "DAVIDSON", 
                       County.FIPS	= "47037")) %>% 
    verify_new_fac_info(.)
    
write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")
