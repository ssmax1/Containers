# RStudio Containers

This repository contains **Singularity/Apptainer** recipes and automation scripts for reproducible R environments. These are specifically designed for High-Performance Computing (HPC) clusters using the SLURM workload manager.

---

## Overview

The goal of this project is to provide portable R and RStudio Server environments. 
* **Containers:** Defined by `.recipe` files and built into `.simg` or `.sif` images.
* **Automation:** A SLURM script is provided to handle port mapping, directory binding, and secure session launching.

---

## Repository Structure

```text
.
├── Containers/
│   ├── Rserver4.4.recipe      # Singularity/Apptainer build recipe
│   └── Rserver4.4.simg.log    # Build log for auditing
├── slurm_start_rstudio_4.4.sh # SLURM launch script for HPC nodes
└── README.md
```
## Building the Container
Building requires root privileges. If you are on an HPC, you may need to build this on a local Linux machine or a dedicated build node.

```text
sudo singularity build Rserver4.4.simg Rserver4.4.recipe 2>&1 | tee Rserver4.4.simg.log
```

## Launching on HPC (SLURM)
The provided slurm_start_rstudio_4.4.sh script automates the process of requesting resources and starting the RStudio Server.

1. Configure the Script
Before submitting, edit the following variables in slurm_start_rstudio_4.4.sh:

#SBATCH --mem=16G: Adjust memory as needed.

PASSWORD="your_password": Set your RStudio login password.

RSHOME="/path/to/user/rstudio_session_1": Set your persistent working directory.

2. Submit the Job
sbatch slurm_start_rstudio_4.4.sh

3. Connect to the Session
Once the job starts, check the output log (rslog-<jobID>.log). It will provide a custom SSH Tunnel command. Run that command on your local terminal:

Example of the generated command:
ssh -N -L 8788:localhost:8788 user@hpc-node-01.internal

Manual Execution (Alternative)
If you aren't using SLURM, you can run the image directly:

Interactive Shell:
singularity shell Rserver4.4.simg

Manual Rstudio Launch:
singularity exec --bind /path/to/home:/home/rstudio Rserver4.4.simg rserver --www-port=8788 --auth-none=0

## 📝 Important Notes
Port Collisions: The SLURM script includes a get_port function that automatically finds an available port if 8788 is in use.

Persistence: The script creates isolated directories for .local, .rstudio, and tmp to prevent session conflicts between different container versions.

Binding: Ensure any external data drives are correctly mapped in the singularity exec section of the script.

