#!/bin/bash

#SBATCH --account=phd
#SBATCH --mem=50G
#SBATCH --time=0-24:00:00
#SBATCH --job-name=exit_stats

# Load the module with the desired version of matlab
module load stata/17.0

# [optional] - load knitro if using the optimization package

# run matlab script named myscript.m
srun stata -b "firm_exit_stats_cluster.do"