# UCLA Law Covid-19 Behind Bars Data Project
### An Initiative of the UCLA Prison Law and Policy Program
### Project Director: Sharon Dolovich, Professor of Law
### Deputy Director: Aaron Littman, Binder Clinical Teaching Fellow

_Follow us on Twitter @uclaprisondata_

Data to add? Please email covidbehindbars@law.ucla.edu_		

_Questions about a dataset? Read the Data Dictionary accompanying each dataset which answers FAQs._

## Facility Data Repository

### Background

This repository contains two datasets managed by the UCLA Law Covid-19 Behind Bars Data Project. For a full description of the project and its goals, please visit the ReadMe for the historical-data branch. These datasets contain information on the various entities for which governments report Covid data. If you are using one of these datasets, please read through this ReadMe and its associated data dictionaries. 

### Description of Datasets

* Alternative & Corrected Spellings for Entities in Dataset
	* Data File Name: `fac_spellings.csv`
	* Data Dictionary: See below.
	* Description. This dataset contains the various names agencies use to refer to the entities they report Covid data for alongside a uniform name for that entity. The UCLA team uses this dataset to make the names in our dataset uniform and consistent. 

* Description of Entities in Dataset
	* Data File Name: `fac_data.csv`
	* Data Dictionary: See below.
	* Description: This dataset contains descriptive information on entities in our dataset like whether they are facilities and, if so, the types of individuals housed in them. 


### Facility Data Overview

There are very few national datasets on correctional facilities in the U.S. The lack of quality and contemporary descriptive data for correctional facilities poses a major problem for research on corrections, particularly research tracking the spread of Covid in these facilities. 

The UCLA team developed these datasets to uniformly describe the entities reported by various government agencies. The facility spellings dataset is used to formalize the names of entities in our dataset. The facility data dataset contains descriptive information on the entities included in our dataset including capacity, population, and demographic data. It combines multiple national datasets, like the Homeland Infrastructure Foundation-Level Data (HIFLD) Prison Boundaries dataset produced by the Department of Homeland Security and datasets produced by the Bureau of Justice Statistics. Where these datasets have failed to provide information, the UCLA team has independently gathered it using public records requests and investigation. 

Both of these datasets are evolving as reporting agencies post new entities and new spellings of those entities. As such, the UCLA team continually updates these datasets.

### Data Dictionary

Data File: fac_spellings.csv

* `name_raw`: Names posted by reporting agencies to refer to various entities.
* `name_clean`: The corrected name for the entity.
* `state`: State where the entity is located.
* `jurisdiction`: Jurisdiction of the reporting agency. 
	* Potential values: Federal, State, County


Data File: fac_data.csv

* `name`: Entity name. 
* `state`: State where the entity is located.
* `jurisdiction`: Jurisdiction of the reporting agency.
	* Potential values: `Federal`, `State`, `County`
* `description`: Entity type. Entities for which no designation could be made were left as NA. 
	* Potential values:
      * `Geographic`: Entities which cover a geographic region and are not a particular facility. Examples include statewide values or parole regions. 
      * `Administrative`: Entities which are staff specific and do not hold correctional residents. Examples include agency headquarters and training academies.
      * `Prison`: Entities which generally hold individuals who have been convicted of a crime and sentenced. These are exclusively run by state or federal agencies.
      * `Jail`: Entities which generally hold individuals who have not been convicted of a crime and are detained or awaiting trial. These facilities also house individuals who have been convicted of a crime but are serving a short sentence. These are generally run by county governments. 
      * `Hybrid`: Entities which generally hold both individuals convicted of a crime and individuals who have not been convicted of a crime. These are facilities housed in jurisdictions that combine their prison and jail systems, like Hawaii and the District of Columbia. 
      * `Reception Center`: These are prisons which also serve as intake centers for newly convicted individuals. At these facilities, individuals are designated a security level and assigned to a long-term facility. These facilities can also hold their own long-term populations.
      * `Transitional Center`: These are prisons which also serve as re-entry centers for convicted individuals who will be released. These facilities often have transitional programs where individuals are technically trained or work in local communities through occupational programs.
      * `Medical Facility`: These are prisons which have significant inpatient and outpatient care services for convicted individuals and typically are correctional hospitals.
      * `Detention Center`: Entities which generally hold individuals who have not been convicted of a crime and are detained or awaiting trial or deportation hearings. These are generally run by state or federal agencies. 
      * `Prison Unit`: These are units within prisons. 
      * `Work Camp`: These are prisons that house individuals who generally work on significant labor projects like farming, land management, and firefighting. 
      * `Aged and Infirmed`: These are prisons that generally house older individuals and individuals with significant chronic diseases.
