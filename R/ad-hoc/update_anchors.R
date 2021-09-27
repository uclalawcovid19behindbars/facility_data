library(tidyverse)
library(behindbarstools)

# Note: Should run this from the root of the data repo! (not facility_data repo)

# Update these   
SHEET <- "Sep21"
DATE <- "sep2021"

# Read data 
latest <- googlesheets4::read_sheet("10UTtnWUmLpiPT7FcVhEubGJ0vDvTsP5lNQ4i_x7S5Wk", 
                                    sheet = SHEET)

old <- stringr::str_c("https://raw.githubusercontent.com/uclalawcovid19behindbars/data/",
                      "master/anchored-data/state_aggregate_denominators.csv") %>% 
    read_csv()

# Join old and new data  
joined <- latest %>% 
    select(State, 
           Residents.Population = Population) %>% 
    left_join(old %>% 
                  select(State, 
                         Old.Population = Residents.Population, 
                         Staff.Population), 
              by = "State")

# Basic data validation - did any values change by more than 5%? 
joined %>% 
    mutate(diff_ = abs(Residents.Population - Old.Population) / Old.Population) %>% 
    filter(diff_ > 0.05)

# Write new data to csv 
out <- joined %>% 
    select(State, Residents.Population, Staff.Population) %>% 
    mutate(Date = DATE)

write.csv(out, "anchored-data/state_aggregate_denominators.csv", na = "", row.names = FALSE)
