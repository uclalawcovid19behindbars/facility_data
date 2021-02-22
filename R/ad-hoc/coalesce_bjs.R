library(haven)

# Read data 
FAC_DATA <- read_fac_info()
bjs <- haven::read_dta("data/37294-0001-Data.dta") 

# Clean BJS data 
bjs_clean <- bjs %>% 
    mutate(V02 = as.double(V02)) %>% 
    distinct(V02, .keep_all = TRUE) %>% 
    mutate(city_bjs = stringr::str_to_upper(V07),
           sex_bjs = case_when(V11 == 1 ~ "Male", 
                               V11 == 2 ~ "Female",
                               V11 == 3 ~ "Mixed"), 
           security_bjs = case_when(V12 %in% c(1, 2) ~ "Max", 
                                    V12 %in% c(3) ~ "Med", 
                                    V12 %in% c(4) ~ "Min"))

# Join datasets 
joined <- FAC_DATA %>% 
    left_join(bjs_clean %>% mutate(V02 = as.double(V02)), 
              by = c("BJS.ID" = "V02")) %>% 
    mutate(City = coalesce(City, city_bjs), 
           Gender = coalesce(Gender, sex_bjs), 
           Security = coalesce(Security, security_bjs)) %>% 
    select(Facility.ID, State, Name, Jurisdiction, Description, Security,
           Age, Gender, Is.Different.Operator, Different.Operator, Population.Feb20,
           Capacity, HIFLD.ID, BJS.ID, Source.Population.Feb20, Source.Capacity, Address,
           City, Zipcode, Latitude, Longitude, County, County.FIPS, Website, ICE.Field.Office)

# Double-check 
nrow(FAC_DATA) == nrow(joined)

# Write out 
write.csv(joined, "data/fac_data.csv", row.names = FALSE, na = "")
