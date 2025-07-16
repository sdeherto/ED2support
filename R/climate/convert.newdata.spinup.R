convert.CRUNCEP <- function(in.path,
                            in.prefix = "DRC_Baego",
                            outfolder,
                            start_date = "1401/01/01",
                            end_date = "1900/12/31",
                            lst = 0,
                            lat = NA,
                            lon = NA,
                            overwrite = TRUE,
                            verbose = FALSE,
                            leap_year = TRUE,
                            trans_co2=TRUE){

  overwrite <- as.logical(overwrite)

  start_date <- as.POSIXlt(start_date, tz = "UTC")
  end_date <- as.POSIXlt(end_date, tz = "UTC")
  met_folder <- file.path(outfolder, in.prefix)
  if (trans_co2){
    met_folder <- file.path(met_folder,'co2')
  }
  met_header_file <- file.path(met_folder, "ED_MET_DRIVER_HEADER")
  co2_path <-file.path(outfolder,'global_co2_ann_1700_2023.txt')
  print(met_header_file)
  results <- data.frame(file = met_header_file, host = fqdn(),
                        mimetype = "text/plain", formatname = "ed.met_driver_header files format",
                        startdate = start_date, enddate = end_date, dbfile.name = "ED_MET_DRIVER_HEADER",
                        stringsAsFactors = FALSE)
  dir.create(met_folder, recursive = TRUE, showWarnings = FALSE)
  dm <- c(0, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305,
          335, 366)
  dl <- c(0, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306,
          336, 367)
  month <- c("JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL",
             "AUG", "SEP", "OCT", "NOV", "DEC")
  mon_num <- c("01", "02", "03", "04", "05", "06", "07", "08",
               "09", "10", "11", "12")

  day2mo <- function(year, day, leap_year) {
    mo <- rep(NA, length(day))
    if (!leap_year) {
      mo <- findInterval(day, dm)
      return(mo)
    }
    else {
      leap <- lubridate::leap_year(year)
      mo[leap] <- findInterval(day[leap], dl)
      mo[!leap] <- findInterval(day[!leap], dm)
      return(mo)
    }
  }
  start_year <- lubridate::year(start_date)
  end_year <- lubridate::year(end_date)
  year_seq <- seq(start_year, end_year)
  day_secs <- udunits2::ud.convert(1, "day", "seconds")
  need_input_files <- file.path(in.path, paste('climate',in.prefix, "RDS", sep = "."))
  have_input_files <- file.exists(need_input_files)
  if (!all(have_input_files)) {
    stop(paste("Missing the following required input files: ",
               paste(sprintf("'%s'", need_input_files[!have_input_files]),
                     collapse = ", ")))
  }
  month_seq <- seq(lubridate::floor_date(start_date, "month"),
                   lubridate::floor_date(end_date, "month"), by = "1 month")
  target_fnames <- paste0(toupper(strftime(month_seq, "%Y%b",
                                           tz = "UTC")), ".h5")
  target_out_files <- file.path(met_folder, target_fnames)
  have_target_out_files <- file.exists(target_out_files)
  if (any(have_target_out_files)) {
    if (overwrite) {
      warning(paste("The following existing target output files will be overwritten:",
                                paste(sprintf("'%s'", target_out_files[have_target_out_files]),
                                      collapse = ", ")))
    }
    else {
      have_output_byyear <- split(have_target_out_files,
                                  lubridate::year(month_seq))
      complete_years <- vapply(have_output_byyear, all,
                               logical(1))
      skip_years <- tryCatch(as.numeric(names(complete_years[complete_years])),
                             warning = function(e) stop(e))
      warning(paste("The following output files already exist:",
                                paste(target_out_files[have_target_out_files]),
                                ". This means the following complete years will be skipped: ",
                                skip_years))
      year_seq <- setdiff(year_seq, skip_years)
    }
  }
  i=-1
  for (year in year_seq) {
    i=i+1
    print(i)
    if (year< 1901){
      year_co2=year
      year=1901+i}
    if (year>1910){
      year=1901
      i=0
    }
    print(year)
    print(year_co2)
    ncfile <- file.path(in.path, paste('climate',in.prefix,
                                       "RDS", sep = "."))
    nc <- readRDS(ncfile)
    nc$time <- as.POSIXct(nc$time, format="%Y-%m-%d %H:%M:%S")
    nc <- nc %>% filter(format(time, "%Y") == as.character(year))

    flat <- nc['lat'][[1]][1]
    if (is.na(lat)) {
      lat <- flat
    }
    else if (lat != flat) {
      warning(paste("Latitude does not match that of file",
                    lat, "!=", flat))
    }
    flon <- nc['lon'][[1]][1]
    if (is.na(lon)) {
      lon <- flon
    }
    else if (lon != flon) {
     warning(paste("Longitude does not match that of file",
                   lon, "!=", flon))
    }

    # lat <- eval(parse(text = lat))
    # lon <- eval(parse(text = lon))
    sec <- as.numeric(nc$time)
    Tair <- nc$tmp
    Qair <- nc$spfh
    Rain <- nc$pre/(6*60*60)
    pres <- nc$pres
    SW <- nc$dswrf/(6*60*60)
    LW <- nc$dlwrf
    U <- nc$ugrd
    V <- nc$vgrd

    if (trans_co2){
      #read csv and put in vector format..
      # Read the file into a dataframe
      CO2 <- read.table("/data/gent/vo/000/gvo00074/vsc46573/met/Meteo_RDS/global_co2_ann_1700_2023.txt", header = FALSE)
      # Assign column names
      colnames(CO2) <- c("Year", "CO2_Concentration")
      # CO2 %>% filter(Year>1900)
      }
    else {CO2 <- NULL}

    use_UV <- is.numeric(U) & is.numeric(V)
    if (!use_UV) {
      U <- try(nc$U, silent = TRUE)
      if (is.numeric(U)) {
        warning("eastward_wind and northward_wind are absent, using wind_speed to approximate eastward_wind")
        V <- rep(0, length(U))
      }
      else {
        stop("No eastward_wind and northward_wind or wind_speed in the met data")
      }
    }
    useCO2 <- !is.null(CO2)
    dt <- seconds_in_year(year, leap_year)/length(sec)
    toff <- -as.numeric(lst) * 3600/dt
    # slen <- seq_along(SW)
    # Tair <- c(rep(Tair[1], toff), Tair)[slen]
    # Qair <- c(rep(Qair[1], toff), Qair)[slen]
    # U <- c(rep(U[1], toff), U)[slen]
    # V <- c(rep(V[1], toff), V)[slen]
    # Rain <- c(rep(Rain[1], toff), Rain)[slen]
    # pres <- c(rep(pres[1], toff), pres)[slen]
    # SW <- c(rep(SW[1], toff), SW)[slen]
    # LW <- c(rep(LW[1], toff), LW)[slen]
    # if (useCO2) {
    #   CO2 <- c(rep(CO2[1], toff), CO2)[slen]
    # }
    skip <- FALSE
    nyr <- floor(length(sec) * dt/86400/365)
    yr <- NULL
    doy <- NULL
    hr <- NULL
    asec <- sec
    for (y in seq(year, year + nyr - 1)) {
      diy <- days_in_year(y, leap_year)
      ytmp <- rep(y, udunits2::ud.convert(diy/dt, "days",
                                          "seconds"))
      dtmp <- rep(seq_len(diy), each = day_secs/dt)
      if (is.null(yr)) {
        yr <- ytmp
        doy <- dtmp
        hr <- rep(NA, length(dtmp))
      }
      else {
        yr <- c(yr, ytmp)
        doy <- c(doy, dtmp)
        hr <- c(hr, rep(NA, length(dtmp)))
      }
      rng <- length(doy) - length(ytmp):1 + 1
      if (!all(rng >= 0)) {
        skip <- TRUE
        warning(paste(year, " is not a complete year and will not be included"))
        break
      }
      asec[rng] <- asec[rng] - asec[rng[1]]
      hr[rng] <- (asec[rng] - (dtmp - 1) * day_secs)/day_secs *
        24
    }
    mo <- day2mo(yr, doy, leap_year)
    if (length(yr) < length(sec)) {
      rng <- (length(yr) + 1):length(sec)
      if (!all(rng >= 0)) {
        skip <- TRUE
        warning(paste(year, "is not a complete year and will not be included"))
        break
      }
      yr[rng] <- rep(y + 1, length(rng))
      doy[rng] <- rep(1:366, each = day_secs/dt)[1:length(rng)]
      hr[rng] <- rep(seq(0, length = day_secs/dt, by = dt/day_secs *
                           24), 366)[1:length(rng)]
    }
    if (skip) {
      print("Skipping to next year")
      next
    }


    ugrdA <- U
    vgrdA <- V
    shA <- Qair
    tmpA <- Tair
    dlwrfA <- LW
    presA <- pres
    prateA <- Rain

    print(useCO2)
    if (useCO2) {
      if (year_co2<1700)
        {co2A <- numeric(length(nc$dlwrf))
         co2A[] <- 276.59}
      else
        {co2_df <- CO2 %>% filter(Year==year_co2)
         co2_value <- as.numeric(co2_df$CO2_Concentration)
         co2A <- numeric(length(nc$dlwrf))
         co2A[] <- co2_value}

      # Check the result
      print(co2A)

    }

    nbdsfA <- nddsfA <- vbdsfA <- vddsfA <- NA*pres

    clat <- lat
    clon <- lon

    cosz <- cos_solar_zenith_angle(doy,
                                   clat, clon, dt, hr)
    rpot <- 1366 * cosz
    rpot <- rpot[1:length(SW)]

    if(all(is.na(SW))) next()
    SW[rpot < SW] <- rpot[rpot < SW]

    frac <- SW/rpot
    frac[frac > 0.9] <- 0.9
    frac[frac < 0] <- 0
    frac[is.na(frac)] <- 0
    frac[is.nan(frac)] <- 0

    SWd <- SW * (1 - frac)
    nbdsfA <- (SW - SWd) * 0.57
    nddsfA <- SWd* 0.48
    vbdsfA <- (SW - SWd) * 0.43
    vddsfA <- SWd * 0.52

    hgtA <- 50*(Rain**0)
    for (y in year + 1:nyr - 1) {
      sely <- which(yr == y)
      for (m in unique(mo[sely])) {
        selm <- sely[which(mo[sely] == m)]
        mout <- paste(met_folder, "/", year_co2, month[m],
                      ".h5", sep = "")
        if (file.exists(mout)) {
          if (overwrite) {
            file.remove(mout)
            ed_met_h5 <- hdf5r::H5File$new(mout)
          }
          else {
            warning("The file already exists! Moving to next month!")
            next
          }
        }
        else {
          ed_met_h5 <- hdf5r::H5File$new(mout)
        }
        dims  <- c(length(selm), 1, 1)
        nbdsf <- array(nbdsfA[selm], dim = dims)
        nddsf <- array(nddsfA[selm], dim = dims)
        vbdsf <- array(vbdsfA[selm], dim = dims)
        vddsf <- array(vddsfA[selm], dim = dims)
        prate <- array(prateA[selm], dim = dims)
        dlwrf <- array(dlwrfA[selm], dim = dims)
        pres  <- array(presA[selm], dim = dims)
        hgt   <- array(hgtA[selm], dim = dims)
        ugrd  <- array(ugrdA[selm], dim = dims)
        vgrd  <- array(vgrdA[selm], dim = dims)
        sh    <- array(shA[selm], dim = dims)
        tmp   <- array(tmpA[selm], dim = dims)
        if (useCO2) {
          co2 <- array(co2A[selm], dim = dims)
        }

        ed_met_h5[["nbdsf"]] <- nbdsf
        ed_met_h5[["nddsf"]] <- nddsf
        ed_met_h5[["vbdsf"]] <- vbdsf
        ed_met_h5[["vddsf"]] <- vddsf
        ed_met_h5[["prate"]] <- prate
        ed_met_h5[["dlwrf"]] <- dlwrf
        ed_met_h5[["pres"]] <- pres
        ed_met_h5[["hgt"]] <- hgt
        ed_met_h5[["ugrd"]] <- ugrd
        ed_met_h5[["vgrd"]] <- vgrd
        ed_met_h5[["sh"]] <- sh
        ed_met_h5[["tmp"]] <- tmp
        if (useCO2) {
          ed_met_h5[["co2"]] <- co2
        }
        ed_met_h5$close_all()
      }
    }
    metvar <- c("nbdsf", "nddsf", "vbdsf", "vddsf", "prate",
                "dlwrf", "pres", "hgt", "ugrd", "vgrd", "sh", "tmp",
                "co2")
    metvar_table <- data.frame(variable = metvar, update_frequency = dt,
                               flag = 1)
    if (!useCO2) {
      metvar_table_vars <- metvar_table[metvar_table$variable !=
                                          "co2", ]
    } else {
      metvar_table_vars <- metvar_table
    }

    ed_metheader <- list(list(path_prefix = met_folder,
                              nlon = length(lon), nlat = length(lat), dx = 0.5, dy = 0.5, xmin = min(lon),
                              ymin = min(lat), variables = metvar_table_vars))

    #check_ed_metheader(ed_metheader)
    write_ed_metheader(ed_metheader, met_header_file, header_line = shQuote("Made_by_PEcAn_met2model.ED2"))
  }
  print("Done with met2model.ED2")

  return(invisible(results))

}
