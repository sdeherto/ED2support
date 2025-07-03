# Load required libraries

library(ncdf4)  # For handling NetCDF files
library(reshape2)  # For data reshaping
library(tidyr)  # For data manipulation
library(dplyr) 

# Read command line arguments
args <- commandArgs(trailingOnly = TRUE)
# Example: print them to check
print(args)
# Assign them to variables
Model<-args[1]
Sitename<-args[2]

ForestType <- "regrowth"  # or "Regrowth"

outdir <- "/data/gent/vo/000/gvo00074/vsc46573/ED_out/default"
ncdir <- "/data/gent/vo/000/gvo00074/vsc46573/regrowth_MIP/"

if(!dir.exists(ncdir)) dir.create(ncdir)

# Define list of variables to extract

variables <- c("agb","agb_pft", "gpp_pft", "npp_pft","transp", "transp_pft", "lai_pft", "biomass", "biomass_pft",
               "broot", "broot_pft", 'hflxlc', 'hflxlc_pft', 'wflxlc', 'wflxlc_pft', 'plant.resp', 'plant.resp_pft')
variables_eco <- c("het.resp","fast.soil.c", "fast.grnd.c", "evap")
#               ,"cVeg", "cVegpft", "cRoot", "cRootpft", "clitter", "csoil",
#               "tas", "pr", "rsds", "mrso", "mrro", "evapotrans", "evapotranspft", "transpft", 
#               "evapo", "albedopft", "shflxpft", "rnpft",
#               "gpp", "ra", "npp", "rh", "nbp", "gpppft", "npppft", "rhpft", "nbppft", 
#               "landCoverFrac", "oceanCoverFrac", "lai", "laipft", "cLeaf", "cWood", "cCwd", 
#               "cSoilpools", "fVegLitter", "fLeafLitter", "fWoodLitter", "fRootLitter", 
#               "fLitterSoil", "fVegSoil", "rhpool", "fAllocLeaf", "fAllocWood", "fAllocRoot",
#               "tsl", "msl", "evspsblveg", "evspsblsoi", "tran", "tskinpft", "mslpft", "theightpft")



#read in additional info for disturbance simulations
df_sites <- read.csv("/data/gent/vo/000/gvo00074/vsc46573/regrwoth_MIP/data2share/sites.locations.csv", stringsAsFactors = FALSE)
df_site <- df_sites %>% filter(site == Sitename)

