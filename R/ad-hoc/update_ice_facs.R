# Script to add facilities to the info and spe
rm(list=ls())
library(tidyverse)
library(behindbarstools)

# should we save changes
DRY_RUN <- TRUE

str_word_detect <- function(string, pattern){
    str_detect(string, str_c(" ", pattern, " ")) |
        str_starts(string, str_c(pattern, " ")) |
        str_ends(string, str_c(" ", pattern))
}

# pull in Vera data for reference from a specific commit so we get
# the same data
vera_fac_df <- str_c(
    "https://raw.githubusercontent.com/vera-institute/ice-detention-covid/",
    "944d9db03780fe7261e69a06354ae5dfd8422e8c/metadata/facility_lookup.csv") %>%
    read_csv(col_types = cols()) %>%
# add ice to every facility
    mutate(facility_listed = ifelse(
        str_word_detect(facility_listed, "ICE"),
        facility_listed,
        str_c("ICE ", facility_listed))) %>%
    mutate(facility_name = ifelse(
        str_word_detect(facility_name, "ICE"),
        facility_name,
        str_c("ICE ", facility_name))) %>%
    filter(!is.na(facility_name)) %>%
    mutate(State = translate_state(state)) %>%
    mutate(State = ifelse(state == "PR", "Puerto Rico", State)) %>%
    mutate(facility_name = clean_fac_col_txt(facility_name, TRUE)) %>%
    mutate(facility_listed = clean_fac_col_txt(facility_listed, TRUE))

# load in the current fac_info_sheet
old_fac_data_df <- read_csv("data/fac_data.csv", col_types = cols())
# load in current spellings
old_fac_spell_df <- read_csv("data/fac_spellings.csv", col_types = cols())

# did we already add in the immigration data?
ICE_ADDED <- "immigration" %in% old_fac_data_df$Jurisdiction

# old max ID
max_id <- max(old_fac_data_df$Facility.ID)

# get the new ice data for the data sheet
new_ice_info <- vera_fac_df %>%
    select(State, Name = facility_name, Latitude = lat, Longitude = lng) %>%
    distinct(State, Name, .keep_all = TRUE) %>%
    bind_rows(tibble(
        Name = "ALL ICE FACILITIES", State = "Not Available")) %>%
    mutate(Website = "https://www.ice.gov/coronavirus") %>%
    mutate(Jurisdiction = "immigration") %>%
    unique() %>%
    mutate(Facility.ID = 1:n() + max_id)

# get the new ice data for the spellings sheetR
new_ice_cw <- vera_fac_df %>%
    select(
        State, xwalk_name_raw = facility_listed, 
        xwalk_name_clean = facility_name) %>%
    unique() %>%
    bind_rows(tibble(
        xwalk_name_clean = "ALL ICE FACILITIES",
        xwalk_name_raw = "ALL ICE FACILITIES",
        State = "Not Available")) %>%
    left_join(
        select(new_ice_info, xwalk_name_clean = Name, Facility.ID),
        by = "xwalk_name_clean"
    ) %>%
    mutate(Is.Federal = 1) %>%
    mutate(Source = NA) %>%
    select(
        Facility.ID, State, xwalk_name_raw,
        xwalk_name_clean, Source, Is.Federal)

if(!all(new_ice_cw$xwalk_name_clean %in% new_ice_info$Name)){
    stop("Some names appear in the cw that do not appear in the info sheet")
}

# merge the data sets together
new_fac_data_df <- bind_rows(old_fac_data_df, new_ice_info) %>%
    filter(Jurisdiction == "immigration")
new_fac_spell_df <- bind_rows(old_fac_spell_df, new_ice_cw) %>%
    filter(Facility.ID %in% new_fac_data_df$Facility.ID)

# write new data only if the flag of the dry run has been set to FALSE
if(!DRY_RUN & !ICE_ADDED){
    write.table(
        new_fac_data_df, "data/fac_data.csv", append = TRUE,  sep = ",",
        col.names = FALSE, row.names = FALSE)
    write.table(
        new_fac_spell_df, "data/fac_spellings.csv", append = TRUE, sep = ",",
        col.names = FALSE, row.names = FALSE)
}
