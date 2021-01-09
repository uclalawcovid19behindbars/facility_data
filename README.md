[![logo](logo.svg)](https://uclacovidbehindbars.org/)

# Facility Data & Crosswalks 

## Background 
The [UCLA Law Covid-19 Behind Bars Data Project](https://uclacovidbehindbars.org/) collects and reports facility-level data on COVID-19 in prisons, jails, and other carceral facilities. Our core dataset can be found on GitHub [here](https://github.com/uclalawcovid19behindbars/data). This repository contains the facility datasets and crosswalks used to integrate data from various sources. 

There are very few national datasets on correctional facilities in the U.S. The lack of quality and contemporary descriptive data for correctional facilities poses a major problem for research on corrections, particularly research tracking the spread of Covid in these facilities. 

The UCLA team developed these datasets to uniformly describe the entities reported by various government agencies by combining information from various sources. This includes information from national datasets, like the [Homeland Infrastructure Foundation-Level Data (HIFLD) Prison Boundaries dataset](https://hifld-geoplatform.opendata.arcgis.com/datasets/prison-boundaries/data) produced by the Department of Homeland Security and [datasets produced by the Bureau of Justice Statistics](https://www.bjs.gov/index.cfm?ty=dca). We have also filled in gaps in these sources by independently gathering data through public records requests and manual investigation. 

**Note**: These files continue to evolve as reporting agencies post new entities and new spellings of those entities. As such, the UCLA team continuously updates these datasets. 


## Directory Structure 
This repository contains two datasets managed by the UCLA Law Covid-19 Behind Bars Data Project: 

#### Facility Information Dataset

* Data File: `fac_data.csv`
* Description: This dataset contains detailed descriptive information on each entity in our dataset (e.g. type of entity, capacity, population, geographic information, etc.). Each row represents a unique entity. 

#### Facility Spellings Crosswalk 

* Data File: `fac_data.csv`
* Description: This crosswalk maps alternative spellings of a given entity to the cleaned name in the Facility Information Dataset. Each row represents a unique spelling of a given entity, as reported by an agency that we collect data from. 


## Data Dictionary

Note that we use facility and entity interchangably here. While the majority of the rows in these datasets are facilities (e.g. jails or prisons), several rows are geographic entities because an agency reports data at that level. 

#### Facility Information Dataset

| Variable | Description |  |
|-|-|-|
| `Facility.ID` | Integer ID that uniquely identifies every facility  |  |
| `Name` | Cleaned name for the facility  |  |
| `State` | State where the facility is located |  |
| `Jurisdiction` | Jurisdiction of the reporting agency. Potential values: `state`, `county`, `federal`.  |  |
| `Description` | Entity type, more detailed descriptions below. Potential values: `Geographic`, `Administrative`, `Prison`, `Jail`, `Hybrid`, `Reception Center`, `Transitional Center`, `Medical Facility`, `Detention Center`, `Prison Unit`, `Work Camp`, `Aged and Infirmed`.  |  |
| `Security` | Security level of the facility, designated by UCLA staff based on available information. Potential values: `Max`, `Med`, `Min`, `Max/Med`, `Max/Min`, `Med/Min`.  |  |
| `Age` | Age group kept in the entity if known, designated by UCLA staff based on available information. Potential values: `Adult`, `Juvenile`, `Mixed`.   |  |
| `Gender` | Gender group kept in the entity if known, designated by UCLA staff based on available information. Potential values: `Female`, `Male`, `Mixed`.  |  |
| `Is.Different.Operator` | Binary indicator for whether the entity is run by an organization different from the reporting jurisdiction (e.g. a private company or a county government).  |  |
| `Different.Operator` | Name of the organization operating the entity if run by an organization different from the reporting jurisdiction. |  |
| `Population` | Population of the facility as close to February 1, 2020 as possible. This variable is a combination of [HIFLD values](https://hifld-geoplatform.opendata.arcgis.com/datasets/prison-boundaries/data) and data gathered by UCLA staff through public records requests. Population values gathered by UCLA staff were prioritized over data from HIFLD if both were available. Staff-gathered population values were prioritized because they are closer to February 2020 than the HIFLD values, which are from the last several years. |  |
| `Capacity` | Capacity of the facility if known. This variable is a combination of [HIFLD values](https://hifld-geoplatform.opendata.arcgis.com/datasets/prison-boundaries/data) and data gathered by UCLA staff. Capacity values gathered by UCLA staff were prioritized over data from HIFLD if both were available.  |  |
| `HIFLD.ID` | Facility's corresponding [Homeland Infrastructure Foundation-Level Data](https://hifld-geoplatform.opendata.arcgis.com/datasets/prison-boundaries/data) ID |  |
| `BJS.ID` | Facility's corresponding [Bureau of Justice Statistics](https://www.bjs.gov/index.cfm?ty=dca) ID |  |
| `Source.Population` | Population source. Potential values: `HIFLD`, `Public Records`.  |  |
| `Source.Capacity` | Capacity source. Potential values: `HIFLD`, `Public Records`.  |  |

Additional geographic fields: `Zipcode`, `City`, `County`, `Latitude`, `Longitude`, `County.FIPS`.

Descriptions of the entity types in the `Description` field are as follows: 

* `Geographic`: Cover a geographic region and are not a particular facility (e.g. statewide values, parole regions) 
* `Administrative`: Staff specific and do not hold correctional residents (e.g. agency headquarters, training academies)
* `Prison`: Generally hold individuals who have been convicted of a crime and sentenced. These are exclusively run by state or federal agencies
* `Jail`: Generally hold individuals who have not been convicted of a crime and are detained or awaiting trial. These facilities also house individuals who have been convicted of a crime but are serving a short sentence. These are generally run by county governments.
* `Hybrid`: Generally hold both individuals convicted of a crime and individuals who have not been convicted of a crime. These are facilities housed in jurisdictions that combine their prison and jail systems, like Hawaii and DC. 
* `Reception Center`: Prisons which also serve as intake centers for newly convicted individuals. At these facilities, individuals are designated a security level and assigned to a long-term facility. These facilities can also hold their own long-term populations.
* `Transitional Center`: Prisons which also serve as re-entry centers for convicted individuals who will be released. These facilities often have transitional programs where individuals are technically trained or work in local communities through occupational programs.
* `Medical Facility`: Prisons which have significant inpatient and outpatient care services for convicted individuals and typically are correctional hospitals.
* `Detention Center`: Generally hold individuals who have not been convicted of a crime and are detained or awaiting trial or deportation hearings. These are generally run by state or federal agencies.
* `Prison Unit`: Units within prisons 
* `Work Camp`: Prisons that house individuals who generally work on significant labor projects like farming, land management, and firefighting 
* `Aged and Infirmed`: Prisons that generally house older individuals and individuals with significant chronic diseases 

#### Facility Spellings Crosswalk 

| Variable              | Description                                                                         |
|-----------------------|-------------------------------------------------------------------------------------|
| `Facility.ID`         | Integer ID that uniquely identifies every facility                                  |
| `facility_name_raw`   | Alternative spelling for the facility                                               |
| `facility_name_clean` | Cleaned name for the facility                                                       |
| `State`               | State where the facility is located                                                 |
| `Is.Federal`          | Binary indicator for whether the entity falls under federal jurisdiction            |


## Citations

Citations for academic publications and research reports:

> Sharon Dolovich, Aaron Littman, Kalind Parish, Grace DiLaura, Chase Hommeyer,  Michael Everett, Hope Johnson, Neal Marquez, and Erika Tyagi. UCLA Law Covid-19 Behind Bars Data Project: Jail/Prison Confirmed Cases Dataset [date you downloaded the data]. UCLA Law, 2020, https://uclacovidbehindbars.org/.

Citations for media outlets, policy briefs, and online resources:

> UCLA Law Covid-19 Behind Bars Data Project, https://uclacovidbehindbars.org/.


## License 
Our data is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/). That means that you must give appropriate credit, provide a link to the license, and indicate if changes were made. You may not use our work for commercial purposes, which means anything primarily intended for or directed toward commercial advantage or monetary compensation. 
