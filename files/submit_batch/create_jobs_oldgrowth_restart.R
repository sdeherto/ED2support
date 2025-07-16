rm(list = ls())

library(PEcAn.ED2)
library(rlist)
library(purrr)
library(dplyr)
source(file.path('/user/gent/465/vsc46573/scenarios/ED2scenarios/R',"write_job.R"))
source(file.path('/user/gent/465/vsc46573/scenarios/ED2scenarios/R',"write_bash_submission.R"))

ED2IN_dir <- "/user/gent/465/vsc46573/ED2.2/ED2/ED/run"
outdir <- "/data/gent/vo/000/gvo00074/vsc46573/ED_out/default"
rundir <- "/user/gent/465/vsc46573/regrwoth_jobs"
if(!dir.exists(ED2IN_dir)) dir.create(ED2IN_dir)
if(!dir.exists(outdir)) dir.create(outdir)

#read in additional info for disturbance simulations
#df_ages <- read.csv("/data/gent/vo/000/gvo00074/vsc46573/regrwoth_MIP/data2share/plot_ages.csv", stringsAsFactors = FALSE)
df_sites <- read.csv("/data/gent/vo/000/gvo00074/vsc46573/regrwoth_MIP/data2share/sites.locations.csv", stringsAsFactors = FALSE)

#list_sites <- c('IC_Yaya','DRC_Yoko','DRC_Baego')
#,'DRC_Yoko','IC_Yaya'
#list_sites <- c('ANG_Cusseque_Chutembo_Bie','CAM_Mpem et Djim NP','DRC_Babagulu','DRC_Djolu','DRC_Sakania','DRC_Salonga','GAB_Lope','GU_Soyah','GU_Ziama','Gh_Abofour','Gh_Bonsa','IC_Agbo1','IC_Badenou','IC_Foumbou','IC_Ht_sassandra','IC_Irobo','IC_Niegre','IC_Tene','Ken_Nyatike','LIB_Gola','LIB_Sapo','LIB_Wonegizi','MOZ_GileNatPark','SL_Gola','SL_Outamba','TAN_Kilwa','ZAM_Chintumukulu')
#list_sites <- c('DRC_Djolu','DRC_Babagulu','DRC_Sakania','DRC_Salonga','GU_Ziama','IC_Badenou')
#list_sites <- c('ZAM_Chintumukulu','Ken_Nyatike','Gh_Abofour','IC_Agbo1','SL_Outamba','IC_Tene','IC_Irobo','IC_Foumbou')
list_sites <- c('ZAM_Chintumukulu','SL_Outamba')
list_sites <- c('GU_Soyah','Gh_Bonsa','IC_Ht_sassandra','IC_Irobo','IC_Niegre','IC_Tene','Ken_Nyatike','LIB_Gola','LIB_Sapo','LIB_Wonegizi','MOZ_GileNatPark','SL_Gola','TAN_Kilwa','GAB_Lope')
list_sites <- c('GU_Soyah','Gh_Bonsa','IC_Ht_sassandra','IC_Irobo','IC_Niegre','IC_Tene','Ken_Nyatike','LIB_Gola','LIB_Sapo','LIB_Wonegizi','MOZ_GileNatPark','SL_Gola','TAN_Kilwa','GAB_Lope')
list_sites <- c('ANG_Cusseque_Chutembo_Bie','CAM_Mpem_et_Djim_NP')
list_sites <- c('Gh_Bonsa','GAB_Lope','MOZ_GileNatPark')
list_sites <- c('LIB_Wonegizi')
year_restart <- 1905
list_dir <- list()

for (st in list_sites){
  print(st)
  df_site <- df_sites %>% filter(site == st)
  time_init_value <- 1400
  time_end_value <- 2023
  name_scenar <- paste0(st,"_oldgrowth_",time_init_value,'-',time_end_value)
  print(name_scenar)
  out_scenar <- file.path(outdir,name_scenar)
  if(!dir.exists(out_scenar)) dir.create(out_scenar)
  if(!dir.exists(file.path(out_scenar,"analysis"))) dir.create(file.path(out_scenar,"analysis"))
  if(!dir.exists(file.path(out_scenar,"history"))) dir.create(file.path(out_scenar,"history"))
  run_scenar <- file.path(rundir,name_scenar)
  if(!dir.exists(run_scenar)) dir.create(run_scenar)
  ED2IN <- read_ed2in(filename = file.path(ED2IN_dir,"ED2IN_def_Yangambi"))
  ED2IN.mod <- ED2IN
  ED2IN.mod$POI_LAT <- as.numeric(df_site$lat)
  ED2IN.mod$POI_LON <- as.numeric(df_site$lon)
  ED2IN.mod$IYEARA <- year_restart
  ED2IN.mod$IYEARZ <- time_end_value
  ED2IN.mod$METCYC1 <- year_restart
  ED2IN.mod$METCYCF <- time_end_value
  
  ED2IN.mod$FFILOUT <-paste0(outdir,'/',st,'_oldgrowth_',as.character(time_init_value),'-',as.character(time_end_value),'/analysis/analysis')  
  ED2IN.mod$SFILOUT <-paste0(outdir,'/',st,'_oldgrowth_',as.character(time_init_value),'-',as.character(time_end_value),'/history/history')   
  ED2IN.mod$RUNTYPE <-'HISTORY'
  ED2IN.mod$IED_INIT_MODE <-6
  ED2IN.mod$SFILIN <- paste0(outdir,'/',st,'_oldgrowth_',as.character(time_init_value),'-',as.character(time_end_value),'/history/history')
  ED2IN.mod$IYEARH = year_restart

  ED2IN.mod$ED_MET_DRIVER_DB <-paste0('/data/gent/vo/000/gvo00074/vsc46573/met/Meteo_RDS/ED2/',st,'/co2/ED_MET_DRIVER_HEADER')
  ED2IN.mod$INCLUDE_THESE_PFT <- c(2,3,4)
  write_ed2in(ed2in = ED2IN.mod,
              filename <- paste0(ED2IN_dir,"/ED2IN_regrowth/ED2IN_", st, "_oldgrowth_restart_",as.character(year_restart),"-",as.character(time_end_value)),
              custom_header = "",barebones = FALSE)
  
  write_job(file =  file.path(run_scenar,"job_restart.sh"),
            nodes = 1,ppn = 18,mem = 16,walltime = 30,
            prerun = "ml  intel-compilers/2023.2.1 HDF5/1.14.3-iimpi-2023b UDUNITS/2.2.28-GCCcore-13.2.0; ulimit -s unlimited",
            CD = paste0(ED2IN_dir,"/ED2IN_regrowth/"),
            ed_exec = "/user/gent/465/vsc46573/ED2.2/ED2/ED/build/ed_2.2-opt-master-f5acf6d6",
            ED2IN = paste0("ED2IN_", st, "_oldgrowth_restart_",as.character(year_restart),"-",as.character(time_end_value)))
  
  list_dir[[name_scenar]]=run_scenar
}

dumb <- write_bash_submission(file = file.path(rundir,"all_jobs_oldgrowth_restart.sh"),
                              list_files = list_dir,
                              job_name = "job_restart.sh")
