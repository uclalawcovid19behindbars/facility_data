# Script to add facilities to the info and spe
rm(list=ls())
library(tidyverse)
library(behindbarstools)

# should we save changes
DRY_RUN <- TRUE

fac_data <- "./data/fac_data.csv" %>%
    read_csv(col_types = cols(
        Facility.ID = "d",
        State = "c",
        Name = "c",
        Description = "c",
        Security = "c",
        Age = "c",
        Gender = "c",
        Is.Different.Operator = "l",
        Different.Operator = "c",
        Population.Feb20 = "d",
        Capacity = "d",
        HIFLD.ID = "d",
        BJS.ID = "d",
        Source.Population.Feb20 = "c",
        Source.Capacity = "c",
        Address = "c",
        City = "c",
        Zipcode = "c",
        Latitude = "d",
        Longitude = "d",
        County = "c",
        County.FIPS = "c",
        Website = "c",
        Jurisdiction = "c"))

ice_fo_df <- read_csv("./data/ice_tmp_data.csv", col_types = cols())

if(!DRY_RUN){
    fac_data %>%
        # add on the new data 
        left_join(ice_fo_df, by = "Facility.ID") %>%
        # take advantage of the new Gender data provided by ICE
        mutate(Gender = ifelse(
            Jurisdiction == "immigration", Gender.New, Gender)) %>%
        # take advantage of the new population data provided by ICE
        mutate(Population.Feb20 = ifelse(
            Jurisdiction == "immigration",
            Population.Feb20.New, Population.Feb20)) %>%
        # make website source consistent
        mutate(Website = ifelse(
            Jurisdiction == "immigration",
            "https://www.ice.gov/coronavirus", Website)) %>%
        # remove extra columns
        select(-Gender.New, -Population.Feb20.New) %>%
        write.csv("data/fac_data.csv", row.names = FALSE, na = "")
}
