# Step 1: Download and Compile ED2

Log on to the cluster, for example via the web tool:  
[https://login.hpc.ugent.be/](https://login.hpc.ugent.be/)

### Load Required Modules

```bash
ml intel-compilers/2023.2.1 HDF5/1.14.3-iimpi-2023b UDUNITS/2.2.28-GCCcore-13.2.0 ulimit -s unlimited
```

Then navigate to the VO directory of Q-ForestLab (if you do not have access please request it to steven.dehertog@ugent.be)
```bash
cd $VSC_DATA_VO
```
Make a personal repository and create an initial directory structure, note that 'myname' below should be replaced by your name ;)
```bash
mkdir myname
cd myname
mkdir ED2.2
cd ED2.2
```
# Step 2: Clone the ED2 and ED2support repositories from GitHub
```bash
git clone https://github.com/EDmodel/ED2.git
git clone https://github.com/sdeherto/ED2support.git
```
# Step 3: Build and compile ED2
```bash
cd ED2/ED/build/make
cp include.mk.intel include.mk.intel_hpc
```
Edit include.mk.intel_hpc,
Change lines 28-29 with the following:
```bash
HDF5_INCS=-I/apps/gent/RHEL9/skylake-ib/software/HDF5/1.14.3-iimpi-2023b/include
HDF5_LIBS=-lm -lz -L/apps/gent/RHEL9/skylake-ib/software/HDF5/1.14.3-iimpi-2023b/bin -lhdf5 -lhdf5_fortran -lhdf5_hl
```

