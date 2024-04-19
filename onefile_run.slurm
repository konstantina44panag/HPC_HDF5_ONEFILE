#!/bin/bash -l

####################################
#     SLURM Job Submission Script  #
#                                  #
# Submit script: sbatch submit_job.slurm #
#                                  #
####################################

#SBATCH --job-name=process_sas_file    # Job name
#SBATCH --nodes=1                      # Number of nodes requested
#SBATCH --ntasks=1                     # One task per node for GNU Parallel
#SBATCH --cpus-per-task=1              # Number of CPUs per task - align with node CPU count
#SBATCH --time=48:00:00                 # Walltime
#SBATCH --mem=3G                     # memory per NODE
#SBATCH --partition=compute           # Partition
#SBATCH --account=pa240201              # Replace with your system project


# Set up the environment
if [ -z "${SLURM_CPUS_PER_TASK+x}" ]; then
    export OMP_NUM_THREADS=1
else
    export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
fi

module purge
module load gnu/9
module load python/3.11.6
module load intel/18
module load intelmpi/2018
module load hdf5/1.12.1/gnu
module load cuda/10.1.168
module load ucx/1.9.0

export HDF5_DIR=/apps/libraries/hdf5/1.12.1/gnu
export PATH=$HDF5_DIR/bin:$PATH
export LD_LIBRARY_PATH=$HDF5_DIR/lib:$HDF5_DIR/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=$HDF5_DIR/lib:$HDF5_DIR/lib64:$LIBRARY_PATH
export C_INCLUDE_PATH=$HDF5_DIR/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=$HDF5_DIR/include:$CPLUS_INCLUDE_PATH
export MPI_DIR=/apps/compilers/intel/18.0.4/impi/2018.4.274


batch_file="/work/pa24/kpanag/scripts/corrected_run/one_file.txt"
process_row() {
    year=$1
    month=$2
    if [ -z "$year" ] || [ -z "$month" ]; then
        echo "Error: Year or month not provided" >&2  # Log to standard error
        return  # Exit the function
    fi
    if [ -z "$SLURM_JOB_ID" ]; then
        echo "Warning: SLURM_JOB_ID not set, using default" >&2
        SLURM_JOB_ID="default"
    fi
    out_file="/work/pa24/kpanag/out_err/${year}${month}_process_sas_file_${SLURM_JOB_ID}.out"
    err_file="/work/pa24/kpanag/out_err/${year}${month}_process_sas_file_${SLURM_JOB_ID}.err"
    bash /work/pa24/kpanag/scripts/corrected_run/csv_hdf.sh $year $month > $out_file 2> $err_file
}

export -f process_row

cat "$batch_file" | parallel -j $SLURM_CPUS_PER_TASK --colsep ' ' process_row {1} {2}
