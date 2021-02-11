library(tidyverse)
library(behindbarstools)
library(docstring)
library(hablar)

# ------------------------------------------------------------------------------
# READ SHEETS 
# ------------------------------------------------------------------------------

read_new_fac_info <- function(google_sheet_url = NULL) {
    #' Read in UCLA facility data updates 
    #'
    #' Reads in new entries for the facility info sheet from Google Sheets.  
    #'
    #' @param google_sheet_url character string URL for the Google Sheet 
    #'
    #' @return data frame 
    
    if (is.null(google_sheet_url)) {
        google_sheet_url <- "1tAhD-brnuqw0s55QXM-xYLPsyD-rNrqHbAVIbxSOMwI"
    }
    
    google_sheet_url %>% 
        googlesheets4::read_sheet(sheet = "fac_data", 
                                  range = readxl::cell_cols("A:X"), 
                                  col_types = "c") %>%
        hablar::convert(
            hablar::chr(
                State, 
                Name, 
                Description, 
                Jurisdiction, 
                Security, 
                Age, 
                Gender, 
                Different.Operator, 
                Source.Population.Feb20, 
                Source.Capacity, 
                Address, 
                City, 
                Zipcode, 
                County, 
                Website, 
                County.FIPS,
                ICE.Field.Office), 
            hablar::dbl(
                Population.Feb20, 
                Capacity, 
                HIFLD.ID, 
                BJS.ID, 
                Latitude, 
                Longitude), 
            hablar::lgl(
                Is.Different.Operator)) %>% 
        mutate(Name = clean_fac_col_txt(Name, to_upper = TRUE)) %>% 
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
        google_sheet_url <- "1tAhD-brnuqw0s55QXM-xYLPsyD-rNrqHbAVIbxSOMwI"
    }
    
    google_sheet_url %>% 
        googlesheets4::read_sheet(sheet = "fac_spellings", 
                                  col_types = "c") %>% 
        mutate(xwalk_name_raw = clean_fac_col_txt(xwalk_name_raw, to_upper = TRUE), 
               xwalk_name_clean = clean_fac_col_txt(xwalk_name_clean, to_upper = TRUE)) %>% 
        unique()
}

# ------------------------------------------------------------------------------
# POPULATE DATA 
# ------------------------------------------------------------------------------

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
        old_fac_info <- read_fac_info()
    }
    if (is.null(old_fac_spellings)) {
        old_fac_spellings <- read_fac_spellings()
    }
    
    max_id <- max(old_fac_info$Facility.ID, old_fac_spellings$Facility.ID, na.rm = TRUE)
    
    return (max_id + 1) 
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

