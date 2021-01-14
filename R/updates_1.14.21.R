library(tidyverse)
library(behindbarstools)

fac_data <- read.csv("data/fac_data.csv")
fac_spellings <- read.csv("data/fac_spellings.csv")

# Add jurisdiction to spellings 
federal <- fac_spellings %>% 
    filter(Is.Federal == 1) %>% 
    mutate(name_clean_ = clean_fac_col_txt(xwalk_name_clean, to_upper = TRUE)) %>% 
    select(-State, -Facility.ID) %>% 
    left_join(fac_data %>% 
                  filter(Jurisdiction %in% c("federal", "immigration")) %>% 
                  mutate(name_clean_ = clean_fac_col_txt(Name, to_upper = TRUE)),  
              by = "name_clean_") %>% 
    select(Facility.ID, xwalk_name_raw, xwalk_name_clean, State, Jurisdiction, Source)
    
non_federal <- fac_spellings %>% 
    filter(Is.Federal == 0) %>% 
    mutate(name_clean_ = clean_fac_col_txt(xwalk_name_clean, to_upper = TRUE)) %>% 
    select(-Facility.ID) %>% 
    left_join(fac_data %>% 
                  filter(Jurisdiction %in% c("state", "county")) %>% 
                  mutate(name_clean_ = clean_fac_col_txt(Name, to_upper = TRUE)),
              by = c("name_clean_", "State")) %>% 
    select(Facility.ID, xwalk_name_raw, xwalk_name_clean, State, Jurisdiction, Source)

alt_spellings <- bind_rows(federal, non_federal)
    
# Add all fac_data rows to fac_spellings
clean_spellings <- fac_data %>% 
    mutate(xwalk_name_raw = Name, 
           xwalk_name_clean = Name) %>% 
    select(Facility.ID, xwalk_name_raw, xwalk_name_clean, State, Jurisdiction)
    
full_spellings <- bind_rows(alt_spellings, clean_spellings) %>% 
    unique() %>% 
    arrange(State, xwalk_name_clean, xwalk_name_raw)

write.csv(full_spellings, "data/fac_spellings.csv", row.names = FALSE)

