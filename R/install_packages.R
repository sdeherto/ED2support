# List of CRAN packages to verify/install

cran_packages <- c(

  "abind", "agricolae", "akima", "beanplot", "boot", "callr", "car", "caTools", "chron",

  "cluster", "compiler", "data.table", "devtools", "FAdist", "fields", "gbm", "gdalUtils",

  "geoR", "gpclib", "grDevices", "gstat", "Hmisc", "klaR", "kriging", "leaps", "maps",

  "mapdata", "maptools", "MASS", "MCMCpack", "nlme", "numDeriv", "onls", "PBSmapping",

  "plotrix", "pls", "proto", "raster", "rgdal", "rgeos", "rlas", "robustbase", "rworldmap",

  "RSEIS", "R.utils", "smatr"

)



# Function to install missing CRAN packages

install_if_missing <- function(pkg) {

  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {

    message(sprintf("Installing package: %s", pkg))

    install.packages(pkg, repos = "https://cloud.r-project.org")

  } else {

    message(sprintf("Package already installed: %s", pkg))

  }

}



# Install CRAN packages

invisible(lapply(cran_packages, install_if_missing))



# Special handling for Bioconductor package: rhdf5

if (!require("rhdf5", quietly = TRUE)) {

  if (!require("BiocManager", quietly = TRUE)) {

    install.packages("BiocManager", repos = "https://cloud.r-project.org")

  }

  BiocManager::install("rhdf5", ask = FALSE, update = FALSE)

} else {

  message("Bioconductor package already installed: rhdf5")

}


