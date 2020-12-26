library(tidyverse)
library(behindbarstools)
library(docstring)

read_new_fac_info <- function(google_sheet_url = NULL) {
    #' Read in UCLA facility data updates 
    #'
    #' Reads in new entries for the facility info sheet from Google Sheets.  
    #'
    #' @param google_sheet_url character string URL for the Google Sheet 
    #'
    #' @return data frame 
    
    if (is.null(google_sheet_url)) {
        google_sheet_url <- "https://docs.google.com/spreadsheets/d/1tAhD-brnuqw0s55QXM-xYLPsyD-rNrqHbAVIbxSOMwI/edit#gid=1597803218"
    }
    
    google_sheet_url %>% 
        googlesheets4::read_sheet(sheet = "fac_data") %>% 
        mutate(Name = behindbarstools::clean_fac_col_txt(Name, to_upper = TRUE)) %>% 
        mutate_at(
            vars(State, 
                 Name, 
                 Jurisdiction, 
                 Designation, 
                 Address, 
                 City, 
                 Zipcode, 
                 County, 
                 County.FIPS, 
                 Security.Level, 
                 Website), 
            as.character) %>% 
        mutate_at(
            vars(HIFLD.ID, 
                 Population.Feb, 
                 Latitude, 
                 Longitude,
                 Capacity), 
            as.numeric) %>% 
        unique()
}

read_new_fac_spellings <- function(google_sheet_url = NULL) {
    #' Read in UCLA facility spellings updates 
    #'
    #' Reads in new entries for the facility alternative spellings sheet from Google Sheets.  
    #'
    #' @param google_sheet_url character string URL for the Google Sheet 
    #'
    #' @return data frame 
    
    if (is.null(google_sheet_url)) {
        google_sheet_url <- "https://docs.google.com/spreadsheets/d/1tAhD-brnuqw0s55QXM-xYLPsyD-rNrqHbAVIbxSOMwI/edit#gid=1597803218"
    }
    
    google_sheet_url %>% 
        googlesheets4::read_sheet(sheet = "fac_spellings") %>% 
        mutate(xwalk_name_raw = behindbarstools::clean_fac_col_txt(xwalk_name_raw, to_upper = TRUE), 
               xwalk_name_clean = behindbarstools::clean_fac_col_txt(xwalk_name_clean, to_upper = TRUE)) %>% 
        select(
            State, 
            xwalk_name_raw, 
            xwalk_name_clean, 
            Source
        ) %>% 
        unique()
}

verify_new_fac_info <- function(
    new_fac_info = NULL, old_fac_info = NULL, old_fac_spellings = NULL) {
    #' Verify UCLA facility data updates 
    #'
    #' Logs and drops facility info entries with invalid state names or that are 
    #' duplicates (i.e. perfect matches after basic string cleaning) to existing 
    #' entries in the facility info sheet. 
    #'
    #' @param new_fac_info data frame, new facility info updates
    #' @param old_fac_info data frame, existing facility info  
    #' @param old_fac_spellings data frame, existing facility spellings 
    #'
    #' @return data frame, dropping entries with invalid state names or that duplicate 
    #' facilities in the existing facility info sheet. 
    
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
        mutate(exists_ = behindbarstools::is_fac_name(Name, State, old_fac_info, old_fac_spellings), 
               valid_state_ = behindbarstools::is_valid_state(State), 
               warning_msg_ = paste0(Name, " (", State, ")"))
    
    drop <- out %>% 
        filter(exists_ == TRUE | valid_state_ == FALSE) 
    
    if (length(nrow(drop)) > 0) {
        for (i in 1:nrow(drop)) {
            if (drop[i,]$exists_ == TRUE) {
                warning(stringr::str_c(
                    "Dropping because facility already exists: ", drop[i,]$warning_msg_))
            }
            if (drop[i,]$valid_state_ == FALSE) {
                warning(stringr::str_c(
                    "Dropping because state name is invalid: ", drop[i,]$warning_msg_)) 
            }
        }
    }
    
    out %>% 
        filter(exists_ == FALSE & valid_state_ == TRUE) %>% 
        select(
            -exists_, 
            -valid_state_, 
            -warning_msg_
        )
}

