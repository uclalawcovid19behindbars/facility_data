library(tidyverse)
library(googlesheets4)
library(tidygeocoder)
library(behindbarstools)

# Read new fac_info entries
read_new_fac_info <- function() {
  google_sheet_url <- "https://docs.google.com/spreadsheets/d/1FqLAwGAugUTTpGSHfFLW4ILrbWPpvhBWsXhJv9CAkFs/edit#gid=0"
  google_sheet_url %>% 
    googlesheets4::read_sheet(sheet = "fac_data") %>% 
    mutate(Name = behindbarstools::clean_fac_col_txt(str_to_upper(Name))) %>% 
    select(
      Facility.ID, 
      State, 
      Name, 
      HIFLD.ID, 
      Address, 
      City, 
      Zipcode, 
      Latitute, 
      Longitude, 
      County, 
      County.FIPS, 
      TYPE, 
      POPULATION, 
      SECURELVL, 
      CAPACITY,
      Website
    ) %>% 
    unique()
}


# Read new fac_spellings entries 
read_new_fac_spellings <- function() {
  google_sheet_url <- "https://docs.google.com/spreadsheets/d/1FqLAwGAugUTTpGSHfFLW4ILrbWPpvhBWsXhJv9CAkFs/edit#gid=0"
  google_sheet_url %>% 
    googlesheets4::read_sheet(sheet = "fac_spellings") %>% 
    mutate(xwalk_name_clean = behindbarstools::clean_fac_col_txt(str_to_upper(facility_name_clean)), 
           xwalk_name_raw = behindbarstools::clean_fac_col_txt(str_to_upper(facility_name_raw))) %>% 
    select(
      Facility.ID, 
      State, 
      xwalk_name_clean, 
      xwalk_name_raw, 
      Source
    ) %>% 
    unique()
}


# Check if valid HIFLD ID 
is_hifld_id <- function(id, hifld_data = NULL) {
  if (is.null(hifld_data)) {
    hifld_data <- behindbarstools::read_hifld_data()
  }
  valid_ids <- hifld_data %>% 
    select(hifld_id) %>% 
    distinct() %>% 
    unlist()
  
  if (is.na(id)) {
    out <- NA 
  } 
  else if (id %in% valid_ids) {
    out <- TRUE
  } 
  else {
    warning(paste0(id, " is not a valid HIFLD."))
    out <- FALSE
  }
  out 
}


# Check if valid state 
is_valid_state <- function(state) {
  valid_states <- datasets::state.name %>% 
    append(c(
      "DC", 
      "Puerto Rico", 
      "Not Available"
    ))
  
  if (is.na(state)){
    out <- NA
  }
  else if (state %in% valid_states) {
    out <- TRUE
  }
  else{
    out <- FALSE
  }
  out
}


# Get all facility names and states 
get_all_facilities <- function(
  fac_info = NULL, fac_spellings = NULL, include_alt = TRUE) {
  
  if (is.null(fac_info)) {
    fac_info <- behindbarstools::read_fac_info()
  }
  if (is.null(fac_spellings)) {
    fac_spellings <- behindbarstools::read_fac_spellings()
  }
  
  fac_data_names <- fac_info %>% 
    select(Name, State) %>% 
    distinct() 
  
  if (! include_alt) {
    fac_data_names
  }
  else {
  fac_spelling_names <- fac_spellings %>% 
    select(xwalk_name_raw, State) %>% 
    distinct() %>% 
    rename(Name = xwalk_name_raw)
  
    rbind(fac_data_names, fac_spelling_names)
  }
}


# Check if facility exists in fac_data or fac_spellings
is_fac_name <- function(
  fac_name, state, fac_info = NULL, fac_spellings = NULL, include_alt = TRUE) {
  
  if (is.null(fac_info)) {
    fac_info <- behindbarstools::read_fac_info()
  }
  if (is.null(fac_spellings)) {
    fac_spellings <- behindbarstools::read_fac_spellings()
  }
  
  names <- get_all_facilities(fac_info, fac_spellings, include_alt) %>%
    filter(State == state) %>% 
    select(Name) %>%
    distinct() %>% 
    unlist()
  
  fac_name %in% names 
}


