library(tidyverse)

# Load data 
fac_data <- read_csv("./data_sheets/fac_data.csv", col_types = cols())
fac_alt <- read_csv("./data_sheets/fac_spellings.csv", col_types = cols())

# Generate new Count.ID 
generate_new_id <- function() {
  max_id <- max(fac_data$Count.ID, fac_alt$Count.ID, na.rm = TRUE)
  new_id <- max_id + 1
  return(new_id)
}



