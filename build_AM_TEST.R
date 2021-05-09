# Build AM Data ####

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# these data include:
#   - the New York Times county data, which is used to build county, metro,
#     regional, and state data sets for MO and adjacent areas
#   - CMS nursing home data, but only if they have been updated
#   - HHS hospitalization data, but only if they have been updated (in progress)

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# qa prompts ####

## Git pull from repos
print("git pull covid_automation_test...")
system("cd ~/repos/covid_automation_test && git pull")
print("git pull covid_automation_test complete!")

print("git pull MO_HEALTH_Covid_Tracking...")
system("cd ~/repos/MO_HEALTH_Covid_Tracking && git pull")
print("git pull MO_HEALTH_Covid_Tracking complete!")

## copying 'data' and 'source' from MO_Health -> covid_automation_test
print("copying MO_HEALTH_Covid_Tracking/data...")
system("cp -r ~/repos/MO_HEALTH_Covid_Tracking/data ~/repos/covid_automation_test/")
print("copy /data success!.")

print("copying MO_HEALTH_Covid_Tracking/source...")
system("cp -r ~/repos/MO_HEALTH_Covid_Tracking/source ~/repos/covid_automation_test/")
print("copy /source success!.")

## set working directory to MO_Health repo
setwd("~/repos/covid_automation_test")

## load function
source("source/functions/get_last_update.R")

## check last update
#q <- get_last_update(source = "New York Times")

## evaluate last update
#if (q == FALSE){
#  stop("AM update aborted!")
#}

## confirm auto update data
#auto_update <- usethis::ui_yeah("Do you want to automatically update the remote GitHub repo?")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# dependencies ####

## packages
### tidyverse
library(dplyr)          # data wrangling
library(lubridate)      # dates and times
library(purrr)          # functional programming
library(readr)          # csv file tools

### spatial
library(sf)             # mapping tools

### other
library(janitor)        # data wrangling
library(zoo)            # rolling means
library(rjson)

## functions
source("source/functions/get_data.R")         # call NYTimes API
source("source/functions/historic_expand.R")  # create empty data for zips by date

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# store date value
date <- Sys.Date()-1

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# execute daily workflow ####

print("# ==== # Executing 01 # ==== #")
source("source/workflow/01_scrape_and_tidy.R")
print("# ==== # 01 Complete! # ==== #")

print("# ==== # Executing 02 # ==== #")
source("source/workflow/02_create_state_msa.R")
print("# ==== # 02 Complete! # ==== #")

print("# ==== # Executing 03 # ==== #")
source("source/workflow/03_add_rates.R")
print("# ==== # 03 Complete! # ==== #")

print("# ==== # Executing 04 # ==== #")
source("source/workflow/04_create_spatial.R")
print("# ==== # 04 Complete! # ==== #")

print("# ==== # Executing 05 # ==== #")
source("source/workflow/05_create_regions.R")
print("# ==== # 05 Complete! # ==== #")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# execute weekly workflow ####

## check ltc metadata for update
update <- get_last_update(source = "CMS")
load("data/source/ltc/last_update.rda")

## rebuild ltc data if there has been an update
if ((update == last_update$current_date) == FALSE){
  source("source/workflow/11_create_ltc.R") 
}

## check hospitalization metadata for update
update <- get_last_update(source = "HHS")
load("data/source/hhs/last_update.rda")

## rebuild hhs data if there has been an update
if ((update == last_update$current_date) == FALSE){
  source("source/workflow/14_create_hhs.R") 
}

# Moving log file to RPi log folder
system("mv /home/pi/repos/covid_automation_test/build_AM_TEST.log /home/pi/logs/")

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# optionally pushed to GitHub
#if (auto_update == TRUE){

  system("git add -A")
  system(paste0("git commit -a -m 'build am data for ", as.character(date+1), "'"))
  system("git push")
  
#}

# ==== # === # === # === # === # === # === # === # === # === # === # === # === #

# clean-up ####
rm(date, update, get_last_update)