# Drop (and log) spellings where clean facility name doesn't exist and invalid state names 
verify_new_fac_spellings <- function(
  new_fac_spellings = NULL, old_fac_info = NULL, old_fac_spellings = NULL) {
  
  if (is.null(new_fac_spellings)) {
    new_fac_spellings <- read_new_fac_spellings()
  }
  if (is.null(old_fac_info)) {
    old_fac_info <- behindbarstools::read_fac_info()
  }
  if (is.null(old_fac_spellings)) {
    old_fac_spellings <- behindbarstools::read_fac_spellings()
  }
  
  out <- new_fac_spellings %>% 
    rowwise() %>% 
    mutate(exists = is_fac_name(xwalk_name_clean, State, old_fac_info, old_fac_spellings, include_alt = FALSE),
           valid_state = is_valid_state(State), 
           warning_msg_ = paste0(xwalk_name_clean, " (", State, ")"))
  
  drop <- out %>% 
    filter(exists == FALSE | valid_state == FALSE)
  
  ndrops <- drop %>% nrow()
  if (length(ndrops) > 0) {
    for (i in 1:ndrops) {
      if (drop[i,]$exists == FALSE) {
        warning(paste0("Dropping because clean facility name does not exist in fac_info: ", drop[i,]$warning_msg_))
      }
      if (drop[i,]$valid_state == FALSE) {
        warning(paste0("Dropping because state name is invalid: ", drop[i,]$warning_msg_)) 
      }
    }
  }
  out %>% 
    filter(exists == TRUE & valid_state == TRUE) %>% 
    select(
      -exists, 
      -valid_state, 
      -warning_msg_
    )
}


# Drop (and log) duplicate facilities and invalid state names 
verify_new_fac_info <- function(
  new_fac_info = NULL, old_fac_info = NULL, old_fac_spellings = NULL) {
  
  if (is.null(new_fac_info)) {
    new_fac_info <- read_new_fac_info()
  }
  if (is.null(old_fac_info)) {
    old_fac_info <- behindbarstools::read_fac_info()
  }
  if (is.null(old_fac_spellings)) {
    old_fac_spellings <- behindbarstools::read_fac_spellings()
  }
    
  out <- new_fac_info %>%
    rowwise() %>% 
    mutate(exists = is_fac_name(Name, State, old_fac_info, old_fac_spellings), 
           valid_state = is_valid_state(State), 
           warning_msg_ = paste0(Name, " (", State, ")"))

  drop <- out %>% 
    filter(exists == TRUE | valid_state == FALSE) 
  
  ndrops <- drop %>% nrow()
  if (length(ndrops) > 0) {
    for (i in 1:ndrops) {
      if (drop[i,]$exists == TRUE) {
        warning(paste0("Dropping because facility already exists: ", drop[i,]$warning_msg_))
      }
      if (drop[i,]$valid_state == FALSE) {
        warning(paste0("Dropping because state name is invalid: ", drop[i,]$warning_msg_)) 
      }
    }
  }
  
  out %>% 
    filter(exists == FALSE & valid_state == TRUE) %>% 
    select(
      -exists, 
      -valid_state, 
      -warning_msg_
    )
}


# Pull HIFLD info for a particular field 
pull_hifld_field <- function(id, field, hifld_data = NULL) {
  if (is.null(hifld_data)){
    hifld_data <- read_hifld_data()
  }
  
  if (is.na(id)) {
    out <- NA
  } 
  else if (! is_hifld_id(id, hifld_data)) {
    out <- NA
  } 
  else {
    out <- hifld_data %>% 
      filter(hifld_id == id) %>% 
      pull(field) 
  }
  out
}


