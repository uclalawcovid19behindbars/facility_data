rm(list = ls())
library(tidyverse)
library(behindbarstools)
source("R/utilities.R")

OLD_FAC_INFO <- read_fac_info()
OLD_FAC_SPELLINGS <- read_fac_spellings()

## UPDATE FAC INFO 
updated_fac_info <- OLD_FAC_INFO %>%
  rows_update(tibble(Facility.ID = 523,
                     Name = "VOLUNTEERS OF AMERICA INC RRC INDIANAPOLIS")) %>%
  rows_update(tibble(Facility.ID = 879,
                     Name = "OTERO COUNTY PRISON FACILITY RRC CHAPARRAL")) %>%
  rows_update(tibble(Facility.ID = 1250,
                     Name = "DIERSEN CHARITIES MEMPHIS")) %>%
  rows_delete(tibble(Facility.ID = 2052)) %>%
  verify_new_fac_info()

write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")

## UPDATE FAC SPELLINGS 
# sadly, can't use rows_update() because IDs aren't unique
updated_fac_spellings <- OLD_FAC_SPELLINGS %>%
  mutate(xwalk_name_clean = ifelse(Facility.ID == 523,
                                   "VOLUNTEERS OF AMERICA INC RRC INDIANAPOLIS",
                                   xwalk_name_clean),
         xwalk_name_clean = ifelse(Facility.ID == 879,
                                   "OTERO COUNTY PRISON FACILITY RRC CHAPARRAL",
                                   xwalk_name_clean),
         xwalk_name_clean = ifelse(Facility.ID == 1250,
                                   "DIERSEN CHARITIES MEMPHIS",
                                   xwalk_name_clean),
         Facility.ID = ifelse(Facility.ID == 2052,
                              1736,
                              Facility.ID)
  ) 

write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE, na = "")