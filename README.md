# Step 1: Download and Compile ED2
logon to the cluster, for example via the web tool (https://login.hpc.ugent.be/)
Then firstly, load the required module to compile and run the model

  ml intel-compilers/2023.2.1 HDF5/1.14.3-iimpi-2023b UDUNITS/2.2.28-GCCcore-13.2.0
  ulimit -s unlimited

Then navigate to the VO directory of Q-ForestLab (if you do not have access please request it to Steven De Hertog)

  cd $VSC_DATA_VO

Make a personal repository and create an initial structure

  mkdir myname
  cd myname
  mkdir ED2.2
  cd ED2.2

# Clone the repository from GitHub
  git clone git@github.com:EDmodel/ED2.git
OR
  git clone https://github.com/EDmodel/ED2.git

# Build ED2
bash
Copy
Edit
cd ED2/ED/build/make
cp include.mk.intel include.mk.intel_hpc
