library(tidyverse)
library(behindbarstools)

# Read existing facility info sheet 
old_fac_info <- read_fac_info()

# Read new public-private crosswalk 
pub_priv_path <- "data/21.5.26_priv-pub_cw.xlsx"
sheets <- readxl::excel_sheets(pub_priv_path)
xwalk <- lapply(sheets, function(x) readxl::read_excel(pub_priv_path, sheet = x, col_types = "text")) %>% 
    do.call(bind_rows, .) %>% 
    hablar::convert(
        hablar::dbl(Facility.ID), 
        hablar::lgl(Is.Different.Operator.New)) %>%
    select(Facility.ID, Is.Different.Operator.New, Different.Operator.New)

# Integrate updates 
updated_fac_info <- old_fac_info %>% 
    left_join(xwalk, by = "Facility.ID") %>% 
    mutate(Is.Different.Operator = coalesce(Is.Different.Operator.New, Is.Different.Operator), 
           Different.Operator = coalesce(Different.Operator.New, Different.Operator)) %>% 
    select(-ends_with(".New")) %>% 
    mutate(Different.Operator = ifelse(Different.Operator %in% c("Core Civic", "CoreCivic"), "CoreCivic", Different.Operator)) %>% 
    mutate(Different.Operator = na_if(Different.Operator, "NA"))

# Sanity checks 
verify_new_fac_info(updated_fac_info)
nrow(old_fac_info) == nrow(updated_fac_info)
ncol(old_fac_info) == ncol(updated_fac_info)

write.csv(updated_fac_info, "data/fac_data.csv", row.names = FALSE, na = "")