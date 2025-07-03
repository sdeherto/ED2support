#!/bin/bash

Model="ED2"
sites=(
  "ANG_Cusseque_Chutembo_Bie"
  "CAM_Mpem_et_Djim_NP"
  "DRC_Babagulu"
  "DRC_Djolu"
  "DRC_Sakania"
  "DRC_Salonga"
  "GAB_Lope"
  "GU_Soyah"
  "GU_Ziama"
  "Gh_Abofour"
  "Gh_Bonsa"
  "IC_Agbo1"
  "IC_Badenou"
  "IC_Foumbou"
  "IC_Ht_sassandra"
  "IC_Irobo"
  "IC_Niegre"
  "IC_Tene"
  "Ken_Nyatike"
  "LIB_Gola"
  "LIB_Sapo"
  "LIB_Wonegizi"
  "MOZ_GileNatPark"
  "SL_Gola"
  "SL_Outamba"
  "TAN_Kilwa"
  "ZAM_Chintumukulu"
)

# Loop and submit

ml purge
ml R-bundle-Bioconductor/3.18-foss-2023a-R-4.3.2
for SITENAME in "${sites[@]}"; do
  echo "Submitting job for $SITENAME"
  Rscript convert_Rdata_to_nc_oldgrowth.R $Model $SITENAME
  Rscript convert_Rdata_to_nc_regrowth.R $Model $SITENAME

done
duration=$SECONDS

echo "$((duration / 60)) minutes and $((duration % 60)) seconds elapsed."

