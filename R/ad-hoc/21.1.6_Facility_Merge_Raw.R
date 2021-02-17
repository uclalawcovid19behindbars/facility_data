## Project Name: Facility Info Merge
## Fellow: Michael Everett
## Date: December 14, 2020

library(readxl)
library(tidyverse)
library(fuzzyjoin)

## Make Facility Spellings List

extra_info <- read_xlsx("20.12.17_Facility_Names_Missing.xlsx") %>%
              subset(!is.na(New_Name)) %>%
              rename(c("Name_Raw" = "Out_Name",
                       "Name_Clean" = "New_Name")) %>%
              select(Name_Raw, Name_Clean)

info <- read_xlsx("20.12.18_Facility_Names.xlsx") %>%
        mutate(Name_Raw = str_trim(Name_Raw, side = c("both"))) %>%
        select(Name_Raw, Name_Clean)

info_match <- read_xlsx("20.12.18_Feb_Pop_CW.xlsx") %>%
              rename(c("Name_Clean" = "Merge_Name",
                       "Name_Raw" = "Raw_Name")) %>%
              subset(Name_Clean != "") %>%
              mutate(Name_Raw = str_trim(Name_Raw, side = c("both"))) %>%
              select(Name_Raw, Name_Clean)

comb_names <- info %>%
              rbind(extra_info) %>%
              rbind(info_match)

comb_names <- unique(comb_names[c("Name_Raw", "Name_Clean")])


info_sheet <- read_xlsx("20.12.18_Facility_Names.xlsx")

comp_spellings <- left_join(comb_names, info_sheet, by = "Name_Clean")

fac_sp_out <- comp_spellings %>%
              rename(c("facility_name_raw" = "Name_Raw.x",
                       "facility_name_clean" = "Name_Clean",
                       "Old_ID" = "ID")) %>%
              select(facility_name_raw,
                     facility_name_clean,
                     Old_ID,
                     State,
                     jurisdiction) 
fac_sp_out <- unique(fac_sp_out[c("facility_name_raw", "facility_name_clean", 
                                  "State", "jurisdiction")])


fac_in_link <- "https://raw.githubusercontent.com/uclalawcovid19behindbars/facility_data/master/data_sheets/fac_data.csv"
fac_in <- read.csv(fac_in_link)

fac_in_clean <- fac_in %>%
                left_join(., fac_sp_out, by = c("Name" = "facility_name_raw",
                                                "State" = "State")) %>%
                mutate(facility_name_clean = coalesce(facility_name_clean, Name)) 


                

fac_info_sheet <- info_sheet %>%
                  subset(Facility != "Duplicate") %>%
                  mutate(Facility = str_replace_all(Facility, "\\?", "NA")) %>%
                  mutate(Facility = str_replace_all(Facility, "PrIson", "Prison")) %>%
                  mutate(Facility = str_replace_all(Facility, "RESIDENTIAL REENTRY CENTER", "Transitional Center")) %>%
                  mutate(Facility = str_replace_all(Facility, "Cemter", "Center")) %>%
                  mutate(Facility = str_replace_all(Facility, "\\*", "")) %>%
                  mutate(Facility = str_replace_all(Facility, "Prison/Jail", "Hybrid"))
fac_info_sheet[ fac_info_sheet == "NA"] <- NA

febmr <- read_xlsx("20.12.18_Feb_Pop_CW.xlsx")

febmm <- unique(febmr[c("Merge_Name", "State")])

febm <- febmr %>%
  rename(c("Name_Clean" = "Merge_Name",
           "Name_Raw" = "Raw_Name")) %>%
  subset(Name_Clean != "") %>%
  mutate(Name_Raw = str_trim(Name_Raw, side = c("both"))) %>%
  mutate(Population = as.numeric(Population)) %>%
  group_by(Name_Clean) %>%
  summarise(Population = sum(Population)) %>%
  left_join(., febmm, by = c("Name_Clean" = "Merge_Name")) %>%
  rename(c("Pop_Feb2020" = "Population")) %>%
  select(Name_Clean, Pop_Feb2020, State) 

