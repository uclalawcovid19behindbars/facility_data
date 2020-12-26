![](logo.svg)(https://uclacovidbehindbars.org/)

## Facility Crosswalks 

### Background 
The [UCLA Law Covid-19 Behind Bars Data Project](https://uclacovidbehindbars.org/) collects and reports facility-level data on COVID-19 in prisons, jails, and other carceral facilities. This repository contains the facility crosswalks used to integrate data from various sources, along with the R code used to maintain and update these crosswalks. 

### Directory Structure 

There are two facility crosswalks in the `data` folder: 
*  `fac_data.csv`: each row is a unique facility, contains detailed information about each facility 
* `fac_spellings.csv`:  each row is a unique spelling of a facility, contains minimal information about each facility and is used to map alternative spellings of a given facility to its cleaned name   

There are two R scripts in the `R` folder: 
* `main.R` updates the crosswalks with new facilities 
* `utilities.R` contains helper functions 

### Data Dictionary 

In the facility info sheet (`fac_data.csv`): 
* `Facility.ID`: A unique integer ID that identifies every facility 
* `Name`: The official cleaned name for the facility  
* `Jurisdiction`: Whether the facility falls under `state`, `county`, or `federal` jurisdiction 
* `Designation`: 
* `HIFLD.ID`: The facility's corresponding [HIFLD ID](https://hifld-geoplatform.opendata.arcgis.com/datasets/prison-boundaries/data)  
* `Address`, `City`, `Zipcode`, `County`, `County.FIPS`, `State`, `Latitude`, `Longitude`: Geographic information about the facility 
* `Population.Feb20`: The facility's population as of Feb 2020, used to calculate COVID-19 rates 
* `Website`: The facility's website or reporting source 

In the facility spellings sheet (`fac_spellings.csv`): 
* `State`
* `xwalk_name_raw`
* `xwalk_name_clean`
* `Source` 

### Update Instructions 

To update the facility crosswalks with a new facility or new alternative spelling: 
1. Add the new entries to the Google Sheet [here](https://docs.google.com/spreadsheets/d/1tAhD-brnuqw0s55QXM-xYLPsyD-rNrqHbAVIbxSOMwI/edit#gid=363817589), following the instructions in the first tab 
2. Run `R/main.R`, which does the following: 
* Reads from the Google Sheet
* Performs validation checks on the new entries 
* Populates missing data if possible (e.g. from the HIFLD database) 
* Assigns a `Facility.ID` to new facilities 
* Combines the new entries with the existing crosswalks
* Updates the facility crosswalk `csv` files in the `data` folder 

Note that `main.R` assumes that you have the following: 
* Access to the Google Sheet, which will automatically generate a valid OAuth token for `googlesheets4`
* A `geocodio` API key, available from [here](https://www.geocod.io/features/api/) 
* An updated version of the [`behindbarstools` R package](https://github.com/uclalawcovid19behindbars/behindbarstools) 
