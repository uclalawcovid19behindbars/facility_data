library(behindbarstools)
library(tidyverse)

updates <- googlesheets4::read_sheet("1UNJurGSVGTBrDaBpyIVvVpgwC4m-iwp3ZwUoNvqj9JQ")

OLD_FAC_INFO <- read_fac_info()

updated_fac_info <- OLD_FAC_INFO %>% 
    left_join(updates %>% select(State, Name, `New Gender`), by = c("Name", "State")) %>% 
    mutate(Gender = coalesce(`New Gender`, Gender)) %>% 
    select(-`New Gender`) 

nrow(OLD_FAC_INFO) == nrow(updated_fac_info) 
ncol(OLD_FAC_INFO) == ncol(updated_fac_info)

write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")