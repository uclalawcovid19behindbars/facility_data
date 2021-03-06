# This script was used clean the data sheets after we added new facility details 
# It also assigns Facility IDs to fac_info and fac_spellings 

rm(list = ls())

library(tidyverse)
library(behindbarstools)

# Read data 
fac_data <- read.csv("data_sheets/fac_data.csv")
fac_spellings <- read.csv("data_sheets/fac_spellings.csv")

# Clean sheets 
fac_data <- fac_data %>% 
    mutate(Security = case_when(Security == "Max/Mid" ~ "Max/Med", 
                                TRUE ~ Security), 
           Is.Different.Operator = case_when(Is.Different.Operator ~ 1, 
                                             is.na(Is.Different.Operator) ~ 0)) %>% 
    rename("Population.Feb20" = "Population", 
           "Source.Population.Feb20" = "Source.Population")

fac_spellings <- fac_spellings %>% 
    rename("xwalk_name_raw" = "Name.Raw", 
           "xwalk_name_clean" = "Name.Clean") %>% 
    select(-Jurisdiction) %>% 
    distinct()
    
# Add IDs to info sheet 
fac_data <- fac_data %>% 
    arrange(State, Name) %>% 
    group_by(State, Name) %>%
    mutate(Facility.ID = cur_group_id()) %>% 
    select(Facility.ID, 
           State, 
           Name, 
           Jurisdiction, 
           Description, 
           Security, 
           Age, 
           Gender, 
           Is.Different.Operator, 
           Different.Operator, 
           Population.Feb20, 
           Capacity, 
           HIFLD.ID, 
           BJS.ID, 
           Source.Population.Feb20, 
           Source.Capacity, 
           Address, 
           City, 
           Zipcode, 
           Latitude, 
           Longitude, 
           County, 
           County.FIPS, 
           Website) 

# Sanity check - should be true 
stopifnot(max(fac_data$Facility.ID) == nrow(fac_data))

# Merge IDs into fac_spellings 
# Federal facilities: merge on cleaned name 
federal <- fac_spellings %>% 
    filter(Is.Federal == 1) %>% 
    mutate(name_clean_ = clean_fac_col_txt(xwalk_name_clean, to_upper = TRUE)) %>% 
    select(-State) %>% 
    left_join(fac_data %>% 
                  filter(Jurisdiction == "federal") %>%  
                  mutate(name_clean_ = clean_fac_col_txt(Name, to_upper = TRUE)),  
              by = "name_clean_") %>% 
    select(Facility.ID, xwalk_name_raw, xwalk_name_clean, State, Is.Federal)

# Non-federal facilities: merge on cleaned name + state 
non_federal <- fac_spellings %>% 
    filter(Is.Federal == 0) %>% 
    mutate(name_clean_ = clean_fac_col_txt(xwalk_name_clean, to_upper = TRUE)) %>% 
    left_join(fac_data %>% 
                  filter(Jurisdiction != "federal") %>% 
                  mutate(name_clean_ = clean_fac_col_txt(Name, to_upper = TRUE)),
              by = c("name_clean_", "State")) %>% 
    select(Facility.ID, xwalk_name_raw, xwalk_name_clean, State, Is.Federal)

full_spellings <- bind_rows(federal, non_federal) %>% 
    arrange(State, Facility.ID) %>% 
    distinct()

stopifnot(nrow(full_spellings) == nrow(fac_spellings))
stopifnot(nrow(full_spellings) == nrow(distinct(full_spellings)))

# Write csv files out 
write_csv(fac_data, "data/fac_data.csv")
write_csv(full_spellings, "data/fac_spellings.csv")

# TODO: Fix spellings without an info sheet match 
# Some of these can be resolved by assigning the correct jurisdiction to the info sheet 
# Others will require updating the facility_name_clean to match the info sheet 
# Others will require adding an altogether new facility to the info sheet 
full_spellings %>% 
    filter(is.na(Facility.ID)) %>% 
    nrow()

