This repository contains some scripts to process CRU-JRA files in .RDS format to ED compatible climate input formats. It is a reworked version of the code used for CRU meteo data generation from PeCAn.

The main script that are run on the cluster are job_climateRDS_flex.pbs and job_climateRDS_flex_tans.pbs. Both these files take command line inputs meaning that you have to run them as follows:
./job_climateRDS_flex.pbs $START_YEAR $END_YEAR $SITENAME $FLAG
Where $START_YEAR and $END_YEAR are the first and last year of the meteo data generated, $SITENAME is the name of the location which is used to find the correct RDS input file to be used and $FLAG indicates whether CO2 should be included or not. Note that in ED2 you can choose whether CO2 is part of the meteo driver or not, see also the ED2 wiki (https://github.com/EDmodel/ED2/wiki/Drivers).

You can also submit this script via several jobs to the cluster, an example for this is provided here (submit_all_RDS_conversion.pbs).


Both job_climateRDS_flex.pbs and job_climateRDS_flex_tans.pbs call R scripts, convert.RDS.input.ED2.flex.R and convert.RDS.input.ED2.flex.trans.R respectively, which are passed the same inputs as described above. these scripts operate similar to the PECAN scripts. For the use case these scripts where generated for we created climate drivers with constant co2 emissions (spinup) for which we used the first script (those that end with flex) while for the analysis period (1700-2020) we used transient co2 based on an input file (), these are the scripts that end in .trans

These scripts were tailored to a specific purpose so it might require considerable code development before they will fit your use case!

