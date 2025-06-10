
cat <<EOF > launch_hmsc.sh
#!/bin/bash
#SBATCH --job-name=hmsc-hpc
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
conda activate hmsc-hpc

# Set input and output files
model="hmsc/Unfitted_Hmsc_model_TH2.rds"
init="init/Unfitted_Hmsc_model_TH2.rds"
output=$(printf "output/Hmsc_model_TH2_chain%.2d.rds" $SLURM_ARRAY_TASK_ID)

# Set parameters
export samples=250
export thin=1000
export transient=$(( samples * thin ))
export nChains=4
export verbose=TRUE

# Get initiation object
Rscript hmsc.r $model $init

# Run model fit
srun python3 -m hmsc.run_gibbs_sampler --input $init --output $output --samples $samples --transient $transient --thin $thin --verbose 100 --chain $SLURM_ARRAY_TASK_ID
EOF

sbatch launch_hmsc.sh