verify_new_fac_spellings <- function(
    new_fac_spellings = NULL, old_fac_info = NULL, old_fac_spellings = NULL) {
    #' Verify UCLA facility spellings updates 
    #'
    #' Logs and drops facility spelling entries with invalid state names or without 
    #' corresponding matches in the facility info sheet. This should be run AFTER 
    #' updating the facility info sheet for a given batch of crosswalk updates. 
    #'
    #' @param new_fac_spellings data frame, new facility spelling updates
    #' @param old_fac_info data frame, existing facility info  
    #' @param old_fac_spellings data frame, existing facility spellings 
    #'
    #' @return data frame, dropping entries with invalid state names or without 
    #' matches in the facility info sheet. 
    
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
        mutate(exists_ = behindbarstools::is_fac_name(xwalk_name_clean, State, old_fac_info, old_fac_spellings, include_alt = FALSE),
               valid_state_ = behindbarstools::is_valid_state(State), 
               warning_msg_ = paste0(xwalk_name_clean, " (", State, ")"))
    
    drop <- out %>% 
        filter(exists_ == FALSE | valid_state_ == FALSE)
    
    if (length(nrow(drop)) > 0) {
        for (i in 1:nrow(drop)) {
            if (drop[i,]$exists_ == FALSE) {
                warning(stringr::str_c(
                    "Dropping because clean facility name does not exist in fac_info: ", drop[i,]$warning_msg_))
            }
            if (drop[i,]$valid_state_ == FALSE) {
                warning(stringr::str_c(
                    "Dropping because state name is invalid: ", drop[i,]$warning_msg_)) 
            }
        }
    }
    
    out %>% 
        filter(exists_ == TRUE & valid_state_ == TRUE) %>% 
        select(
            -exists_, 
            -valid_state_, 
            -warning_msg_
        )
}

generate_new_fac_id <- function(old_fac_info = NULL, old_fac_spellings = NULL) {
    #' Generate next facility ID 
    #' 
    #' Generates the next facility ID by adding one to the largest existing ID. 
    #'
    #' @param old_fac_info data frame, existing facility info  
    #' @param old_fac_spellings data frame, existing facility spellings 
    #'
    #' @return
    
    if (is.null(old_fac_info)) {
        old_fac_info <- behindbarstools::read_fac_info()
    }
    if (is.null(old_fac_spellings)) {
        old_fac_spellings <- behindbarstools::read_fac_spellings()
    }
    
    max_id <- max(old_fac_info$Facility.ID, old_fac_spellings$Facility.ID, na.rm = TRUE)
    return (max_id + 1) 
}

