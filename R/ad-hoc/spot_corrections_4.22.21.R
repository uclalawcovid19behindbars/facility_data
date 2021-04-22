library(tidyverse)
library(behindbarstools)
source("R/utilities.R")

OLD_FAC_INFO <- read_fac_info()
OLD_FAC_SPELLINGS <- read_fac_spellings()

bad_ids <- c(2155, 1939, 735, 733)

updated_fac_spellings <- OLD_FAC_SPELLINGS %>%
    filter(!(xwalk_name_raw == "DIVISION OF COMMUNITY CORRECTIONS TOTAL" 
             & xwalk_name_clean == "STATEWIDE" & State == "Wisconsin")) %>% 
    filter(!(xwalk_name_raw == "VOL OF AMER DALLAS TX HUTCHINS TX" 
             & xwalk_name_clean == "VOLUNTEERS OF AMERICA DALLAS TX")) %>% 
    filter(!Facility.ID %in% bad_ids)

write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE, na = "")
          
updated_fac_info <- OLD_FAC_INFO %>% 
    filter(!Facility.ID %in% bad_ids)
    
write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")