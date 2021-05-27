library(tidyverse)
library(behindbarstools)

source("R/utilities.R")

old_fac_info <- read_fac_info()
feb20_updates_raw <- googlesheets4::read_sheet("1EnXEEKVdAPHcKblqMSaMWb8bcfUqUBKYvUr6_ORzIzY", 
                                           col_types = "c")

feb20_updates <- feb20_updates_raw %>% 
    mutate(`New Population.Feb20` = as.numeric(`New Population.Feb20`), 
           `Old Population.Feb20` = as.numeric(`Old Population.Feb20`), 
           Facility.ID = as.numeric(Facility.ID)) %>% 
    filter(Checked == "ET") %>% 
    filter(!is.na(`New Population.Feb20`)) %>% 
    mutate(Source = ifelse(str_detect(`New Source`, "(?i)prea"), "PREA Audit", "Public Records")) %>% 
    mutate(Source = ifelse(str_detect(`Notes`, "(?i)prea"), "PREA Audit", Source)) %>% 
    mutate(Source = ifelse(is.na(Source), "Public Records", Source)) %>% 
    select(Facility.ID, `New Population.Feb20`, Source) 
    
updated_fac_info <- old_fac_info %>% 
    left_join(feb20_updates, by = "Facility.ID") %>% 
    mutate(Population.Feb20 = coalesce(`New Population.Feb20`, Population.Feb20), 
           Source.Population.Feb20 = coalesce(Source, Source.Population.Feb20)) %>% 
    select(-`New Population.Feb20`, -Source)

verify_new_fac_info(updated_fac_info)

write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")
