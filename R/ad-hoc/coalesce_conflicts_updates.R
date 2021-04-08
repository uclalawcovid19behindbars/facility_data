rm(list=ls())

library(behindbarstools)
library(tidyverse)

fac_spellings <- read_fac_spellings()
fac_info <- read_fac_info()

raw_flightline <- c(
    "BIG SPRING FLIGHTLINE CI", 
    "BIG SPRING CI FLIGHTLINE", 
    "BIG SPRING FLIGHTLINE CORRECTIONAL INSTITUTION"
)
 
raw_jessup <- c(
    "MARYLAND CI - JESSUP", 
    "MARYLAND CORRECTIONAL INSTITUTION JESSUP", 
    "MARYLAND CORRECTIONAL INSTITUTION-JESSUP", 
    "MCI-J-MARYLAND CI - JESSUP"
)

raw_mdw_infirm <- c(
    "MACDOUGALL WALKER CORRECTIONAL INSTITUTION INFIRMARY", 
    "MACDOUGALL WALKER CI INFIRMARY", 
    "MACDOUGALL WALKER CI INFIRMIRY", 
    "MACDOUGALL-WALKER CI INFIRMARY"
)

raw_nbci <- c(
    "NBC", 
    "NBCI NORTH BRANCH CI", 
    "NBCI NORTH BRANCH CORRECTIONAL INSTITUTION", 
    "NBCI-NORTH BRANCH CI", 
    "NORTH BRANCH CI"
)

updated_fac_spellings <- fac_spellings %>% 
    filter(! (State == "Texas" & xwalk_name_raw == "GEO CARE INC SALT LAKE CITY UT")) %>% 
    mutate(xwalk_name_clean = case_when(
        xwalk_name_raw %in% raw_flightline ~ "BIG SPRING FLIGHTLINE CORRECTIONAL INSTITUTION", 
        xwalk_name_raw %in% raw_jessup ~ "MARYLAND CORRECTIONAL INSTITUTION - JESSUP", 
        xwalk_name_raw %in% raw_mdw_infirm ~ "MACDOUGALL WALKER CORRECTIONAL INSTITUTION INFIRMARY", 
        xwalk_name_raw %in% raw_nbci ~ "NORTH BRANCH CORRECTIONAL INSTITUTION", 
        TRUE ~ xwalk_name_clean)
    ) %>% 
    mutate(Facility.ID = case_when(
        xwalk_name_raw %in% raw_flightline ~ 2184, 
        xwalk_name_raw %in% raw_jessup ~ 2185, 
        xwalk_name_raw %in% raw_mdw_infirm ~ 2186, 
        xwalk_name_raw %in% raw_nbci ~ 2182, 
        TRUE ~ Facility.ID)
    ) %>% 
    distinct()

write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE, na = "")