populate_new_fac_info <- function(new_fac_info = NULL, hifld_data = NULL) {
    #' Populate new facility data 
    #' 
    #' Populates missing data in the new facility data updates from the HIFLD 
    #' database and by geocoding addresses. Assigns a new facility ID to each entry. 
    #'
    #' @param new_fac_info data frame, new facility info updates
    #' @param hifld_data data frame with HIFLD data 
    #'
    #' @return data frame with missing data populated 
    
    if (is.null(new_fac_info)) {
        new_fac_info <- read_new_fac_info()
    }
    if (is.null(hifld_data)) {
        hifld_data <- behindbarstools::read_hifld_data()
    }
    
    new_fac_info %>%
        # Populate from HIFLD 
        rowwise() %>% 
        mutate(
            Population.Feb = coalesce(
                Population.Feb, 
                pull_hifld_field(HIFLD.ID, "POPULATION", hifld_data)),
            Address = coalesce(
                Address, 
                pull_hifld_field(HIFLD.ID, "ADDRESS", hifld_data)), 
            City = coalesce(
                City, 
                pull_hifld_field(HIFLD.ID, "CITY", hifld_data)), 
            Zipcode = coalesce(
                Zipcode, 
                pull_hifld_field(HIFLD.ID, "ZIP", hifld_data)), 
            County = coalesce(
                County, 
                pull_hifld_field(HIFLD.ID, "COUNTY", hifld_data)), 
            County.FIPS = coalesce(
                County.FIPS, 
                pull_hifld_field(HIFLD.ID, "COUNTYFIPS", hifld_data)), 
            Security.Level = coalesce(
                Security.Level, 
                pull_hifld_field(HIFLD.ID, "SECURELVL", hifld_data)), 
            Capacity = coalesce(
                Capacity, 
                pull_hifld_field(HIFLD.ID, "CAPACITY", hifld_data)), 
            Website = coalesce(
                Website, 
                pull_hifld_field(HIFLD.ID, "WEBSITE", hifld_data))
        ) %>% 
        ungroup() %>%
        # Geocode addresses
        tidygeocoder::geocode(
            method = "geocodio", 
            street = Address,
            city = City,
            county = County,
            state = State,
            postalcode = Zipcode,
            lat = "lat_geo_",
            long = "long_geo_"
        ) %>%
        mutate(
            Latitude = coalesce(Latitude, lat_geo_),
            Longitude = coalesce(Longitude, long_geo_)
        ) %>%
        select(-lat_geo_, -long_geo_) %>%
        # Assign Facility.ID
        mutate(Facility.ID = generate_new_fac_id() + row_number() - 1)
}

pull_hifld_field <- function(id, field, hifld_data = NULL) {
    #' Get HIFLD data for a single field and ID  
    #'
    #' @param id integer HIFLD ID 
    #' @param field character string for the HIFLD field to pull data from 
    #' @param hifld_data data frame with HIFLD data 
    #'
    #' @return value for the given field and ID 
    #'
    #' @examples
    #' pull_hifld_field(10002798, "CITY")
    
    if (is.null(hifld_data)) {
        hifld_data <- read_hifld_data()
    }
    
    if (is.na(id)) {out <- NA} 
    else if (! is_hifld_id(id, hifld_data)) {out <- NA} 
    else {
        out <- hifld_data %>% 
            filter(hifld_id == id) %>% 
            pull(field) 
    }
    return (out)
}

update_fac_info <- function(new_fac_info, old_fac_info = NULL) {
    #' Update UCLA facility data 
    #' 
    #' Updates the UCLA facility info sheet by combining the existing sheet with 
    #' the new entries. 
    #'
    #' @param new_fac_info data frame, new facility info updates
    #' @param old_fac_info data frame, existing facility info  
    #' 
    #' @return data frame, combining existing and new facilities  

    if (is.null(old_fac_info)) {
        old_fac_info <- behindbarstools::read_fac_info()
    }
    
    out <- old_fac_info %>% 
        bind_rows(new_fac_info)
    
    message(paste("Adding", nrow(new_fac_info), "facilities.")) 
    message(paste("New facility info crosswalk contains", nrow(out), "facilities."))
    
    return (out)
} 

update_fac_spellings <- function(new_fac_spellings, old_fac_spellings = NULL) {
    #' Update UCLA facility spellings 
    #' 
    #' Updates the UCLA facility alternative spellings sheet by combining the 
    #' existing sheet with the new entries. 
    #'
    #' @param new_fac_spellings data frame, new facility spelling updates
    #' @param old_fac_spellings data frame, existing facility spellings 
    #' 
    #' @return data frame, combining existing and new spellings  

    if (is.null(old_fac_spellings)) {
        old_fac_info <- behindbarstools::read_fac_spellings()
    }
    
    out <- old_fac_spellings %>% 
        bind_rows(new_fac_spellings)
    
    message(paste("Adding", nrow(new_fac_spellings), "alternative spellings")) 
    message(paste("New facility spellings crosswalk contains", nrow(out), "spellings"))
    
    return (out)
}