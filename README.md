# Containers

This repository contains Singularity/Apptainer container recipes and build logs for reproducible R environments, including an RStudio Server image.

Overview

The goal of this project is to provide portable, reproducible containers for R and RStudio Server that can be deployed on HPC systems or local machines. Each container is defined by a .recipe file and built into a .sif/.simg image.

Repository Structure

Containers/
├── Rserver4.4.recipe        # Singularity/Apptainer build recipe
├── Rserver4.4.simg.log      # Build log (optional)
└── README.md

Building the Container

You can build the RStudio Server container using Singularity or Apptainer. This requires root privileges (or an unprivileged build environment configured by your HPC admins).

Build Command

sudo singularity build Rserver4.4.simg Rserver4.4.recipe 2>&1 | tee Rserver4.4.simg.log

This will:

Compile the container from the recipe

Output the build log to Rserver4.4.simg.log

Produce the final image Rserver4.4.simg

If using Apptainer, the command is identical:

sudo apptainer build Rserver4.4.sif Rserver4.4.recipe

Using the Container

Once built, you can run the image directly:

singularity exec Rserver4.4.simg R --version

Or start an interactive shell:

singularity shell Rserver4.4.simg

Running RStudio Server (Example)

If you want to run RStudio Server inside the container, bind the necessary directories and launch rserver:

singularity exec 
    --bind /path/to/home:/home/rstudio 
    --bind /path/to/tmp:/tmp 
    Rserver4.4.simg 
    rserver --www-port=8788 --auth-none=0

Then open your browser at:

http://localhost:8788

(You may need an SSH tunnel if running on a remote HPC node.)

Notes

You may need to adjust bind paths depending on your HPC environment.

If your cluster uses Apptainer instead of Singularity, commands are interchangeable.

For multi-user environments, ensure you configure authentication appropriately.