populate_new_fac_info <- function(
    new_fac_info = NULL, old_fac_info = NULL, old_fac_spellings = NULL, hifld_data = NULL) {
    #' Populate new facility data 
    #' 
    #' Populates missing data in the new facility data updates from the HIFLD 
    #' database and by geocoding addresses. Assigns a new facility ID to each entry. 
    #'
    #' @param new_fac_info data frame, new facility info updates
    #' @param old_fac_info data frame, existing facility info  
    #' @param old_fac_spellings data frame, existing facility spellings 
    #' @param hifld_data data frame with HIFLD data 
    #'
    #' @return data frame with missing data populated 
    
    if (is.null(new_fac_info)) {
        new_fac_info <- read_new_fac_info()
    }
    if (is.null(old_fac_info)) {
        old_fac_info <- read_fac_info()
    }
    if (is.null(old_fac_spellings)) {
        old_fac_spellings <- read_fac_spellings()
    }
    if (is.null(hifld_data)) {
        hifld_data <- read_hifld_data()
    }
    
    # Add source to HIFLD for coalesce 
    hifld_data <- hifld_data %>% 
        mutate(population_source = ifelse(is.na(POPULATION), NA, "HIFLD"), 
               capacity_source = ifelse(is.na(CAPACITY), NA, "HIFLD"))
    
    new_fac_info %>%
        # Populate from HIFLD 
        rowwise() %>% 
        mutate(
            Population.Feb20 = coalesce(
                Population.Feb20, 
                pull_hifld_field(HIFLD.ID, "POPULATION", hifld_data)),
            Source.Population.Feb20 = coalesce(
                Source.Population.Feb20, 
                pull_hifld_field(HIFLD.ID, "population_source", hifld_data)), 
            Address = coalesce(
                Address, 
                pull_hifld_field(HIFLD.ID, "ADDRESS", hifld_data)), 
            City = coalesce(
                stringr::str_to_upper(City), 
                pull_hifld_field(HIFLD.ID, "CITY", hifld_data)), 
            Zipcode = coalesce(
                Zipcode, 
                pull_hifld_field(HIFLD.ID, "ZIP", hifld_data)), 
            County = coalesce(
                stringr::str_to_upper(County), 
                pull_hifld_field(HIFLD.ID, "COUNTY", hifld_data)), 
            County.FIPS = coalesce(
                County.FIPS, 
                pull_hifld_field(HIFLD.ID, "COUNTYFIPS", hifld_data)), 
            Capacity = coalesce(
                Capacity, 
                pull_hifld_field(HIFLD.ID, "CAPACITY", hifld_data)), 
            Source.Capacity = coalesce(
                Source.Capacity, 
                pull_hifld_field(HIFLD.ID, "capacity_source", hifld_data)), 
            Website = coalesce(
                Website, 
                pull_hifld_field(HIFLD.ID, "WEBSITE", hifld_data)), 
            Latitude = coalesce(
                Latitude, 
                pull_hifld_field(HIFLD.ID, "lat", hifld_data)), 
            Longitude = coalesce(
                Longitude, 
                pull_hifld_field(HIFLD.ID, "lon", hifld_data))
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
        mutate(Facility.ID = generate_new_fac_id(
            old_fac_info = old_fac_info, 
            old_fac_spellings = old_fac_spellings) + row_number() - 1)
}

populate_new_spellings <- function(
    new_fac_spellings = NULL, old_fac_info = NULL) {
    #' Populate new facility spellings  
    #' 
    #' Assigns the facility ID to each spelling based on the facility info data.  
    #' 
    #' @param new_fac_spellings data frame, new facility spelling updates
    #' @param old_fac_info data frame, existing facility info  
    
    if (is.null(new_fac_spellings)) {
        new_fac_spellings <- read_new_fac_spellings()
    }
    if (is.null(old_fac_info)) {
        old_fac_info <- read_fac_info()
    }

    # Merge federal and ice facilities on cleaned name 
    federal <- new_fac_spellings %>% 
        filter(Jurisdiction %in% c("federal", "immigration")) %>% 
        mutate(name_clean_ = clean_fac_col_txt(xwalk_name_clean, to_upper = TRUE)) %>% 
        select(-State, -Jurisdiction) %>% 
        left_join(old_fac_info %>% 
                      filter(Jurisdiction %in% c("federal", "immigration")) %>% 
                      mutate(name_clean_ = clean_fac_col_txt(Name, to_upper = TRUE)),  
                  by = "name_clean_") %>% 
        select(Facility.ID, xwalk_name_raw, xwalk_name_clean, State, Jurisdiction, Source)

    # Merge county and state facilities on cleaned name AND state 
    non_federal <- new_fac_spellings %>% 
        filter(Jurisdiction %in% c("state", "county")) %>% 
        mutate(name_clean_ = clean_fac_col_txt(xwalk_name_clean, to_upper = TRUE)) %>% 
        select(-Jurisdiction) %>% 
        left_join(old_fac_info %>% 
                      filter(Jurisdiction %in% c("state", "county")) %>% 
                      mutate(name_clean_ = clean_fac_col_txt(Name, to_upper = TRUE)),
                  by = c("name_clean_", "State")) %>% 
        select(Facility.ID, xwalk_name_raw, xwalk_name_clean, State, Jurisdiction, Source)

    return (bind_rows(federal, non_federal))  
}

# ------------------------------------------------------------------------------
# VALIDATE DATA 
# ------------------------------------------------------------------------------

is_valid_jurisdiction <- function(jurisdiction) {
    #' Returns TRUE if the given jurisdiction is valid 
    #' 
    #' Returns TRUE if the given jurisdiction is in the list of valid 
    #' jurisdictions (state, county, federal). 
    #' 
    #' @param jurisdiction character string of the jurisdiction to check 
    #' 
    #' @return logical, TRUE if the given state is a valid jurisdiction 
    
    valid_jurisdictions <- c(
        "state", 
        "county", 
        "federal", 
        "immigration") 
    
    return(jurisdiction %in% valid_jurisdictions)
}

is_valid_description <- function(description) {
    valid_descriptions <- c(
        "Geographic", 
        "Administrative", 
        "Prison", 
        "Jail", 
        "Hybrid", 
        "Reception Center", 
        "Transitional Center", 
        "Medical Facility", 
        "Detention Center", 
        "Prison Unit", 
        "Work Camp", 
        "Aged and Infirmed", 
        "Contractor", 
        NA) 
    
    return(description %in% valid_descriptions)
}

is_valid_security <- function(security) {
    valid_securities <- c(
        "Max", 
        "Med", 
        "Min", 
        "Max/Med", 
        "Max/Min", 
        "Med/Min", 
        NA)
    
    return(security %in% valid_securities)
}

is_valid_age <- function(age) {
    valid_ages <- c(
        "Adult", 
        "Juvenile", 
        "Mixed", 
        NA)
    
    return(age %in% valid_ages)    
}

is_valid_gender <- function(gender) {
    # This refers to our facility data naming conventions 
    # We firmly believe that ALL gender identities (including transgender and non-binary) are valid!!   
    valid_genders <- c(
        "Female", 
        "Male", 
        "Mixed", 
        NA)
    
    return(gender %in% valid_genders)    
}

is_valid_flag <- function(flag) {
    valid_flags <- c(0, 1, NA)
    
    return(flag %in% valid_flags) 
}

# Used for both population and capacity 
is_valid_source <- function(source) {
    valid_sources <- c(
        "HIFLD", 
        "Public Records", 
        NA)
    
    return(source %in% valid_sources)  
}

# Rough check for wildly off coordinates
is_valid_latitude <- function(lat) {
    min_lat <- 15
    max_lat <- 75
    
    if (is.na(lat)) {return (TRUE)}
    return (lat > min_lat & lat < max_lat)
}

is_valid_longitude <- function(lon) {
    min_lon <- -165
    max_lon <- -60
    
    if (is.na(lon)) {return (TRUE)}
    return (lon > min_lon & lon < max_lon)
}

is_valid_id <- function(id, old_fac_info = NULL) {
    if (is.null(old_fac_info)) {
        old_fac_info <- read_fac_info()
    }
    
    valid_ids <- old_fac_info %>% 
        select(Facility.ID) %>% 
        distinct() %>% 
        unlist()
    
    return (id %in% valid_ids)
}

get_custom_warning <- function(text, row, value = NULL) {
    if (is.null(value)) {
        warning(paste0(text, " : ", row$Name, " (", row$State, ")"), call. = FALSE) 
    } 
    else (
        warning(paste0(text, " : ", row$Name, " (", row$State, ")", " : ", value), call. = FALSE) 
    )
} 

verify_new_fac_info <- function(new_fac_info = NULL) {
    #' Verify UCLA facility data updates 
    #'
    #' Logs and drops facility info entries with data validation issues.  
    #'
    #' @param new_fac_info data frame, new facility info updates
    #'
    #' @return data frame, dropping entries with invalid values. 
    
    if (is.null(new_fac_info)) {
        new_fac_info <- read_new_fac_info() 
    }
    
    message(paste("Read", nrow(new_fac_info), "facilities.")) 
    
    out <- new_fac_info %>%
        rowwise() %>% 
        mutate(valid_state_ = is_valid_state(State), 
               valid_jurisdiction_ = is_valid_jurisdiction(Jurisdiction),
               valid_description_ = is_valid_description(Description),
               valid_security_ = is_valid_security(Security), 
               valid_age_ = is_valid_age(Age), 
               valid_gender_ = is_valid_gender(Gender), 
               valid_diff_operator_flag_ = is_valid_flag(Is.Different.Operator), 
               valid_source_pop_ = is_valid_source(Source.Population.Feb20), 
               valid_source_cap_ = is_valid_source(Source.Capacity),  
               valid_lat_ = is_valid_latitude(Latitude),
               valid_long_ = is_valid_longitude(Longitude), 
               drop_ = ifelse(valid_state_ == FALSE
                              | valid_jurisdiction_ == FALSE
                              | valid_description_ == FALSE 
                              | valid_security_ == FALSE 
                              | valid_age_ == FALSE 
                              | valid_gender_ == FALSE 
                              | valid_diff_operator_flag_ == FALSE 
                              | valid_source_pop_ == FALSE 
                              | valid_source_cap_ == FALSE 
                              | valid_lat_ == FALSE 
                              | valid_long_ == FALSE, 
                              TRUE, FALSE)) 
    
    ndrops <- nrow(out %>% filter(drop_))
    if (ndrops > 0) {
        warning(paste("Dropping", ndrops, "rows."))
        for(i in 1:nrow(out)) {
            row <- out[i,]
            if (!row$valid_state_) {
                get_custom_warning("State name is invalid", row, row$State)}
            if (!row$valid_jurisdiction_) {
                get_custom_warning("Jurisdiction is invalid", row, row$Jurisdiction)}
            if (!row$valid_description_) {
                get_custom_warning("Description is invalid", row, row$Description)}
            if (!row$valid_security_) {
                get_custom_warning("Security is invalid", row, row$Security)}
            if (!row$valid_age_) {
                get_custom_warning("Age is invalid", row, row$Age)}
            if (!row$valid_gender_) {
                get_custom_warning("Gender is invalid", row, row$Gender)}
            if (!row$valid_diff_operator_flag_) {
                get_custom_warning("Different operator flag is invalid", row, row$Is.Different.Operator)} 
            if (!row$valid_source_pop_) {
                get_custom_warning("Population source is invalid", row, row$Source.Population.Feb20)} 
            if (!row$valid_source_cap_) {
                get_custom_warning("Capacity source is invalid", row, row$Source.Capacity)} 
            if (!row$valid_lat_) {
                get_custom_warning("Latitude is invalid", row, row$Latitude)}
            if (!row$valid_long_) {
                get_custom_warning("Longitude is invalid", row, row$Longitude)}
            }}
    
    out <- out %>% 
        filter(drop_ %in% c(NA, FALSE)) %>% 
        select(Facility.ID, State, Name, Jurisdiction, Description, Security,
               Age, Gender, Is.Different.Operator, Different.Operator, Population.Feb20,
               Capacity, HIFLD.ID, BJS.ID, Source.Population.Feb20, Source.Capacity, Address,
               City, Zipcode, Latitude, Longitude, County, County.FIPS, Website, ICE.Field.Office)
    
    # Check for duplicate IDs 
    if (length(unique(out$Facility.ID)) != length(out$Facility.ID)) {
        dupes <- out %>% 
            group_by(Facility.ID) %>% 
            summarise(n = n()) %>% 
            filter(n > 1) %>% 
            pull(Facility.ID)
        
        warning(paste0("Duplicated Facility IDs found : ", dupes), call. = FALSE)
    }
    
    message(paste("Verified", nrow(out), "facilities.")) 
    
    return (out)
}

verify_new_fac_spellings <- function(new_fac_spellings = NULL, old_fac_info = NULL) {
    #' Verify UCLA facility spellings updates 
    #'
    #' Logs and drops facility spelling entries with invalid state names or without 
    #' corresponding matches in the facility info sheet. This should be run AFTER 
    #' updating the facility info sheet for a given batch of crosswalk updates. 
    #'
    #' @param new_fac_spellings data frame, new facility spelling updates
    #' @param old_fac_info data frame, existing facility info  
    #'
    #' @return data frame, dropping entries with invalid state names or without 
    #' matches in the facility info sheet. 
    
    if (is.null(new_fac_spellings)) {
        new_fac_spellings <- read_new_fac_spellings()
    }
    if (is.null(old_fac_info)) {
        old_fac_info <- read_fac_info()
    }
    
    message(paste("Read", nrow(new_fac_spellings), "alternative spellings.")) 
    
    out <- new_fac_spellings %>% 
        rowwise() %>% 
        mutate(valid_id_ = is_valid_id(Facility.ID, old_fac_info), 
               valid_name_ = is_fac_name(xwalk_name_clean, State, old_fac_info, new_fac_spellings, include_alt = FALSE),
               valid_state_ = is_valid_state(State), 
               Name = xwalk_name_clean, 
               valid_jurisdiction_ = is_valid_jurisdiction(Jurisdiction), 
               drop_ = ifelse(valid_id_ == FALSE
                              | valid_name_ == FALSE 
                              | valid_state_ == FALSE  
                              | valid_jurisdiction_ == FALSE, 
                              TRUE, FALSE))
    
    ndrops <- nrow(out %>% filter(drop_))
    if (ndrops > 0) {
        warning(paste("Dropping", ndrops, "rows."))
        for(i in 1:nrow(out)) {
            row <- out[i,]
            if (!row$valid_id_) {
                get_custom_warning("Facility ID does not exist in fac_info", row, row$Facility.ID)}
            if (!row$valid_name_) {
                get_custom_warning("Clean name does not exist in fac_info", row)} 
            if (!row$valid_state_) {
                get_custom_warning("State name is invalid", row, row$State)}
            if (!row$valid_jurisdiction_) {
                get_custom_warning("Jurisdiction is invalid", row, row$Jurisdiction)}
        }}
    
    out <- out %>% 
        filter(drop_ %in% c(NA, FALSE)) %>% 
        select(Facility.ID, State, xwalk_name_raw, xwalk_name_clean, Jurisdiction)
    
    message(paste("Verified", nrow(out), "alternative spellings.")) 
    
    return (out)
} 

# ------------------------------------------------------------------------------
# UPDATE DATA 
# ------------------------------------------------------------------------------

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
        old_fac_info <- read_fac_info()
    }
    
    out <- old_fac_info %>% 
        bind_rows(new_fac_info) 
    
    message(paste("New facility info crosswalk contains", nrow(out), "facilities."))
    
    return (out)
} 

