library(tidyverse)
library(here)
library(janitor)
library(reshape)

#Goals: 
#Merge Contacts - Connections
#ID everyone who visited system around Harvey
#ID Harvey victims with indicators

#Ways to ID missing 9/11 vets
    #Entrance date if missing separation (~250); brings in 151 extras
    #Separation date if missing entrance (~5); Brings in 1 extra
    #Age if missing both (~12); doesn't bring any extras in
    #2765 clients are post-9/11 verified

#Import datasets
contact <- read_csv(here::here("cax_data", "Contact.csv")) %>% 
  reshape::rename(c(
    Id = "ContactId", #Rename Id to ContactId for merging
    CreatedDate = "enteredDate"
  )) %>% 
  mutate(
    #ID post-911 vets
    enteredService_post911 = ifelse(ads_resourceman__Date_Entered_Service__c>="2001-09-11", 1, 0),
    exitService_post911 = ifelse(ads_resourceman__Separation_Date__c>="2001-09-11", 1, 0),
    age_post911 = ifelse(Birthdate>="1983-09-11", 1, 0), #Turned 18 after 9/11
    
    post911 = ifelse(Era__c == "Post 9/11 | GWOT", 1, 0),
    post911 = ifelse(is.na(post911) & enteredService_post911==1, 1, post911),
    post911 = ifelse(is.na(post911) & exitService_post911==1, 1, post911),
    post911 = ifelse(is.na(post911) & Birthdate==1, 1, post911),
    
    #Demographics
    gender = ads_resourceman__Gender__c,
    racethn = ifelse(ads_resourceman__Ethnicity__c %in% c("White;White", "White"), "White",
                     ifelse(ads_resourceman__Ethnicity__c %in% c("Black"), "Black",
                            ifelse(ads_resourceman__Ethnicity__c %in% c("Latino", "Latino;Latino"), "Latino",
                                   ifelse(ads_resourceman__Ethnicity__c %in% c("Asian", "Pacific Islander"), "Asian/Pacific Islander",
                                          ifelse(!is.na(ads_resourceman__Ethnicity__c), "Other/Multiple/Unknown", NA))))),
    edu_level = ads_resourceman__Education_Level__c,
    edu_status = ads_resourceman__Current_Education_Status__c,
    emp_status = ads_resourceman__Current_Employment_Status__c,
    housing_status = ads_resourceman__Current_Housing_Status__c,
    marital_status = ads_resourceman__Marital_Status__c,
    kid_status = ads_resourceman__Children__c,
    zipcode = MailingPostalCode, #It's not bad
    
    #Needs
    satisfied_w_life = ads_resourceman__Satisfied_with_life__c,
    
    #Id Harvey victims
    enteredDuringHarvey = ifelse(enteredDate>="2017-08-25 00:00:00 UTC" & enteredDate<="2017-11-01 00:00:00 UTC", 1, 0),
    
    harveyVictim = ifelse(Affected_by_Harvey__c=="Yes" | 
                            Harvey_Status__c %in% c('<img src="/resource/1504528772000/Harvey_Red_House" alt=" " border="0"/>',
                                                    '<img src="/resource/1504528794000/Harvey_Yellow_House" alt=" " border="0"/>',
                                                    '<img src="/resource/1504528828000/Harvey_Green_House" alt=" " border="0"/>'), 
                          1, 0),
    harveyVictim = ifelse(is.na(harveyVictim), 0, harveyVictim),
    
    riskHarveyVictim = ifelse(enteredDuringHarvey==1 & harveyVictim==0, "Entered during Harvey; no Harvey reported",
                              ifelse(harveyVictim==1, "Harvey reported", "")),
    
    
  )

contact_names <- as.data.frame(names(contact))

# 
# Mental_Health_Score__c
# Mental_Health_Services__c
# Mental_Health_Status__c
# 


#How many Harvey victims were new to CAX?
#Could we ID others based on flooding in their area?

#Note: Era__c has 70% missing values; can't find discharge date


#Connection: "ConnectionReceivedId" "ConnectionSentId" 
#"CreatedDate"   Interviews__c

#Connection
connection <- read_csv(here::here("cax_data", "Connection.csv")) 

#Resource: ads_resourceman__Resource_Name__c, ads_resourceman__Resource__c
#Type of service provided: ads_resourceman__Service_Category_Name__c


#Merge Connection to Contact to ID additional 
connection_service_harvey <- connection %>% 
  mutate(
    harvey_service = ifelse(ads_resourceman__Resource_Name__c %in% c("Disabled American Veterans-Internal Disaster Financial Relief",
                                                                     "Team Rubicon-Disaster Response",
                                                                     "Combined Arms Resources-Internal Disaster Financial Relief",
                                                                     "Grace After Fire-Internal Disaster Financial Relief",
                                                                     "Lone Star Veterans Association-Internal Disaster Financial Relief",
                                                                     "Wounded Warrior Project-Internal Disaster Financial Relief",
                                                                     "TexVet-Disaster Unemployement") |
                              ads_resourceman__Service_Category_Name__c=="Harvey Relief Services" ,1, 0)
  ) %>% 
  filter(harvey_service==1 & CreatedDate>"2017-08-25 00:00:00 UTC") %>% 
  arrange(CreatedDate) %>% 
  dplyr::select(CreatedDate, ContactId, ads_resourceman__Resource_Name__c, harvey_service) %>% 
  count(ContactId) %>% 
  dplyr::rename("harvey_services" = "n")

names(connection)

contact <- left_join(contact, connection_service_harvey, by="ContactId") %>% 
  mutate(
    harveyVictim = ifelse(harveyVictim==0 & harvey_services>=1, 1, harveyVictim),
    harveyVictim = ifelse(is.na(harveyVictim), 0, harveyVictim)
  )
  

#Merged Contact and Connection
contact_to_merge <- dplyr::select(contact, ContactId, Name, post911:riskHarveyVictim) 

merged <- left_join(connection, contact_to_merge, by="ContactId") %>% 
  arrange(ContactId, CaseNumber, CreatedDate) %>% 
  dplyr::select(ContactId, Name:riskHarveyVictim, CaseNumber, CreatedDate, ClosedDate, everything())


#Remove extraneous datasets-----
rm(contact_to_merge, contact_names, connection_service_harvey, contact, connection)


#EXPORT -----
conn_grab <- merged %>%
  filter(CreatedDate>="2017-08-25 00:00:00 UTC" & CreatedDate<="2017-11-30 00:00:00 UTC") %>%
  filter(harveyVictim==1) %>% 
  dplyr::select(ContactId, CaseNumber, CreatedDate, ClosedDate, 
                Response_Met__c, post911, harveyVictim, ads_resourceman__Organization__c,
                ads_resourceman__Service_Category_Name__c) %>%
  dplyr::rename(ResponseDate = Response_Met__c,
                ServiceProvider = ads_resourceman__Organization__c,
                ServiceProviderCategory = ads_resourceman__Service_Category_Name__c) %>% 
  write_csv(here::here("build", "clean_data.csv"))


