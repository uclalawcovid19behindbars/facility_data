library(tidyverse)
library(behindbarstools)

dat_path <- file.path("~", "UCLA", "code", "facility_data", "data")

# read in files with NA jurisdiction updated by Michael
# on commit/branch: https://github.com/uclalawcovid19behindbars/facility_data/commit/ac622e9f5938dc8ce418ffff6c0e8a36b8435006
na_fix_fac_spellings <- read_csv("https://raw.githubusercontent.com/uclalawcovid19behindbars/facility_data/fix_na_jur/fac_spellings.csv") %>%
  select(Facility.ID,
         State,
         xwalk_name_raw,
         xwalk_name_clean,
         Jurisdiction)
na_fix_fac_data <- read_csv("https://raw.githubusercontent.com/uclalawcovid19behindbars/facility_data/fix_na_jur/fac_data.csv") 

# read in files from main branch 
# on commit: https://github.com/uclalawcovid19behindbars/facility_data/commit/1df844163d8d9a1e2520c1b980034d8df143f562
main_fac_spellings <- read_csv("https://raw.githubusercontent.com/uclalawcovid19behindbars/facility_data/master/data/fac_spellings.csv")
nrow(main_fac_spellings) # 4569
main_fac_data <- read_csv("https://raw.githubusercontent.com/uclalawcovid19behindbars/facility_data/master/data/fac_data.csv")
nrow(main_fac_data) # 1915

# rbind the tables
all_fac_spellings <- bind_rows(na_fix_fac_spellings, main_fac_spellings)
all_fac_data <- bind_rows(na_fix_fac_data, main_fac_data)

## coalesce tables
fac_data_out <- group_by_coalesce(all_fac_data, Facility.ID)
fac_spellings_out <- group_by_coalesce(all_fac_spellings, Facility.ID, State, xwalk_name_raw, xwalk_name_clean)

## sanity check -- left join approach is the same! 
# all_fac_spellings <- left_join(main_fac_spellings,
#                                na_fix_fac_spellings,
#                                by = c("Facility.ID", "State", "xwalk_name_raw", "xwalk_name_clean")) %>%
#   mutate(Jurisdiction = coalesce(Jurisdiction.x, Jurisdiction.y)) %>%
#   select(-Jurisdiction.x,
#          -Jurisdiction.y,
#          -src.x,
#          -src.y) %>%
#   unique() 

# update one facility jurisdiction that Michael missed
fac_spellings_out$Jurisdiction[fac_spellings_out$xwalk_name_clean == "OCC FORDLAND"] <- "state"

occ_fordland <- na_fix_fac_data %>% filter(Name == "OCC FORDLAND")
fac_data_out <- fac_data_out %>%
  add_row(occ_fordland)
fac_data_out$Jurisdiction[fac_data_out$Name == "OCC FORDLAND"] <- "state"

# drop rows with missing critical data
fac_spellings_final <- fac_spellings_out %>%
  filter(!is.na(Jurisdiction)) %>% # drop remaining NA jurisdictions (MN ambiguous ones)
  filter(!is.na(Facility.ID))  %>%    # drop CORRECTIONAL ALTERNATIVES INC RRC SAN DIEGO from na_jur_fix branch
  select(-X1)
  
fac_data_final <- fac_data_out %>%
  filter(!is.na(Jurisdiction)) %>%
  select(-X1)

write_csv(fac_spellings_final, file.path(dat_path, "fac_spellings.csv"))
write_csv(fac_data_final, file.path(dat_path, "fac_data.csv"))


