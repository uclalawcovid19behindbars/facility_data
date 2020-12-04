library(tidyverse)

# Create new Count.ID 
# df should be fac_data or fac_spellings 
generate_new_id <- function(df) {
  max_id <- max(df$Count.ID)
  new_id <- max_id + 1
  return(new_id)
}

