rm(list=ls())
source("R/utilities.R")

# ------------------------------------------------------------------------------
# Load data into environment once 
# ------------------------------------------------------------------------------

OLD_FAC_INFO <- behindbarstools::read_fac_info()
OLD_FAC_SPELLINGS <- behindbarstools::read_fac_spellings()
HIFLD_DATA <- behindbarstools::read_hifld_data()

# ------------------------------------------------------------------------------
# Update facility info sheet 
# ------------------------------------------------------------------------------

updated_fac_info <- 
    # Read from Google sheet 
    read_new_fac_info() %>%
    # Run QC checks 
    verify_new_fac_info(
        new_fac_info = ., 
        old_fac_info = OLD_FAC_INFO, 
        old_fac_spellings = OLD_FAC_SPELLINGS
    ) %>% 
    # Update missing data from HIFLD, geocode addresses, assign ID   
    populate_new_fac_info(
        new_fac_info = ., 
        old_fac_info = OLD_FAC_INFO, 
        old_fac_spellings = OLD_FAC_SPELLINGS,         
        hifld_data = HIFLD_DATA
    ) %>% 
    # Combine with existing info sheet 
    update_fac_info(
        new_fac_info = ., 
        old_fac_info = OLD_FAC_INFO)

# Replace csv 
write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# Update facility spellings sheet 
# ------------------------------------------------------------------------------

updated_fac_spellings <- 
    # Read from Google sheet 
    read_new_fac_spellings() %>% 
    # Run QC checks 
    verify_new_fac_spellings(
        new_fac_spellings = ., 
        old_fac_info = updated_fac_info, 
        old_fac_spellings = OLD_FAC_SPELLINGS
    ) %>% 
    # Assign ID from fac_info sheet
    populate_new_spellings(
        new_fac_spellings = .,
        old_fac_info = updated_fac_info
    ) %>%
    # Combine with existing spellings sheet
    update_fac_spellings(
        new_fac_spellings = .,
        old_fac_spellings = OLD_FAC_SPELLINGS
    )

# Replace csv 
write.csv(updated_fac_spellings, "data/fac_spellings.csv", row.names = FALSE)
