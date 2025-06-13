# ANMI022_salmonella_micro_hmsc

HMSC modelling of micro-scale Salmonella experiment samples, using HMSC-HPC mode for GPU-based model fitting. Make sure that the latest version of HMSC is installed from Github, as the Bioconda and CRAN versions do not incorporate the code to generate GPU-compatible initialisation files.

## Preparations

GPU-based Hmsc requires a very specific setup to work correctly.

### 1. Create and activate conda environment

```
conda create -n hmsc-hpc python=3.11
conda activate hmsc-hpc
```

### 2. Install Hmsc-hpc

Get this specific version and install it from the local files using pip.

```
wget https://github.com/trossi/hmsc-hpc/archive/refs/heads/simplify-io-w-reduce-memory-consumption.zip
unzip simplify-io-w-reduce-memory-consumption.zip
pip install hmsc-hpc-simplify-io-w-reduce-memory-consumption/
```

### 3. Install tensorflow and related packages

```
pip install tensorflow[and-cuda]==2.16.2
pip install tensorflow-probability==0.24.0
pip install keras==2.15.0
pip install tf-keras~=2.16.0rc0
pip install git+https://github.com/vnmabus/rdata.git@develop
```

### 4. Install R and required libraries

```
conda install r-base r-devtools r-jsonify
```

### 5. Install latest version of HMSC

Get into R and install it directly from the Github repository.

```
R
library(devtools)
install_github("hmsc-r/HMSC")
```

## Usage

### 1. Create Hmsc model

Using regular Hmsc procedures.

### 2. Create init object

Initialise the model fitting to get the model ready for GPU computation

```
conda activate hmsc-hpc

model="hmsc/Unfitted_Hmsc_model_TH2.rds"
init="init/Unfitted_Hmsc_model_TH2.rds"

export samples=250
export thin=1000
export transient=$(( samples * thin ))
export nChains=4
export verbose=TRUE
export model
export init

# Get initiation object
Rscript hmsc.r $model $init
```

### 3. Create SLURM array for the model fitting

```
cat <<'EOF' > launch_hmsc.sh
#!/bin/bash
#SBATCH --job-name=hmsc_hpc
#SBATCH --nodes=1
#SBATCH --partition=cpuqueue
#SBATCH --qos=normal
#SBATCH --gres=gpu:1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32gb
#SBATCH --time=24:00:00
#SBATCH --array=0-3

# Activate conda environment
source activate hmsc-hpc

# Set output files
output=$(printf "output/Hmsc_model_TH2_chain_%.2d.rds" $SLURM_ARRAY_TASK_ID)
mkdir output

# Run model fit
srun python3 -m hmsc.run_gibbs_sampler --input $init --output $output --samples $samples --transient $transient --thin $thin --verbose 100 --chains $SLURM_ARRAY_TASK_ID
EOF
```

### 4. Submit SLURM job array

```
sbatch launch_hmsc.sh
```