fac_out <- fac_in_clean %>%
           left_join(., fac_info_sheet, by = c("facility_name_clean" = "Name_Clean",
                                               "State" = "State")) %>%
           rename(c("Contract" = "Operated By")) %>%
           select(Count.ID, State, facility_name_clean, jurisdiction.x,
                  Facility, Security, Age, Gender, Contract, Capacity,
                  hifld_id, Address, City, Zipcode, Latitude, Longitude,
                  County, County.FIPS, TYPE, POPULATION, SECURELVL, CAPACITY,
                  Website) %>%
            mutate(Capacity_Combined = coalesce(Capacity, CAPACITY)) %>%
            rename(c("Name" = "facility_name_clean",
                     "jurisdiction" = "jurisdiction.x")) %>%
            left_join(., febm, by = c("Name" = "Name_Clean",
                                      "State" = "State")) %>%
            mutate(Population_Combined = coalesce(Pop_Feb2020, POPULATION))

test <- fac_out %>%
        subset(is.na(jurisdiction))

write.csv(fac_out, "20.12.19_fac_info.csv")

fac_sp_out_2 <- fac_sp_out %>%
              subset(facility_name_raw != "CCC-L") %>%
              subset(facility_name_raw != "CCC-O") %>%
              subset(facility_name_raw != "DEC") %>%
              subset(facility_name_raw != "NCCW") %>%
              subset(facility_name_raw != "NCYF") %>%
              subset(facility_name_raw != "NSP") %>%
              subset(facility_name_raw != "OCC") %>%
              subset(facility_name_raw != "TSCI") %>%
              subset(facility_name_raw != "WEC")

write.csv(fac_sp_out_2, "20.12.19_fac_sp.csv")


                  
             
        


    

fac_sp_link <- "https://raw.githubusercontent.com/uclalawcovid19behindbars/facility_data/master/data_sheets/fac_spellings.csv"
fac_sp <- read.csv(fac_sp_link) %>%
          mutate(facility_name_clean = str_trim(facility_name_clean, side = c("both"))) 
          mutate(facility_name_clean = str_replace_all(facility_name_clean, " ", ""))



## Diagnose issue with Multiple Clean Names/IDs

nam_num <- length(unique(fac_sp$facility_name_clean))
nam_num

id_num <- length(unique(fac_sp$Count.ID))
id_num

## Test Merge

info_merge <- left_join(fac_sp, info, by = c("facility_name_clean" = "Name_Raw",
                                             "State" = "State"))

info_merge <- stringdist_inner_join(fac_sp, info, 
                                    by = list(x = c("facility_name_clean", "Name_Raw"), 
                                              y = c("State", "State")), 
                                    distance_col = NULL)

other_names <- subset(info_merge, is.na(Name_Clean)) 
other_names <- unique(other_names[c("State", "facility_name_clean", "facility_name_raw")])

               .$facility_name_clean %>%
               unique() %>%
               as.data.frame() %>%
               rename(., c("Out_Name" = "."))

all_names <- info_merge$facility_name_clean %>%
             unique() %>%
             as.data.frame() %>%
             rename(., c("Out_Name" = "."))

## CDC -----------------

latest_link <- "https://raw.githubusercontent.com/uclalawcovid19behindbars/data/master/Adult%20Facility%20Counts/adult_facility_covid_counts_today_latest.csv"
data <- read.csv(latest_link) %>%
        select(State, Residents.Confirmed,  Staff.Confirmed, Residents.Deaths, Staff.Deaths,       
               Residents.Recovered, Staff.Recovered, Residents.Tadmin, Staff.Tested, Residents.Negative,  
               Staff.Negative, Residents.Pending, Staff.Pending, Residents.Quarantine, Staff.Quarantine,    
               Residents.Active) %>%
        group_by(State) %>%
        summarise_all(funs(sum(., na.rm = TRUE)))
write.csv(data, "20.12.21_Variables_By_State.csv")

facilities <- fac_info_sheet %>%
              select(State, Facility) %>%
              group_by(State, Facility) %>%
              summarise(Facility_County = n())
              
write.csv(facilities, "20.12.21_Facilities_By_State.csv")


## Create ReadMe

