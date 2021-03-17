rm(list=ls())

library(behindbarstools)
library(tidyverse)

old_fac_info <- read_fac_info()
old_fac_spellings <- read_fac_spellings()

updated_fac_info <- old_fac_info %>% 
    rows_update(tibble(Facility.ID = 312, 
                       Name = "ST LUCIE COUNTY JAIL")) %>% 
    rows_update(tibble(Facility.ID = 58, 
                       Population.Feb20 = 5306)) %>% 
    rows_update(tibble(Facility.ID = 135, 
                       Population.Feb20 = 17076)) %>% 
    rows_update(tibble(Facility.ID = 144, 
                       Population.Feb20 = 5074)) %>% 
    rows_update(tibble(Facility.ID = 312, 
                       Population.Feb20 = 808)) %>% 
    rows_update(tibble(Facility.ID = 1579, 
                       Population.Feb20 = 1519)) %>% 
    rows_update(tibble(Facility.ID = 1726, 
                       Population.Feb20 = 3279)) %>% 
    rows_update(tibble(Facility.ID = 1759, 
                       Population.Feb20 = 4780)) %>% 
    rows_update(tibble(Facility.ID = 2075, 
                       Population.Feb20 = 1163)) 

updated_fac_spellings <- old_fac_spellings %>% 
    mutate(xwalk_name_clean = case_when(Facility.ID == 312 ~ "ST LUCIE COUNTY JAIL", 
                                        TRUE ~ xwalk_name_clean))

write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")
write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE, na = "")
   