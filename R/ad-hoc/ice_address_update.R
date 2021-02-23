rm(list=ls())
library(tidyverse)
library(googlesheets4)
library(behindbarstools)
library(tigris)
library(sf)

# read in the new updates 
df_update <- read_sheet("1oTTKeyiPPXJnjNI5ZzxQFlsb6G49xk-VUSacZPwNCGI", 2) %>%
    select(State, Name, Jurisdiction, Address, City, Zipcode)
# read the old data
df_old <- read_fac_info()
# make sure we know the old column order and appropriate var names
col_order <- names(df_old)

# get non immigration data as a separate dataset that we wont touch
df_non_ice <- df_old %>%
    filter(Jurisdiction != "immigration")

# edit the current immigration data
df_ice_raw <- df_old %>%
    filter(Jurisdiction == "immigration") %>%
    # remove old address info
    select(-Address, -City, -Zipcode) %>%
    # add in the updates
    left_join(df_update) %>%
    # recode this facility which had the wrong state associated with it
    rows_update(
        tibble(
            `Facility.ID` = 1796,
             State = "Nebraska"
        )) %>%
    select(-Latitude, -Longitude) %>%
    # new geocode for icedata
    tidygeocoder::geocode(
        method = "geocodio",
        street = Address,
        city = City,
        state = State,
        postalcode = Zipcode,
        lat = "Latitude",
        long = "Longitude"
    )

# need to make a change to the speelings as well
df_spell <- read_fac_spellings() %>%
    # recode this facility which had the wrong state associated with it
    mutate(State = ifelse(`Facility.ID` == 1796, "Nebraska", State))

# next we want to add in county information to ice data
county_sf <- counties(class = "sf") %>%
    select(County = NAME, County.FIPS = GEOID, geometry, STATEFP)

# grab state name identifiers as a sanity check
state_df <- states(class = "sf") %>%
    as_tibble() %>%
    select(STATEFP, STATENAME = NAME)

# start with raw ice data
over_sf <- filter(df_ice_raw, !is.na(Latitude)) %>%
    # convert to spatial sf object
    st_as_sf(coords = c("Longitude", "Latitude"), crs = "NAD83") %>%
    # keep only relevant vars
    select(Facility.ID, State, geometry) %>%
    # do the overlap with the county shape file
    st_join(county_sf) %>%
    # merge on state for sanity check
    left_join(state_df)

# did anything go horribly wrong? We can tell if state names dont match
if(any(over_sf$State != over_sf$STATENAME)){
    stop("Something went horribly wrong with geocoding")
}

# finally add in the new county level information
df_ice <- df_ice_raw %>%
    select(-County, County.FIPS) %>%
    left_join(
        over_sf %>%
            as_tibble() %>%
            select(Facility.ID, County, County.FIPS),
        by = "Facility.ID")

# put the ice data back with the none ice data
df_new <- df_non_ice %>%
    bind_rows(mutate(df_ice, Zipcode = as.character(Zipcode))) %>%
    select(!!col_order)

# check to make sure the dims match
if(nrow(df_old) != nrow(df_new)){
    stop("Something went horribly wrong with adding rows")
}

if(ncol(df_old) != ncol(df_new)){
    stop("Something went horribly wrong with adding cols")
}

write.csv(df_new, "data/fac_data.csv", row.names = FALSE, na = "")
write.csv(df_spell, "data/fac_spellings.csv", row.names = FALSE, na = "")