rm_data <- read.csv("https://raw.githubusercontent.com/uclalawcovid19behindbars/facility_data/master/data_sheets/20.12.19_fac_info.csv")

write.csv(rm_data, "21.1.3_fac-data_backup.csv")
## Formalize description  

# Create: diff_operator, bjs_id, source_pop, source_capacity

rm_clean <- rm_data %>%
            rename(., c("name" = "Name",
                        "state" = "State",
                        "jurisdiction" = "jurisdiction",
                        "description" = "Facility",
                        "security" = "Security",
                        "age" = "Age",
                        "gender" = "Gender",
                        "diff_operator_dummy" = "Contract",
                        "capacity" = "Capacity_Combined",
                        "population" = "Population_Combined",
                        "hifld_id" = "hifld_id",
                        "city" = "City",
                        "zipcode" = "Zipcode",
                        "latitude" = "Latitude",
                        "longitude" = "Longitude",
                        "county" = "County",
                        "county_fips" = "County.FIPS")) %>%
            mutate(source_population = ifelse(!is.na(hifld_id), "HIFLD",
                                              ifelse(!is.na(Pop_Feb2020), "Public Records", NA))) %>% # make dummy
            mutate(source_capacity = ifelse(!is.na(CAPACITY), "HIFLD",
                                            ifelse(!is.na(Capacity), "Public Records", NA))) %>%
            mutate(current = ifelse(is.na(jurisdiction), "Previous", "Current")) %>%
            mutate(diff_operator = ifelse(diff_operator_dummy == "Contract (Core)", "CoreCivic", 
                                          ifelse(diff_operator_dummy == "Contract (Marshall)", "US Marshall",
                                          ifelse(diff_operator_dummy == "Contract (Alternatives)", "Alternatives",
                                          ifelse(diff_operator_dummy == "Contract (CCA)", "CoreCivic",
                                          ifelse(diff_operator_dummy == "Contract (Geo)", "GeoGroup",
                                          ifelse(diff_operator_dummy == "Contract (MTC)", "Management & Training Corporation",
                                          ifelse(diff_operator_dummy == "Contract (VA)", "Volunteers of America", NA)))))))) %>%
            mutate(diff_operator_dummy = ifelse(diff_operator_dummy == "NA", NA,
                                         ifelse(diff_operator_dummy == "Public", NA,
                                         ifelse(is.na(diff_operator_dummy), "Unknown", "Different Operator")))) %>%
            mutate(age = str_replace_all(age, "Y", "J")) %>%
            mutate(description = ifelse(description == "NA", NA,
                                 ifelse(description == "Administrative - Staff", "Administrative",
                                 ifelse(description == "Age and Infirmed", "Aged and Infirmed",
                                 ifelse(description == "Detention", "Detention Center",
                                 ifelse(description == "Medical Center", "Medical Facility",
                                 ifelse(description == "Treatment Center", "Prison", description))))))) %>%
            mutate(security = str_replace_all(security, "Mid", "Med"))

bjs <- read_xlsx("ucla_bjs_crosswalk.xlsx") %>%
       row_to_names(row_number = 4) %>%
       mutate(Count.ID = as.numeric(Count.ID))

rm_final <- rm_clean %>%
            left_join(., bjs, by = "Count.ID") %>%
            rename(., c("bjs_id" = "BJS_ID")) %>%
            select(name, state, jurisdiction, description,
                   security, age, gender, diff_operator_dummy,
                   diff_operator, population, capacity,
                   hifld_id, bjs_id, current,
                   source_population,
                   source_capacity, latitude, longitude,
                   county_fips, zipcode, city, county) %>%
            subset(!is.na(state)) %>%
            mutate(state = str_replace_all(state, "Abroad", "Guam")) %>%
            mutate(description = str_replace_all(description, "Closed", "Prison")) %>%
            mutate(state = str_replace_all(state, "DC", "District of Columbia")) %>%
            mutate(state = str_replace_all(state, "Deleware", "Delaware"))

write.csv(rm_final, "fac_data.csv")

## Fix HIFLD merge for fac_data.csv

hifld_data <- read.csv("Prison_Boundaries.csv")

