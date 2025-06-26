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
# Clone the repository from GitHub
```bash
 git clone git@github.com:EDmodel/ED2.git
# OR
git clone https://github.com/EDmodel/ED2.git
```
# Build ED2
```bash
cd ED2/ED/build/make
cp include.mk.intel include.mk.intel_hpc
```
Edit include.mk.intel_hpc:
Change lines XX-XX
HDF5_INCS=-I/apps/gent/RHEL9/skylake-ib/software/HDF5/1.14.3-iimpi-2023b/include
HDF5_LIBS=-lm -lz -L/apps/gent/RHEL9/skylake-ib/software/HDF5/1.14.3-iimpi-2023b/bin -lhdf5 -lhdf5_fortran -lhdf5_hl

Then compile the model:
```bash
cd ..
./install.sh -k E -p intel_hpc
```
