rm(list = ls())
source("R/utilities.R")

# ------------------------------------------------------------------------------
# Load data into environment once 
# ------------------------------------------------------------------------------

OLD_FAC_INFO <- read_fac_info()
OLD_FAC_SPELLINGS <- read_fac_spellings()
HIFLD_DATA <- read_hifld_data() 

# Specify Google Sheet URL here! 
url <- "1oTTKeyiPPXJnjNI5ZzxQFlsb6G49xk-VUSacZPwNCGI"

# ------------------------------------------------------------------------------
# Update facility info sheet 
# ------------------------------------------------------------------------------

updated_fac_info <- 
    # Read from Google sheet 
    read_new_fac_info(google_sheet_url = url) %>% 
    # Update missing data from HIFLD, geocode addresses, assign ID   
    populate_new_fac_info(
        new_fac_info = ., 
        old_fac_info = OLD_FAC_INFO, 
        old_fac_spellings = OLD_FAC_SPELLINGS,         
        hifld_data = HIFLD_DATA) %>% 
    # Run QC checks 
    verify_new_fac_info() %>% 
    # Combine with existing info sheet 
    update_fac_info(
        new_fac_info = ., 
        old_fac_info = OLD_FAC_INFO)

# Replace csv 
write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")

# ------------------------------------------------------------------------------
# Update facility spellings sheet 
# ------------------------------------------------------------------------------

# If you updated fac_info above, use the latest version of fac_info updated above 
# If you are only adding spellings, use OLD_FAC_INFO 
if (!exists("updated_fac_info")) {
    updated_fac_info <- OLD_FAC_INFO
}

updated_fac_spellings <- 
    # Read from Google sheet 
    read_new_fac_spellings(google_sheet_url = url) %>% 
    # Assign ID from fac_info sheet
    populate_new_spellings(
        new_fac_spellings = .,
        old_fac_info = updated_fac_info) %>% 
    # Run QC checks 
    verify_new_fac_spellings(
        new_fac_spellings = ., 
        old_fac_info = updated_fac_info) %>% 
    # Combine with existing spellings sheet
    update_fac_spellings(
        new_fac_spellings = ., 
        old_fac_spellings = OLD_FAC_SPELLINGS, 
        old_fac_info = updated_fac_info)

# Replace csv 
write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE, na = "")