hifld_cw <- read_excel("hifld_dataset_for_ucla_linkage.xlsx") %>%
            row_to_names(row_number = 1) %>%
            mutate(HIFLD_ID = as.numeric(HIFLD_ID)) %>%
            left_join(., hifld_data, by = c("HIFLD_ID" = "FACILITYID"))
            

missing_before <- rm_final %>%
                  subset(is.na(hifld_id)) 

rm_merge <- rm_final %>%
            left_join(., hifld_cw, by = c("name" = "Name")) %>%
            mutate(hifld_id = coalesce(hifld_id, HIFLD_ID)) %>%
            mutate(source_population = ifelse(is.na(population) & !is.na(POPULATION), "HIFLD", source_population)) %>%
            mutate(source_capacity = ifelse(is.na(capacity) & !is.na(CAPACITY), "HIFLD", source_capacity)) %>%
            mutate(population = coalesce(population, POPULATION)) %>%
            mutate(capacity = coalesce(capacity, CAPACITY)) %>%
            mutate(COUNTYFIPS = as.numeric(COUNTYFIPS)) %>%
            mutate(county_fips = coalesce(county_fips, COUNTYFIPS)) %>%
            mutate(county = coalesce(county, COUNTY)) %>%
            mutate(zipcode = coalesce(zipcode, ZIP)) %>%
            mutate(city = coalesce(city, CITY)) %>%
            select(name, state, jurisdiction, description,
            security, age, gender, diff_operator_dummy,
            diff_operator, population, capacity,
            hifld_id, bjs_id, current,
            source_population,
            source_capacity, latitude, longitude,
            county_fips, zipcode, city, county) %>%
            mutate(state = str_replace_all(state, "Deleware", "Delaware")) %>%
            mutate(name = str_replace_all(name, "AZ", "ARIZONA"))

missing_after <- rm_merge %>%
                 subset(is.na(hifld_id))

write.csv(rm_merge, "facility_data.csv", row.names = FALSE)
            
            

## fac_spellings.csv

fs_base <- read.csv("https://raw.githubusercontent.com/uclalawcovid19behindbars/facility_data/master/data_sheets/20.12.19_fac_sp.csv")
fs_original <- read.csv("https://raw.githubusercontent.com/uclalawcovid19behindbars/facility_data/master/data_sheets/fac_spellings.csv")

write.csv(fs_base, "21.1.3_backup_facility_spellings.csv") # backup new fac sp
write.csv(fs_original, "20.1.3_backup_facsp_original.csv") # backup origina; fac sp

fs_b <- fs_base %>%
        rename(., c("name_raw" = "facility_name_raw",
                    "name_clean" = "facility_name_clean",
                    "state" = "State",
                    "jurisdiction" = "jurisdiction")) %>%
        select(name_raw, name_clean, state, jurisdiction)

fs_j <- fs_original %>%
        rename(., c("name_raw" = "facility_name_raw",
                    "name_clean" = "facility_name_clean",
                    "state" = "State")) %>%
        select(name_raw, name_clean, state) %>%
        mutate(jurisdiction = "Not Determined")

fs_j <- fs_j[!fs_j$name_raw %in% fs_b$name_raw,] # first missing

fs_new <- fs_b %>%
          left_join(., fs_j, by = c("name_raw" = "name_clean")) %>%
          subset(!is.na(name_raw.y)) %>%
          select(name_clean, state.x, jurisdiction.x, name_raw.y) %>%
          rename(., c("state" = "state.x",
                      "jurisdiction" = "jurisdiction.x",
                      "name_raw" = "name_raw.y"))

fs_merge1 <- fs_b %>%
             rbind(., fs_new)

fs_j2 <- fs_j[!fs_j$name_raw %in% fs_merge1$name_raw,]
          
fs_final <- fs_merge1 %>%
            rbind(., fs_j2)

write.csv(fs_final, "facility_spellings.csv", row.names = FALSE)  

## Final Fix

data_new <- read.csv("facility_data.csv")
spellings_new <- read.csv("facility_spellings.csv")

data_marked <- data_new %>%        
               group_by(name, state) %>%
               mutate(dup = ifelse(n() > 1, "Duplicate", "Not Duplicate"))