* `security`: Security level of the facility. This rating was designated by UCLA staff based on available information. Entities for which no designation could be made were left as NA. 
	* Potential values:
	    * `Max`: Maximum security (including close).
	    * `Med`: Medium security.
	    * `Min`: Minimum security.
	    * `Max/Med`: Maximum to medium security.
	    * `Max/Min`: Maximum to minimum security.
	    * `Med/Min`: Medium to minimum security. 
* `age`: Aged group kept in the entity if known. This rating was designated by UCLA staff based on available information. Entities for which no designation could be made were left as NA. 
	* Potential values:
	    * `A`: Adult only facility.
	    * `J`: Juvenile only facility.
	    * `B`: Mixed age facility.
* `gender`: Gender group kept in the entity if known. This rating was designated by UCLA staff based on available information. Entities for which no designation could be made were left as NA. 
	* Potential values:
	    * `M`: Male only facility.
	    * `F`: Female only facility.
	    * `B`: Mixed gender facility.
* `diff_operator_dummy`: Dummy variable indicating whether the entity is run by an organization different from the reporting jurisdiction (e.g. a private company or a county government).
	* Potential values:
	    * `Different Operator`
	    * `Unknown`
* `diff_operator`: The name of the organization operating the entity if the entity is run by an organization different from the reporting jurisdiction. 

* `capacity`: The capacity of the facility if known. This variable is a combination of reported capacity values from the HIFLD dataset and capacity values gathered by UCLA staff. When making this variable, capacity values gathered by UCLA staff were prioritized over capacity values from HIFLD if both were available. To find the source of capacity values consult the source_capacity dummy variable.
* `population`: The population of the facility as close to February 1, 2020 as possible if known. This variable is a combination of population values from the HIFLD dataset and population values gathered by UCLA staff through public records requests. When making this variable, population values gathered by UCLA staff were prioritized over population values from HIFLD if both were available. Staff-gathered population values were prioritized because they are closer to February 2020 than the HIFLD values, which come from the last several years, and they all come from the period of the pandemic. The next update of this dataset will include a new variable that identifies the exact source date for all population values. In the meantime, please consult the source_population variable to find the source of the population values.
* `hifld_id`: The associated ID for the entity in the HIFLD dataset if one has been identified. 
* `bjs_id`: The associated ID for the entity in the BJS dataset if one has been identified.
* `city`: The associated city for the entity from the HIFLD dataset. 
* `zipcode`: The associated zipcode for the entity from the HIFLD dataset. 
* `latitude`: The associated latitude for the entity.
* `longitude`: The associated longitude for the entity.
* `county`: The associated county for the entity from the HIFLD dataset.
* `county_fips`: The associated county FIPS code for the entity from the HIFLD dataset.
* `current`: This entity was still being reported on as of December 2020 when these designations were made. Entities that were not current were facilities formerly reported by a jurisdiction and did not receive designations.
	* Potential values:
	    * `Current`
	    * `Previous`
* `source_population`: The source of the population value in population.
	* Potential values:
	    * `Public Records`
	    * `HIFLD`
* `source_capacity`: The source of the capacity value in capacity.
	* Potential values:
	    * `Public Records`
	    * `HIFLD`

### Citations 

Citations for academic publications and research reports:

    Sharon Dolovich,
     Aaron Littman, Kalind Parish, Grace DiLaura, Chase Hommeyer,  Michael Everett, Hope Johnson, Neal Marquez, and Erika Tykagi. UCLA Law Covid-19 Behind Bars Data Project: Jail/Prison Confirmed Cases Dataset [date you downloaded the data]. UCLA Law, 2020, https://uclacovidbehindbars.org/.
 
Citations for media outlets, policy briefs, and online resources:

    UCLA Law Covid-19 Behind Bars Data Project, https://uclacovidbehindbars.org/.

### Data licensing

Our data is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/). That means that you must give appropriate credit, provide a link to the license, and indicate if changes were made. You may not use our work for commercial purposes, which means anything primarily intended for or directed toward commercial advantage or monetary compensation.
