library(tidyverse)
library(behindbarstools)
library(glue)
source("R/utilities.R")

'%!in%' <- function(x,y)!('%in%'(x,y))

OLD_FAC_INFO <- read_fac_info()
OLD_FAC_SPELLINGS <- read_fac_spellings()

# FAC SPELLINGS CHANGES ---------------------------------------------------

## figure out which facilities we want to change
ca_staff_facs <- OLD_FAC_SPELLINGS %>%
  filter(State == "California",
        str_detect(xwalk_name_clean, "(?i)county staff")) %>%
  mutate(county_name = str_remove(xwalk_name_clean, "COUNTY STAFF"),
         county_name = str_squish(county_name)) %>%
  unique() 

## which among these have a "CDCR CCHCS" equivalent?
cdcr_facs <- OLD_FAC_SPELLINGS %>%
  filter(State == "California",
         str_detect(xwalk_name_clean, "(?i)CDCR CCHCS")) %>%
  mutate(county_name = str_remove_all(xwalk_name_clean, "CDCR CCHCS WORKSITE LOCATION |COUNTY"),
         county_name = str_squish(county_name)) %>%
  select(Facility.ID, xwalk_name_clean, Jurisdiction, county_name) %>%
  unique()

## what are the facility IDs of the facilities we're changing? 
matched_ids_to_change <- cdcr_facs %>%
  left_join(ca_staff_facs, by = "county_name") %>%
  filter(!is.na(xwalk_name_raw)) %>%
  pull(Facility.ID.y) %>%
  unique()

## link old county staff facs to correct facility ID #s, xwalk_name_clean
renamed_staff_facs <- cdcr_facs %>%
  left_join(ca_staff_facs, by = "county_name") %>%
  filter(!is.na(xwalk_name_raw)) %>% 
  select(-c(Facility.ID.y, xwalk_name_clean.y, Jurisdiction.y)) %>% 
  select(Facility.ID = Facility.ID.x,
         State,
         xwalk_name_raw,
         xwalk_name_clean = xwalk_name_clean.x,
         Jurisdiction = Jurisdiction.x) 

## find X COUNTY NAME without a CDCR CCHCS equivalent
unmatched_to_change <- cdcr_facs %>% 
  full_join(ca_staff_facs, by = "county_name") %>% 
  filter(is.na(Jurisdiction.x)) %>%
  mutate(xwalk_name_clean = glue('CDCR CCHCS WORKSITE LOCATION {county_name} COUNTY')) %>%
  rename(Facility.ID = Facility.ID.y) %>%
  mutate(Jurisdiction = "state") %>%
  select(Facility.ID,
         State,
         xwalk_name_raw,
         xwalk_name_clean,
         Jurisdiction)

## these are IDs where I'll need to change the clean name and jurisdiction in fac_data 
unmatched_ids_to_change <- cdcr_facs %>% 
  full_join(ca_staff_facs, by = "county_name") %>% 
  filter(is.na(Jurisdiction.x)) %>%
  rename(Facility.ID = Facility.ID.y) %>%
  pull(Facility.ID) %>%
  unique()
  
## rm bad rows from fac_spellings, and add good rows
interim_fac_spellings <- OLD_FAC_SPELLINGS %>%
  filter(Facility.ID %!in% matched_ids_to_change,
         Facility.ID %!in% unmatched_ids_to_change) %>%
  bind_rows(unmatched_to_change) %>%
  bind_rows(renamed_staff_facs) %>%
  ## get rid of wack entry 
  filter(!(xwalk_name_raw == "NAME" & Facility.ID == 105))
  
## check: there should be 12 fewer unique IDs now
n_distinct(OLD_FAC_SPELLINGS$Facility.ID)
n_distinct(interim_fac_spellings$Facility.ID)
assertthat::assert_that(n_distinct(OLD_FAC_SPELLINGS$Facility.ID) - n_distinct(interim_fac_spellings$Facility.ID) == 12)

# FAC DATA CHANGES --------------------------------------------------------
interim_fac_info <- OLD_FAC_INFO %>% 
  filter(Facility.ID %!in% matched_ids_to_change) %>%
  mutate(county_name = str_remove_all(Name, "STAFF|COUNTY"),
         county_name = str_squish(county_name),
         Name = ifelse(Facility.ID %in% unmatched_ids_to_change,
                       glue('CDCR CCHCS WORKSITE LOCATION {county_name} COUNTY'),
                       Name),
         Jurisdiction = ifelse(Facility.ID %in% unmatched_ids_to_change,
                               "state", Jurisdiction))

## check things look good here
# interim_fac_info %>% 
#   select(Facility.ID, Name, county_name, Jurisdiction) %>% 
#   filter(Facility.ID %in% unmatched_ids_to_change) %>% 
#   View()

ids_from_changed_names <- renamed_staff_facs %>% 
  pull(Facility.ID)

## check for other CDCR-like names that don't follow the same format: 
diff_name_pattern <- interim_fac_info %>%
  filter(State == "California",
        str_detect(Name, "(?i)worksite"),
        Facility.ID %!in% ids_from_changed_names,
        Facility.ID %!in% unmatched_ids_to_change) %>%
  mutate(county_name = str_remove_all(Name, "COUNTY WORKSITE LOCATION|COUNTYWORKSITE LOCATION"),
         county_name = str_squish(county_name)) %>%
  select(Name, county_name, Facility.ID)

## which of these did I change in the unmatched ids?
unmatched_already_changed <- cdcr_facs %>% 
  full_join(ca_staff_facs, by = "county_name") %>% 
  filter(is.na(Jurisdiction.x)) %>%
  pull(county_name) %>%
  unique()

## grab facility IDs of the different name patterns to filter out
ids_to_rm_from_diff_name_pattern <- diff_name_pattern %>%
  filter(county_name %in% unmatched_already_changed) %>%
  pull(Facility.ID)

## filter out IDs from bad entries 
## (I add these entries below in fac_spellings)
updated_fac_info <- interim_fac_info %>%
  filter(Facility.ID %!in% ids_to_rm_from_diff_name_pattern)

# FAC SPELLINGS CHANGES.... MORE ! ---------------------------------------------------
diff_name_pattern_spellings_to_fix <- diff_name_pattern %>%
  filter(county_name %in% unmatched_already_changed) %>%
  select(-Facility.ID) 
  
diff_name_spellings_merged <- cdcr_facs %>% 
  full_join(ca_staff_facs, by = "county_name") %>% 
  filter(is.na(Jurisdiction.x)) %>%
  mutate(xwalk_name_clean = glue('CDCR CCHCS WORKSITE LOCATION {county_name} COUNTY')) %>%
  rename(Facility.ID = Facility.ID.y) %>%
  mutate(Jurisdiction = "state") %>%
  select(Facility.ID,
         county_name,
         State,
         xwalk_name_clean,
         Jurisdiction) %>%
  right_join(diff_name_pattern_spellings_to_fix, by = "county_name") %>%
  select(Facility.ID,
         State,
         xwalk_name_raw = Name,
         xwalk_name_clean,
         Jurisdiction)

## add entries from diff name pattern with correctly linked IDs 
## remove bad entries
updated_fac_spellings <- interim_fac_spellings %>%
  bind_rows(diff_name_spellings_merged) %>%
  filter(Facility.ID %!in% ids_to_rm_from_diff_name_pattern)

write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE, na = "")
write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")