test <- data_marked %>%
        subset(., dup == "Duplicate")

hifld <- read.csv("Prison_Boundaries.csv")

no_dup <- data_marked %>%
          subset(dup != "Duplicate")

dup_fix <- read_xlsx("21.1.5_dup_fixed.xlsx") %>%
           lapply(., type.convert)

og_comb <- no_dup %>%
           rbind(dup_fix)

corr_dummy <- read.csv("21.1.3_fac-data_backup.csv") %>%
              group_by(Name, State) %>%
              mutate(dup = ifelse(n() > 1, "Duplicate", "Not Duplicate")) %>%
              ungroup() %>%
              mutate(sp_2 = ifelse(is.na(Pop_Feb2020) & !is.na(POPULATION), "HIFLD",
                                   ifelse(!is.na(Pop_Feb2020), "Public Records", NA))) %>%
              mutate(sc_2 = ifelse(is.na(Capacity) & !is.na(CAPACITY), "HIFLD",
                                   ifelse(!is.na(Capacity), "Public Records", NA))) %>%
              select(Name, jurisdiction, State, Capacity_Combined, Population_Combined,
                     dup, sp_2, sc_2) %>%
              rename(c("name_merge" = "Name",
                       "jurisdiction_merge" = "jurisdiction",
                       "state_merge" = "State",
                       "capacity_merge" = "Capacity_Combined",
                       "population_merge" = "Population_Combined",
                       "sp_merge" = "sp_2",
                       "sc_merge" = "sc_2")) 

              
              

corr_dup <- corr_dummy %>%
            subset(., dup == "Duplicate")
              
corr_base <- corr_dummy %>%
             subset(dup != "Duplicate")
                                   
corr_dup_fix <- read_xlsx("21.1.5_dummy_fix_in.xlsx") %>%
                mutate(state_merge = str_replace_all(state_merge, "DC", "District of Columbia")) %>%
                mutate(state_merge = str_replace_all(state_merge, "Deleware", "Delaware"))

dummy_final <- corr_base %>%
               rbind(corr_dup_fix)

fix_final <- og_comb %>%
             merge(., dummy_final, by.x = c("name", "state"),
                                   by.y = c("name_merge", "state_merge")) 

fix_test <- fix_final[!duplicated(fix_final),] 

fix_comp <- fix_test %>%
            mutate(delete = ifelse(name == "DALLAS COUNTY JAIL" & capacity = -999, "delete",
                            ifelse(name == "DALLAS COUNTY JAIL" & capacity = 34, "delete",
                            ifelse(name == "EAST TEXAS UNIT" & is.na(hifld_id), "delete",
                            ifelse(name == "TURNER RESIDENTIAL SUBSTANCE ABUSE TREATMENT" & is.na(population_merge), "delete", "keep")))))

bjs <- read_xlsx("ucla_bjs_crosswalk.xlsx") %>%
       row_to_names(row_number = 4)

fix_out <- fix_test %>%
           subset(-c(source_population, source_capacity, current, bjs_id, dup.y, capacity, population)) %>%
           rename(c("source_population" = "sp_merge",
                    "source_capacity" = "sp_capacity",
                    "control" = "dup.x",
                    "capacity" = "capacity_merge",
                    "population" = "population_merge")) %>%
            mutate(control = str_replace_all(control, "Duplicate", "x")) %>%
            mutate(control = str_replace_all(control, "Not Duplicate", "")) %>%
            
            
            
         

test <- fix_comp %>%
        group_by(name, state) %>%
        filter(n() > 1)

# fix spellings

hold <- spellings_new


          

sp_fix <- spellings_new[!duplicated(spellings_new),]      

sp_clean <- sp_fix %>%
            mutate(state = ifelse(state == "Deleware", "Delaware",
                                  ifelse(state == "Abroad", "Guam",
                                         ifelse(state == "DC", "District of Columbia",
                                                ifelse(state == "Federal", NA,
                                                       ifelse(state == "Not Available", NA, state))))))

write.csv(sp_clean, "21.1.5_fac_spellings_fix.csv")

