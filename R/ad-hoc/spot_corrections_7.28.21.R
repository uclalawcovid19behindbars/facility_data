library(tidyverse)
library(behindbarstools)
source("R/utilities.R")

OLD_FAC_INFO <- read_fac_info()

## issues to fix: 
## IDS 852 and 871: both NJ facilities should be "adult" rather than "juvenile" because population is ages 18-30 

updated_fac_info <- OLD_FAC_INFO %>% 
  mutate(Age = ifelse(Facility.ID == 852,
                                   "Adult",
                                   Age),
         Age = ifelse(Facility.ID == 871,
                      "Adult",
                      Age)
  )
write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")