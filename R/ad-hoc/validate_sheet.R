library(tidyverse)

fac_data <- read_csv("./data_sheets/fac_data.csv", col_types = cols())
fac_alt <- read_csv("./data_sheets/fac_spellings.csv", col_types = cols())

# all data keys unique?
length(fac_data$Count.ID) == length(unique(fac_data$Count.ID))

# all keys in spelling in data
all(unique(fac_alt$Count.ID) %in% unique(fac_data$Count.ID))

# which ones arent?
spell_ids <- unique(fac_alt$Count.ID)
data_ids <- unique(fac_data$Count.ID)

missing_ids <- spell_ids[!(spell_ids %in% data_ids)]

fac_alt %>%
    filter(Count.ID %in% missing_ids) %>%
    select(Count.ID, State, facility_name_clean) %>%
    unique() %>%
    arrange(Count.ID) %>%
    print(n=100)