bjs_merge <- bjs %>%
             left_join(., sp_clean, by = c("Name" = "name_raw",
                                           "State" = "state")) %>%
             rename(c("name" = "name_clean")) %>%
             select(name, State, BJS_ID)

fix_out <- fix_test %>%
  select(-c(source_population, source_capacity, current, bjs_id, dup.y, capacity, population)) %>%
  rename(c("source_population" = "sp_merge",
           "source_capacity" = "sc_merge",
           "control" = "dup.x",
           "capacity" = "capacity_merge",
           "population" = "population_merge")) %>%
  mutate(control = str_replace_all(control, "Duplicate", "x")) %>%
  mutate(control = str_replace_all(control, "Not Duplicate", "")) %>%
  left_join(., bjs_merge, by = c("name" = "Name",
                                 "state" = "State")) %>%
  rename(c("bjs_id" = "BJS_ID",
           "jurisdiction" = "jurisdiction.x")) %>%
  mutate(current = ifelse(is.na(jurisdiction), "Previous", "Current")) %>%
  select(name, state, jurisdiction, description,
         security, age, gender, diff_operator_dummy,
         diff_operator, population, capacity,
         hifld_id, bjs_id, current,
         source_population,
         source_capacity, latitude, longitude,
         county_fips, zipcode, city, county) %>%
  mutate(remove = ifelse(is.na(county) & name == "EAST TEXAS UNIT", "delete",
                         ifelse(population == "NA" & name == "TURNER RESIDENTIAL SUBSTANCE ABUSE TREATMENT", "delete", "keep"))) %>%
  subset(remove == "keep") %>%
  select(-c(remove))

fix_out <- fix_out[!duplicated(fix_out),]  

write.csv(fix_out, "21.1.5_fac_data_fix.csv")

control <- fix_out %>%
           group_by(name, state) %>%
           filter(n() > 1)

## FIX FACILITY DATA ------------------------


## Error checking

sp_clean # new facility spellings
fix_out # new facility data

# Check for naming conventions
fix_out %>%
  select(state, jurisdiction, description, security, age,
         gender, diff_operator, diff_operator_dummy, current,
         source_population, source_capacity) %>%
  lapply(., unique)

# Fix categories
fix_cat <- fix_out %>%
           mutate(age = ifelse(age == "A", "Adult",
                               ifelse(age == "B", "Mixed",
                                      ifelse(age == "J", "Juvenile", age)))) %>%
           mutate(gender = ifelse(gender == "M", "Male",
                                  ifelse(gender == "F", "Female",
                                         ifelse(gender == "W", "Female",
                                                ifelse(gender == "B", "Mixed", gender))))) %>%
           mutate(source_population = ifelse(source_population == "NA", NA, source_population)) %>%
           mutate(source_capacity = ifelse(source_capacity == "NA", NA, source_capacity))

# Check Female Facilities
fem <- fix_cat %>%
       subset(gender == "Female")
View(fem)

# fix wrong Ms
fix_m <- fix_cat %>%
         mutate(gender = ifelse(grepl("WOMEN", name), "Female", gender))

#Check Youth Facilities
youth <- fix_m %>%
         subset(age == "Juvenile")

# Check for duplicates
fix_m %>%
  group_by(state, name) %>%
  filter(n()> 1)
#no duplicates

# Make final
fix_final_out <- fix_m

# FIX SPELLINGS -----------------------------------

## Error check facility spellings

sp_clean %>% 
  select(state, jurisdiction) %>%
  lapply(., unique)

sp_out <- sp_clean %>%
          mutate(jurisdiction = ifelse(jurisdiction == "Not Determined", NA, jurisdiction))

# Check for duplicates
test <-  sp_out %>%
         group_by(name_clean, state) %>%
         filter(n() > 1)
# Meaningless
sp_final <- sp_out[!duplicated(sp_out),]


## FINAL DF ---------------------------------------





#### New Facility Data
fix_final_out
write_csv(fix_final_out, "fac_data.csv")

### New Facility Spellings
sp_final
write_csv(sp_final, "fac_spellings.csv")



### PUSH TO GITHUB --------------------------------








