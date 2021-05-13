library(tidyverse)
library(behindbarstools)
source("R/utilities.R")

OLD_FAC_INFO <- read_fac_info()
OLD_FAC_SPELLINGS <- read_fac_spellings()

bad_ids <- c(1269, 1210)

## issues to fix: 
## 1269	Tennessee	WHITEVILLE CORRECTIONAL FACILTY (misspelled)
## 1210	South Carolina	CAMILLE GRAHAM CORRECITONAL INSTITUTION (misspelled)

updated_fac_spellings <- OLD_FAC_SPELLINGS %>%
  mutate(xwalk_name_clean = ifelse(Facility.ID == 1269,
                                   "WHITEVILLE CORRECTIONAL FACILITY",
                                   xwalk_name_clean),
         xwalk_name_clean = ifelse(Facility.ID == 1210,
                                   "CAMILLE GRAHAM CORRECTIONAL INSTITUTION",
                                   xwalk_name_clean),
         )
write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE, na = "")

updated_fac_info <- OLD_FAC_INFO %>% 
  mutate(Name = ifelse(Facility.ID == 1269,
                                   "WHITEVILLE CORRECTIONAL FACILITY",
                                   Name),
         Name = ifelse(Facility.ID == 1210,
                                   "CAMILLE GRAHAM CORRECTIONAL INSTITUTION",
                                   Name),
  )

write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")