# Determine the age of the forest
if (ForestType == "Oldgrowth") {
  Age <- 300
  name_scenar <- paste0(Sitename,"_oldgrowth_1400-2023/")
  out_scenar <- file.path(outdir,name_scenar)
  start <- 1700
} else {
  # Load plot age data
  df_ages <- read.csv("/data/gent/vo/000/gvo00074/vsc46573/regrwoth_MIP/data2share/plot_ages.csv", stringsAsFactors = FALSE)
  df_age <- df_ages %>% filter(site == Sitename)
  time_init_values <- as.numeric(df_age$time_ini)
  time_end_values <- as.numeric(df_age$time_end)
  Age_values <- as.numeric(df_age$age)
  for (i in seq_along(time_init_values)) {
    print(as.numeric(time_init_values[[i]]))
    print(as.numeric(time_end_values[[i]]))
    start <- as.numeric(time_init_values[[i]])
    name_scenar <- paste0(Sitename,"_regrowth_",time_init_values[[i]],'-',time_end_values[[i]])
    print(name_scenar)
    out_scenar <- file.path(outdir,name_scenar)
    old_scenar <- paste0(Sitename,"_oldgrowth_1400-2023/")
    path_to_old <- file.path(outdir,old_scenar)
    if(!dir.exists(out_scenar)) dir.create(out_scenar)
    if(!dir.exists(file.path(out_scenar,"analysis"))) dir.create(file.path(out_scenar,"analysis"))
    if(!dir.exists(file.path(out_scenar,"history"))) dir.create(file.path(out_scenar,"history"))
    #run_scenar <- file.path(rundir,name_scenar)
    
    # Define paths ## to update and include in loop before 
    ## added difficulty will need to ctraete a loop to go through series of cases for regrowth case
    input_file <- paste0(out_scenar,"/analysis/analysis.RData")  # Change this to your actual file
    write_dir <- paste0(ncdir,name_scenar)
    dir.create(write_dir, showWarnings = FALSE)
    
    # Load .Rdata file
    load(input_file)
    
    #extract timeseries datum$szpft$agb[,12,18]
    
    # Iterate over each variable and write to NetCDF
    for (var in variables) {
      pft_flag <- 0
      if (substr(var, nchar(var) - 3, nchar(var)) == "_pft") {
        pft_flag <- 1
        nc_filename <- sprintf("%s_%s_%s_%s_%s.nc", Model, Sitename, ForestType, Age_values[[i]], var)
        var <- substr(var, 1, nchar(var) - 4)
        print(var)
        data <- datum$szpft[var][[1]][, , 18]}
      else {
        data <- datum$szpft[var][[1]][, 12, 18]
        nc_filename <- sprintf("%s_%s_%s_%s_%s.nc", Model, Sitename, ForestType, Age_values[[i]], var)
      } 
      nc_filepath <- file.path(write_dir, nc_filename)
      
      # Assuming data has dimensions: [lon, lat, PFT, time]
      # Modify below if necessary based on your data structure
      timdim <- length(datum$szpft['agb'][[1]][, 12, 18])
      lon_dim <- ncdim_def("lon", "degrees_east", df_site$lon)  # Adjust as needed
      lat_dim <- ncdim_def("lat", "degrees_north", df_site$lat)  # Adjust as needed
      if (pft_flag == 1) {
        pft_dim <- ncdim_def("PFT", "unitless", seq(1, 12))  # Adjust as needed
        time_dim <- ncdim_def("time", paste0("months since January ", start), seq(1, timdim))  # Modify based on actual time data
        # Define NetCDF variable
        nc_var <- ncvar_def(var, "units", list(lon_dim, lat_dim, pft_dim, time_dim), missval = -99999, longname = var)
      } else {
        time_dim <- ncdim_def("time", paste0("months since ", start), seq(1, timdim))  # Modify based on actual time data
        # Define NetCDF variable
        nc_var <- ncvar_def(var, "units", list(lon_dim, lat_dim, time_dim), missval = -99999, longname = var)
      }      
      # Create and write NetCDF file
      nc_out <- nc_create(nc_filepath, nc_var)
      ncvar_put(nc_out, nc_var, data)
      # Close NetCDF file
      nc_close(nc_out)
      print(paste("Written:", nc_filepath))
    }

for (var in variables_eco) {
   data <- datum$emean[[var]]
   nc_filename <- sprintf("%s_%s_%s_%d_%s.nc", Model, Sitename, ForestType, Age_values[[i]], var)
   nc_filepath <- file.path(write_dir, nc_filename)

      # Assuming data has dimensions: [lon, lat, time]
      # Modify below if necessary based on your data structure
   timdim <- length(datum$emean[[var]])
   print(timdim)
   lon_dim <- ncdim_def("lon", "degrees_east", df_site$lon)  # Adjust as needed
   lat_dim <- ncdim_def("lat", "degrees_north", df_site$lat)  # Adjust as needed
   time_dim <- ncdim_def("time", paste0("months since ", start), seq(1, timdim))  # Modify based on actual time data
   # Define NetCDF variable
   nc_var <- ncvar_def(var, "units", list(lon_dim, lat_dim, time_dim), missval = -99999, longname = var)
      # Create and write NetCDF file
   nc_out <- nc_create(nc_filepath, nc_var)
   ncvar_put(nc_out, nc_var, data)
      # Close NetCDF file
   nc_close(nc_out)
   print(paste("Written:", nc_filepath))
    }
}}


print("All NetCDF files created successfully.")

