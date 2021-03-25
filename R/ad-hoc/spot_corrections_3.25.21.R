rm(list = ls())
library(tidyverse)
library(behindbarstools)
source("R/utilities.R")

OLD_FAC_INFO <- read_fac_info()
OLD_FAC_SPELLINGS <- read_fac_spellings()

updated_fac_info <- OLD_FAC_INFO %>%
    rows_update(tibble(Facility.ID = 6,
                       Gender = "Female")) %>% 
    rows_update(tibble(Facility.ID = 119, 
                       State = "Louisiana")) %>% 
    verify_new_fac_info()

write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")


updated_fac_spellings <- OLD_FAC_SPELLINGS %>%
    mutate(State = ifelse(Facility.ID == 119, "Louisiana", State))

write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE, na = "")
