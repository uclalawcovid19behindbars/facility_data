library(tidyverse)
library(behindbarstools)
source("R/utilities.R")

OLD_FAC_INFO <- read_fac_info()
OLD_FAC_SPELLINGS <- read_fac_spellings()

## issues to fix: 
## 2563: rename it "Miami Youth Academy" 
## 2553: Get rid of it (duplicative) 2553

updated_fac_spellings <- OLD_FAC_SPELLINGS %>%
  mutate(xwalk_name_clean = ifelse(Facility.ID == 2563,
                                   "MIAMI YOUTH ACADEMY",
                                   xwalk_name_clean)) %>%
  filter(Facility.ID != 2553)
write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE, na = "")

updated_fac_info <- OLD_FAC_INFO %>% 
  mutate(Name = ifelse(Facility.ID == 2563,
                                   "MIAMI YOUTH ACADEMY",
                                   Name)) %>%
  filter(Facility.ID != 2553)

write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")