# Script to merge volunteer linkage work into the main facility crosswalk 
# Volunteers linked BJS and HIFLD IDs to facilities in our (old) crosswalk 
# starting in September. 

library(tidyverse)
library(behindbarstools)
library(readxl)

# Read files
fac_info <- read_fac_info()
fac_spellings <- read_fac_spellings()
bjs_xwalk <- read_excel("data/linkage/ucla_bjs_crosswalk.xlsx", skip = 4)
hifld_xwalk <- read_excel("data/linkage/ucla_hifld_crosswalk_part2.xlsx", skip = 4, range = "A5:H225")

# State and name should be unique in crosswalks so we can m:1 merge 
bjs_xwalk %>% select(State, Name) %>% distinct() %>% nrow() == bjs_xwalk %>% nrow()
hifld_xwalk %>% select(State, Name) %>% distinct() %>% nrow() == hifld_xwalk %>% nrow()

# Join BJS and HIFLD crosswalks with fac_spellings 
# Have to join based on name and state because there is no jurisdiction or ID variable in the crosswalks 
# As a result, only look for matches where name and state are unique in fac_spellings  
xwalk_joined <- fac_spellings %>% 
    mutate(name_clean_ = clean_fac_col_txt(xwalk_name_raw, to_upper = TRUE)) %>% 
    group_by(name_clean_, State) %>% 
    mutate(n = n()) %>% 
    filter(n == 1) %>%  
    ungroup() %>% 
    left_join(bjs_xwalk %>% 
                  mutate(name_clean_ = clean_fac_col_txt(Name, to_upper = TRUE)) %>% 
                  select(State, name_clean_, BJS_ID), by = c("name_clean_", "State")) %>% 
    left_join(hifld_xwalk %>% 
                  mutate(name_clean_ = clean_fac_col_txt(Name, to_upper = TRUE)) %>% 
                  select(State, name_clean_, HIFLD_ID), by = c("name_clean_", "State")) %>% 
    mutate(name_clean_ = clean_fac_col_txt(xwalk_name_clean, to_upper = TRUE)) %>% 
    select(Facility.ID, State, name_clean_, BJS_ID, HIFLD_ID) %>% 
    distinct() %>% 
    group_by_coalesce(Facility.ID) %>% 
    select(Facility.ID, 
           BJS.ID_linkage = BJS_ID, 
           HIFLD.ID_linkage = HIFLD_ID)

# Check for duplicate Facility IDs 
xwalk_joined %>% janitor::get_dupes(Facility.ID) 

# Join crosswalks + spellings with fac_info 
joined <- fac_info %>% 
    left_join(xwalk_joined, 
              by = "Facility.ID") %>% 
    mutate(HIFLD.ID = coalesce(HIFLD.ID, HIFLD.ID_linkage), 
           BJS.ID = coalesce(BJS.ID, as.double(BJS.ID_linkage)))

# Double-check that we have only updated info, not adding duplicate facilities 
joined %>% nrow() == fac_info %>% nrow()

# Update sheet 
updated_fac_info <- joined %>% 
    select(Facility.ID, State, Name, Jurisdiction, Description, Security,
           Age, Gender, Is.Different.Operator, Different.Operator, Population.Feb20,
           Capacity, HIFLD.ID, BJS.ID, Source.Population.Feb20, Source.Capacity, Address,
           City, Zipcode, Latitude, Longitude, County, County.FIPS, Website, ICE.Field.Office)

write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")
