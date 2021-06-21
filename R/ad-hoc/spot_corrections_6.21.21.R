library(tidyverse)
library(behindbarstools)
source("R/utilities.R")

OLD_FAC_INFO <- read_fac_info()
OLD_FAC_SPELLINGS <- read_fac_spellings()

bad_id <- 200

## issues to fix: 
## 200: Pop.Feb20 should be 219 (source http://104.131.72.50:3838/scraper_data/raw_files/2020-02-29_historical_co_pop.pdf)
## 200:	alt spelling "YOS - TRANSFERS D III" should not be mapped there

updated_fac_spellings <- OLD_FAC_SPELLINGS %>%
  filter(!(Facility.ID == 200 & xwalk_name_raw == "YOS - TRANSFERS D III"))
write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE, na = "")

updated_fac_info <- OLD_FAC_INFO %>% 
  mutate(Population.Feb20 = ifelse(Facility.ID == 200,
                       219,
                       Population.Feb20)
  )
write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")