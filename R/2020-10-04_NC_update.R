library(tidyverse)

source("./R/assignment.R")

# Read in old data 
fac_data_old <- read_csv("./data_sheets/fac_data.csv", col_types = cols())
fac_alt_old <- read_csv("./data_sheets/fac_spellings.csv", col_types = cols())

# Create new fac_data entries 
new_data_rows <- fac_data_old[0,] %>% 
  
  # Add HOKE CI
  add_row(
    Count.ID = generate_new_id(fac_data_old), 
    State = "North Carolina", 
    Name = "HOKE CI", 
    Jurisdiction = "Prison", 
    hifld_id = 10001797, 
    Address = "243 OLD HWY 211", 
    City = "RAEFORD", 
    Zipcode = 28376, 
    Latitude = 35.0520132, 
    Longitude = -79.3412791, 
    County = "HOKE", 
    County.FIPS = 37093, 
    TYPE = "STATE", 
    POPULATION = 502, 
    SECURELVL = "MINIMUM", 
    CAPACITY = NA, 
    federal_prison_type = NA, 
    Website = "https://www.ncdps.gov/adult-corrections/prisons/prison-facilities/hoke-correctional-institution"
  ) %>% 
  
  # Add CENTRAL PRISON HCF
  add_row(
    Count.ID = generate_new_id(.), 
    State = "North Carolina", 
    Name = "CENTRAL PRISON HCF", 
    Jurisdiction = "Prison", 
    hifld_id = 10001766, 
    Address = "1300 WESTERN BLVD", 
    City = "RALEIGH", 
    Zipcode = 27606, 
    Latitude = 35.7775454, 
    Longitude = -78.6554932, 
    County = "WAKE", 
    County.FIPS = 37183, 
    TYPE = "STATE", 
    POPULATION = 1104, 
    SECURELVL = "CLOSE", 
    CAPACITY = 752, 
    federal_prison_type = NA, 
    Website = "https://www.ncdps.gov/Adult-Corrections/Prisons/Prison-Facilities/Central-Prison"
  ) %>% 
  
  # Add ROBESON CRV 
  add_row(
    Count.ID = generate_new_id(.), 
    State = "North Carolina", 
    Name = "ROBESON CRV", 
    Jurisdiction = NA, 
    hifld_id = 10001794, 
    Address = "803 NC HWY 711", 
    City = "LUMBERTON", 
    Zipcode = 28360, 
    Latitude = 34.6251147, 
    Longitude = -79.0757916, 
    County = "ROBESON", 
    County.FIPS = 37155, 
    TYPE = "STATE", 
    POPULATION = 145, 
    SECURELVL = "MINIMUM", 
    CAPACITY = 192, 
    federal_prison_type = NA, 
    Website = "https://www.ncdps.gov/adult-corrections/community-corrections/confinement-in-response-to-violation-crv"
  ) 

# Add new facilities to fac_data
fac_data_new <- fac_data_old %>% 
  rbind(new_data_rows)

# Create new alt_data entries 
new_alt_rows <- new_data_rows %>% 
  select(Count.ID, State, Name, City) %>% 
  mutate(
    facility_specific = NA, 
    facility_name_raw = NA, 
    delete = NA
  ) %>% 
  rename(facility_name_clean = Name)

# Add new facilities to alt_data 
drop_cols <- c("...8", "...9", "...10", "X11")
fac_alt_new <- fac_alt_old %>% 
  select(-drop_cols) %>% 
  rbind(new_alt_rows)  

# Update files
write_csv(fac_alt_new, "./data_sheets/fac_spellings.csv")
write_csv(fac_data_new, "./data_sheets/fac_data.csv")