update_fac_spellings <- function(
    new_fac_spellings, old_fac_spellings = NULL, old_fac_info = NULL) {
    #' Update UCLA facility spellings 
    #' 
    #' Updates the UCLA facility alternative spellings sheet by combining the 
    #' existing sheet with the new entries. 
    #'
    #' @param new_fac_spellings data frame, new facility spelling updates
    #' @param old_fac_spellings data frame, existing facility spellings 
    #' #' @param old_fac_info data frame, existing facility info  
    #' 
    #' @return data frame, combining existing and new spellings  
    
    if (is.null(old_fac_spellings)) {
        old_fac_info <- read_fac_spellings()
    }
    if (is.null(old_fac_info)) {
        old_fac_info <- read_fac_info()
    }
    
    dirty_spellings <- old_fac_spellings %>% 
        bind_rows(new_fac_spellings) %>% 
        select(Facility.ID, State, xwalk_name_raw, xwalk_name_clean, Jurisdiction)
    
    clean_spellings <- old_fac_info %>% 
        mutate(xwalk_name_raw = Name, 
               xwalk_name_clean = Name) %>% 
        select(Facility.ID, State, xwalk_name_raw, xwalk_name_clean, Jurisdiction)
    
    out <- bind_rows(dirty_spellings, clean_spellings) %>% 
        unique() 
    
    message(paste("New facility spellings crosswalk contains", nrow(out), "spellings"))
    
    return (out)
}
