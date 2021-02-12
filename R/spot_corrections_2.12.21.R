rm(list = ls())
library(tidyverse)
library(behindbarstools)
source("R/utilities.R")

OLD_FAC_INFO <- read_fac_info()
OLD_FAC_SPELLINGS <- read_fac_spellings()

## UPDATE FAC INFO 
updated_fac_info <- OLD_FAC_INFO %>%
  rows_update(
    tibble(
      Facility.ID = 718,
      Name = "CENTRAL MISSISSIPPI CORRECTIONAL FACILITY",
      Gender = "Mixed",
      Age = "Mixed"
    )
  ) %>%
  rows_update(
    tibble(
      Facility.ID = 1051,
      State = "Oregon",
      Description = "Transitional Center",
      Address = "6000 NE 80th Ave",
      City = "Portland",
      Zipcode = "97218",
      Latitude = 45.56745525352395,
      Longitude = -122.57882949629663,
    )
  ) %>%
  rows_update(tibble(Facility.ID = 1048,
                     State = "Oregon")) %>%
  rows_update(
    tibble(
      Facility.ID = 448,
      State = "Missouri",
      Address = "2300 E Division St",
      City = "Springfield",
      Zipcode = "65803",
      Latitude = 37.22580565239795,
      Longitude = -93.24936944232807
    )
  ) %>%
  rows_update(
    tibble(
      Facility.ID = 829,
      State = "Virginia",
      Address = "128 Rogers St",
      City = "Lebanon",
      Zipcode = "24266",
      Latitude = 36.90474437107333,
      Longitude = -82.0769545423281
    )
  ) %>%
  rows_update(tibble(Facility.ID = 731,
                     Name = "MISSISSIPPI STATE PENITENTIARY (PARCHMAN)")) %>%
  rows_delete(tibble(Facility.ID = 1064)) %>%
  rows_delete(tibble(Facility.ID = 1033)) %>%
  rows_delete(tibble(Facility.ID = 1035)) %>%
  rows_delete(tibble(Facility.ID = 1051)) %>%
  verify_new_fac_info()

write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")

## UPDATE FAC SPELLINGS 
# sadly, can't use rows_update() because IDs aren't unique
updated_fac_spellings <- OLD_FAC_SPELLINGS %>%
  mutate(xwalk_name_clean = ifelse(Facility.ID == 718,
                                   "CENTRAL MISSISSIPPI CORRECTIONAL FACILITY",
                                   xwalk_name_clean),
         xwalk_name_clean = ifelse(Facility.ID == 731,
                                   "MISSISSIPPI STATE PENITENTIARY (PARCHMAN)",
                                   xwalk_name_clean),
         State = ifelse(Facility.ID == 1051,
                                   "Oregon",
                                   State),
         State = ifelse(Facility.ID == 1048,
                        "Oregon",
                        State),
         State = ifelse(Facility.ID == 448,
                        "Missouri",
                        State),
         State = ifelse(Facility.ID == 829,
                        "Virginia",
                        State),
         ) %>%
  filter(Facility.ID != 1064) %>%
  filter(Facility.ID != 1033) %>%
  filter(Facility.ID != 1035)

write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE, na = "")

