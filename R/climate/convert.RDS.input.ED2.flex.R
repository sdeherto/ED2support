rm(list = ls())

library(ncdf4)
library(dplyr)
library(lubridate)
library(tibble)
library(glue)
library(utils)
library(udunits2)
library(hdf5r)


source("/user/gent/465/vsc46573/ED2support/R/convert.newdata.spinup.R")
#source("./convert.CRUNCEP_mul.R")
#source("./convert.CRUNCEP_div.R")
source("/user/gent/465/vsc46573/ED2support/R/other.functions.R")

# Read command line arguments
args <- commandArgs(trailingOnly = TRUE)
# Example: print them to check
print(args)
# Assign them to variables
year1<-as.integer(args[1])
year2<-as.integer(args[2])
		
flag <- as.integer(args[4])
sitename <- args[3]




output.folder <- "/scratch/gent/465/vsc46573/ED2/"
all.years <- year1:year2
lat <- NA
lon <- NA
site <- sitename
leap <- FALSE
trans_co2 <- flag
#######################################################################
# No change beyond this point

dir.create(output.folder,
           showWarnings = FALSE)

convert.CRUNCEP(in.path = file.path('/data/gent/vo/000/gvo00074/vsc46573/met/Meteo_RDS/'),
                in.prefix = site,
                outfolder = file.path('/data/gent/vo/000/gvo00074/vsc46573/met/Meteo_RDS/ED2'),
                start_date = paste0(min(all.years),"/01/01"),
                end_date = paste0(max(all.years),"/12/31"),
                lst = 0,
                lat = lat,
                lon = lon,
                overwrite = TRUE,
                verbose = FALSE,
                leap_year = leap,
                trans_co2 = trans_co2)


