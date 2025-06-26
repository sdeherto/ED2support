# Step 1: Download and Compile ED2

Log on to the cluster, for example via the web tool:  
[https://login.hpc.ugent.be/](https://login.hpc.ugent.be/)

### Load Required Modules

```bash
ml intel-compilers/2023.2.1 HDF5/1.14.3-iimpi-2023b UDUNITS/2.2.28-GCCcore-13.2.0
ulimit -s unlimited
```

Then navigate to the VO directory of Q-ForestLab (if you do not have access please request it to Steven De Hertog)
```bash
cd $VSC_DATA_VO
```
Make a personal repository and create an initial structure
```bash
mkdir myname
cd myname
mkdir ED2.2
cd ED2.2
```
# Clone the ED2 and ED2support repositories from GitHub
```bash
git clone https://github.com/EDmodel/ED2.git
git clone https://github.com/sdeherto/ED2support.git
```
# Build ED2
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

Then compile the model:
```bash
cd ..
./install.sh -k E -p intel_hpc
```
For more information on the compilation script we refer to the ED2 wiki (https://github.com/EDmodel/ED2/wiki/Quick-start and https://github.com/EDmodel/ED2/wiki/Compiler-instructions-%28aka-the-include.mk-files%29)

### Prepare a simple test run

Next we can run teh model for a short test case. 
First we have to get some climate drivers for the model, these have been downloaded from GitHub before and should be available under $VSC_DATA_VO/myname/ED2support/outputs/drivers
Now all that is left to do is adapt the ED2IN file to point to these climate drivers, this file controls all model settings and can be found $PATH
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

and lines 376-377

```bash
   NL%FFILOUT = '/data/gent/vo/000/gvo00074/myname/outputs/test_ED/analysis/analysis'
   NL%SFILOUT = '/data/gent/vo/000/gvo00074/myname/outputs/test_ED/history/history'
```

More information on the contents of the ED2IN file are decribed on the ED2 wiki (https://github.com/EDmodel/ED2/wiki/ED2IN-namelist), note that the first change points to the provided climate drivers (CRU data from 1901 and 1902) and the two other lines point to the locations where the output files will be written. Important, you as a model user need to manually create those directories so we create them:
```bash
  mkdir /data/gent/vo/000/gvo00074/myname/ED2support/outputs/test_ED
  mkdir /data/gent/vo/000/gvo00074/myname/ED2support/outputs/test_ED/analysis
  mkdir /data/gent/vo/000/gvo00074/myname/ED2support/outputs/test_ED/history
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