# Populate missing info 
populate_new_fac_info <- function(new_fac_info = NULL, hifld_data = NULL) {
  if (is.null(new_fac_info)) {
    new_fac_info <- read_new_fac_info()
  }
  if (is.null(hifld_data)) {
    hifld_data <- read_hifld_data()
  }

  new_fac_info %>%

  # Populate from HIFLD 
  rowwise() %>% 
  mutate(
    Address = coalesce(Address, pull_hifld_field(HIFLD.ID, "ADDRESS", hifld_data)), 
    City = coalesce(City, pull_hifld_field(HIFLD.ID, "CITY", hifld_data)), 
    Zipcode = coalesce(Zipcode, pull_hifld_field(HIFLD.ID, "ZIP", hifld_data)), 
    County = coalesce(County, pull_hifld_field(HIFLD.ID, "COUNTY", hifld_data)), 
    County.FIPS = coalesce(County.FIPS, pull_hifld_field(HIFLD.ID, "COUNTYFIPS", hifld_data)), 
    TYPE = coalesce(TYPE, pull_hifld_field(HIFLD.ID, "TYPE", hifld_data)), 
    POPULATION = coalesce(POPULATION, pull_hifld_field(HIFLD.ID, "POPULATION", hifld_data)), 
    SECURELVL = coalesce(SECURELVL, pull_hifld_field(HIFLD.ID, "SECURELVL", hifld_data)), 
    CAPACITY = coalesce(CAPACITY, pull_hifld_field(HIFLD.ID, "CAPACITY", hifld_data)), 
    Website = coalesce(Website, pull_hifld_field(HIFLD.ID, "WEBSITE", hifld_data))
  ) %>% 
  ungroup() %>%

  # Geocode addresses
  tidygeocoder::geocode(
    street = Address,
    city = City,
    county = County,
    state = State,
    postalcode = Zipcode,
    method = "census",
    lat = "lat_geo_",
    long = "long_geo_"
    ) %>%
  mutate(
    Latitute = coalesce(Latitute, lat_geo_),
    Longitude = coalesce(Longitude, long_geo_)
    ) %>%
  select(-lat_geo_, -long_geo_) %>%

  # Assign Facility.ID
  mutate(Facility.ID = generate_new_fac_id() + row_number() - 1)
}


# Generate next Facility.ID 
# TODO: What do we want this to be called? Count.ID? Facility.ID?
# Should be consistent across read_fac_info(), read_fac_spellings(), these functions, etc. 
generate_new_fac_id <- function(old_fac_info = NULL, old_fac_spellings = NULL) {
  # TODO: Why does behindbarstools::read_fac_info() drop Count.ID? 
  if (is.null(old_fac_info)) {
    # old_fac_info <- behindbarstools::read_fac_info()
    old_fac_info <- "https://raw.githubusercontent.com/uclalawcovid19behindbars" %>%
      str_c("/facility_data/master/data_sheets/fac_data.csv") %>%
      read_csv(col_types = cols()) %>%
      select(-Jurisdiction)
  }
  if (is.null(old_fac_spellings)) {
    old_fac_spellings <- behindbarstools::read_fac_spellings()
  }
  
  max_id <- max(old_fac_info$Count.ID, old_fac_spellings$ID, na.rm = TRUE)
  max_id + 1
}


# Process fac_data 
read_new_fac_info() %>% 
  verify_new_fac_info(
    new_fac_info = ., 
    old_fac_info = behindbarstools::read_fac_info(), 
    old_fac_spellings = behindbarstools::read_fac_spellings()
  ) %>% 
  populate_new_fac_info(
    ., 
    hifld_data = behindbarstools::read_hifld_data()
  ) 
# TODO: update_fac_info()
# TODO: reset_fac_info()

# Process fac_spellings
read_new_fac_spellings() %>% 
  verify_new_fac_spellings() 

# TODO: populate_new_fac_spellings()  
# TODO: update_new_fac_spellings()
# TODO: reset_new_fac_spellings() 
