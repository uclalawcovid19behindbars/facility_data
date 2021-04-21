library(tidyverse)
library(behindbarstools)
source("R/utilities.R")

OLD_FAC_INFO <- read_fac_info()
OLD_FAC_SPELLINGS <- read_fac_spellings()

updated_fac_info <- OLD_FAC_INFO %>%
    rows_update(tibble(Facility.ID = 1247,
                       HIFLD.ID = "10001713", 
                       Population.Feb20 = 2427, 
                       Capacity = 2539, 
                       Address = "1045 HORSEHEAD RD")) %>% 
    rows_update(tibble(Facility.ID = 200,
                       Population.Feb20 = NA, 
                       Source.Population.Feb20 = NA, 
                       Capacity = NA, 
                       Source.Capacity = NA)) %>% 
    mutate(County.FIPS = stringr::str_pad(County.FIPS, 5, pad = "0"), 
           Zipcode = stringr::str_pad(Zipcode, 5, pad = "0")) %>% 
    verify_new_fac_info()

write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")