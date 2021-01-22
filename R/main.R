rm(list = ls())
source("R/utilities.R")

# ------------------------------------------------------------------------------
# Load data into environment once 
# ------------------------------------------------------------------------------

OLD_FAC_INFO <- read_fac_info()
OLD_FAC_SPELLINGS <- read_fac_spellings()
HIFLD_DATA <- read_hifld_data()

# Specify Google Sheet URL here to avoid using the default! 
url <- "1ThlA_7Ht7-j3b9nY43zNOLZo6BdwxvwEvbPSx8DPrys"

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
    verify_new_fac_info(
        new_fac_info = ., 
        old_fac_info = OLD_FAC_INFO, 
        old_fac_spellings = OLD_FAC_SPELLINGS)

# Replace csv 
write.table(updated_fac_info, "data/fac_data.csv", 
            append = TRUE, sep = ",", col.names = FALSE, row.names = FALSE)

# ------------------------------------------------------------------------------
# Update facility spellings sheet 
# ------------------------------------------------------------------------------

# Note: updated_fac_info (created above) is paseed into old_fac_info below 

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
        old_fac_info = updated_fac_info, 
        old_fac_spellings = OLD_FAC_SPELLINGS) 

# Replace csv 
write.table(updated_fac_spellings, "data/fac_spellings.csv", 
            append = TRUE, sep = ",", col.names = FALSE, row.names = FALSE)
