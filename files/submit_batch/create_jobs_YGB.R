rm(list = ls())

library(PEcAn.ED2)
library(rlist)
library(purrr)
library(dplyr)
source(file.path('/user/gent/465/vsc46573/scenarios/ED2scenarios/R',"write_job.R"))
source(file.path('/user/gent/465/vsc46573/scenarios/ED2scenarios/R',"write_bash_submission.R"))

list_modes <- c('bare','inventory_2020','inventory_static_2020')
#,'DRC_Yoko','IC_Yaya'
list_dir <- list()
conf<- 'vcmax80'
use_hydr<- FALSE

ED2IN_dir <- "/user/gent/465/vsc46573/ED2.2/ED2/ED/run"
if (use_hydr){
  outdir <- "/data/gent/vo/000/gvo00074/vsc46573/ED_out/hydr"
}else{outdir <- "/data/gent/vo/000/gvo00074/vsc46573/ED_out/default"}
rundir <- "/user/gent/465/vsc46573/YGB_jobs"
if(!dir.exists(ED2IN_dir)) dir.create(ED2IN_dir)
if(!dir.exists(outdir)) dir.create(outdir)


for (st in list_modes){
    print(st)
    if (use_hydr){name_scenar <- paste0('Yangambi_', st,"_GSWP_",conf,'_hydr')}
    else {name_scenar <- paste0('Yangambi_', st,"_GSWP_",conf)}  
    out_scenar <- file.path(outdir,name_scenar)
    if(!dir.exists(out_scenar)) dir.create(out_scenar)
    if(!dir.exists(file.path(out_scenar,"analysis"))) dir.create(file.path(out_scenar,"analysis"))
    if(!dir.exists(file.path(out_scenar,"history"))) dir.create(file.path(out_scenar,"history"))
    run_scenar <- file.path(rundir,name_scenar)
    if(!dir.exists(run_scenar)) dir.create(run_scenar)
    ED2IN <- read_ed2in(filename = file.path(ED2IN_dir,"ED2IN_def_Yangambi"))
    ED2IN.mod <- ED2IN
    ED2IN.mod$POI_LAT = 0.79
    ED2IN.mod$POI_LON = 24.45 
    ED2IN.mod$IYEARA <- 1700
    ED2IN.mod$IYEARZ <- 2050
    ED2IN.mod$METCYC1 <- 1980
    ED2IN.mod$METCYCF <- 2010
    ED2IN.mod$IEDCNFGF <- paste0('/user/gent/465/vsc46573/new/config_',conf,'.xml')
    ED2IN.mod$FFILOUT <-paste0(outdir,'/',name_scenar,'/analysis/analysis')  
    ED2IN.mod$SFILOUT <-paste0(outdir,'/',name_scenar,'/history/history')   
    if (st=='bare'){
      ED2IN.mod$IED_INIT_MODE <-0}
    else if (st=='inventory_2020'){
      ED2IN.mod$IED_INIT_MODE <-6
      ED2IN.mod$SFILIN = '/user/gent/465/vsc46573/new/YGB_2020_ED'}
    else if (st=='inventory_static_2020'){
      ED2IN.mod$IED_INIT_MODE <-6
      ED2IN.mod$SFILIN = '/user/gent/465/vsc46573/new/YGB_2020_ED'
      ED2IN.mod$IVEGT_DYNAMICS<-0}
    ED2IN.mod$ED_MET_DRIVER_DB <-paste0('/data/gent/vo/000/gvo00074/vsc46573/ED2_Support_Files/reanalysis_processing/GSWP/GSWP3v1.0/GSWP3v1.0_HEADER')
    ED2IN.mod$INCLUDE_THESE_PFT <- 3
    if (use_hydr){
      ED2IN.mod$H2O_PLANT_LIM<-3
      ED2IN.mod$PLANT_HYDRO_SCHEME<-1}
    ED2IN.mod$IPHYSIOL <- 3
    ED2IN.mod$SLXCLAY <- 0.3
    ED2IN.mod$SLXSAND <- 0.7
    ED2IN.mod$TRAIT_PLASTICITY_SCHEME <- -2
    ED2IN.mod$ISOILBC <- 1
    ED2IN.mod$ECONOMICS_SCHEME <- 1
    ED2IN.mod$REPRO_SCHEME <- 3
    ED2IN.mod$DECOMP_SCHEME <- 5
    ED2IN.mod$H2O_PLANT_LIM <- 5
    ED2IN.mod$IDDMORT_SCHEME  <- 1
    ED2IN.mod$ICANTURB <- 0
    ED2IN.mod$ISFCLYRM <- 4
    ED2IN.mod$TPRANDTL <- 1
    ED2IN.mod$IFUSION <- 1
    ED2IN.mod$TREEFALL_DISTURBANCE_RATE <-0.01
    ED2IN.mod$INITIAL_CO2 <-400
    ED2IN.mod$SOIL_HYDRO_SCHEME <- 2

    
    write_ed2in(ed2in = ED2IN.mod,
                filename <- paste0(ED2IN_dir,"/ED2IN_YGB/ED2IN_", name_scenar),
                custom_header = "",barebones = FALSE)
    
    write_job(file =  file.path(run_scenar,"job.sh"),
              nodes = 1,ppn = 18,mem = 16,walltime = 24,
              prerun = "ml  intel-compilers/2023.2.1 HDF5/1.14.3-iimpi-2023b UDUNITS/2.2.28-GCCcore-13.2.0; ulimit -s unlimited",
              CD = paste0(ED2IN_dir,"/ED2IN_YGB/"),
              ed_exec = "/user/gent/465/vsc46573/ED2.2/ED2/ED/build/ed_2.2-opt-master-f5acf6d6",
              ED2IN = paste0("ED2IN_", name_scenar),
              Rplot_function = '/user/gent/465/vsc46573/ED2support/R/read_save_plot_ED2.2.R')
    
    list_dir[[name_scenar]]=run_scenar

}

if (use_hydr){dumb <- write_bash_submission(file = file.path(rundir,paste0("all_jobs_YGB_hydr_",conf,".sh")),
                                                             list_files = list_dir,
                                                             job_name = "job.sh")}
if (!use_hydr) {dumb <- write_bash_submission(file = file.path(rundir,paste0("all_jobs_YGB_",conf,".sh")),
                              list_files = list_dir,
                              job_name = "job.sh")}