Then compile the model by running the install script:
```bash
cd ..
./install.sh -k E -p intel_hpc
```
This might take a while, so get a coffee or take a break, once the message 'build complete' is shown you can continue with the next steps. For more information on the compilation script we refer to the ED2 wiki (https://github.com/EDmodel/ED2/wiki/Quick-start and https://github.com/EDmodel/ED2/wiki/Compiler-instructions-%28aka-the-include.mk-files%29)

# Step 4: Prepare a simple test run

Next we can run the model for a short test case. 
First we have to get some climate drivers for the model, these have been downloaded from GitHub before and should be available under $VSC_DATA_VO/myname/ED2support/outputs/drivers
Now all that is left to do is adapt the ED2IN file to point to these climate drivers, this file controls all model settings, there is annotations in the file but additional info on parameter meanings can be found here (https://github.com/EDmodel/ED2/wiki/ED2IN-namelist). The ED2IN file we will use can be found here /data/gent/vo/000/gvo00074/myname/ED2support/files
First navigate to its location make a local copy for adapting, then open the file with vi.
```bash
cd /data/gent/vo/000/gvo00074/myname/ED2support/files
cp ED2IN_def_Yangambi ED2IN_test
vi ED2IN_test
```
Then Adapt the following lines in the ED2IN_test file on line 630:
```bash
   NL%ED_MET_DRIVER_DB  = '/data/gent/vo/000/gvo00074/myname/outputs/drivers/ED_MET_DRIVER_HEADER'
```

and in lines 376-377 change the following (again pay attention to write your name!)

```bash
   NL%FFILOUT = '/data/gent/vo/000/gvo00074/myname/outputs/test_ED/analysis/analysis'
   NL%SFILOUT = '/data/gent/vo/000/gvo00074/myname/outputs/test_ED/history/history'
```

More information on the contents of the ED2IN file are decribed on the ED2 wiki (https://github.com/EDmodel/ED2/wiki/ED2IN-namelist), note that the first change points to the provided climate drivers (CRU data from 1901 and 1902) and the two other changed lines point to the locations where the output files will be written. Important, you as a model user need to manually create those directories so we create them:
```bash
  mkdir /data/gent/vo/000/gvo00074/myname/ED2support/outputs/test_ED
  mkdir /data/gent/vo/000/gvo00074/myname/ED2support/outputs/test_ED/analysis
  mkdir /data/gent/vo/000/gvo00074/myname/ED2support/outputs/test_ED/history
```

Copy the ED2IN file over to the run directory of ED2
```bash
cp  /data/gent/vo/000/gvo00074/myname/ED2support/files/ED2IN_test /data/gent/vo/000/gvo00074/myname/ED2.2/ED2/ED/run/ED2IN_test
```

Finally, we can run the model, to do this navigate to the following directory

```bash
cd /data/gent/vo/000/gvo00074/myname/ED2support/files
```

To run the model we use the job.pbs script, which runs the command to launch a simulation with a given ED2IN file, this job script has been set up so it already points to the ED2IN file we adpated before. The only modifications you ahve to make is change the paths so it points to the appropriate directories. You can choose to submit the job to the queue:
```bash
qsub job.pbs
```
Or run it within an interecative job to monitor its progression (preferred option when it is the first run):
```bash
qsub -I 
./job.pbs
```
Note that you may need to change the properties of the file job.pbs to make it executable (simply run 'chmod u+x job.pbs' in the terminal)

# Step 5: Create easy to use outputs

By default ED2 writes its output to hdf5 files, these can be explored and visualised by the rhdf package. However to make this output exploration step a bit more convenient several postprocessing scripts have been developed.
Here we will discuss two options, 1. based on the postprocessing script included in the ED2 installation under (R-utils) and 2. based on a home made script to convert the hdf files to netcdf timeseries files per variable (still requires some development).

We will start with the ED2 functions under the R-utils, to use these we first need to make some adaptations, first and foremost load the required R modules
```bash
ml purge; ml R-bundle-Bioconductor/3.18-foss-2023a-R-4.3.2
```
Then ensure that all R packages required to run the script are installed, you can use the install_packages.R script for thsi which can be found under ED2support/R
```bash
Rscript install_packages.R
```
The next step is to update some of the scripts in the R-utils directory, navigate to the ED2support/files/R-utils directory and copy these files over to the R-utils directory in your ED2 installation, these should replace some of the original files with the updated versions.

then run the postprocessing script, first open the file and make sure that the paths in the script point to your local directories
```bash
Rscript post.process.ED2.outputs.R
```
this will take some time and will generate two useful things, both will be added in your ED2 output directory
1. a whole slate of diagnostic plots that you can browse through, excellent for explorative analysis
2. an Rdata file that compiles your output in an easy to use format

Additionally some files within the R subdirectory (convert_Rdata_to_nc.sh and R scripts called therein) provide some code to convert from an RData file to timeseries files per variables in netcdf format (mimicking TRENDY output).

# create new meteo input
For general info on the contents of ED2 met drivers please consult the wiki (https://github.com/EDmodel/ED2/wiki/Drivers). Here we provide some script for generating these at the UGent cluster. There exist multiple scripts for different types of atmospheric forcings, we will illustrate two here:
- Scripts to convert CRU data based on Pecan (download.and.convert.input.ED2.R available in R subdirectory)
- Scripts to convert any generic climate data given that it is provided in a simple csv format (available in subfolder R/climate, check the README there for more info)

# special cases: implement land use
Some example scripts are available on the VO (/data/gent/vo/000/gvo00074/land_use/regrowth) in general we recommend that you check the ED2 wiki for any information regarding this (https://github.com/EDmodel/ED2/wiki/Initial-conditions). You are just required to generate a .lu file and point to this file in the ED2IN file.

# special cases: use ED-hydro
Simply change the following in your ED2IN
```bash
H2O_PLANT_LIM<-3
PLANT_HYDRO_SCHEME<-1
```
# how to set up multiple simulations and manipulate ED2IN in scripted way
Some example scripts to do this are provided under files/submit_batch there is a readme available with some brief description on how to use these scripts. They are heavily based on the original scripts developed by Félicien Meunier which are provided here https://github.com/femeunier/ED2scenarios





