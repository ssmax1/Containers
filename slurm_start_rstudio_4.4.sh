#!/bin/bash
# To give your job a name, replace "MyJob" with an appropriate name
#SBATCH --job-name=rstudio

# Request CPU resource for a serial job
#SBATCH --ntasks=1
# SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
# Select node if specific node is needed
# SBATCH --nodelist=hpc-1

# Memory usage (MB)
#SBATCH --mem=16G

# Set your minimum acceptable walltime, format: day-hours:minutes:seconds
#SBATCH --time=1-0:00:00
# SBATCH --qos=irq

# Set the file for output (stdout)
#SBATCH --output="rslog-%j.log"

# Set the file for error log (stderr)
#SBATCH --error="rslog-%j.log"

# select partition
# SBATCH --partition=compute

# Commands to run
######################################################################################

USER=${USER:-$(whoami)}

echo ${USER}
echo ${HOME}

# image for singularity built based on https://www.rocker-project.org/use/singularity/

IMAGE=Rserver4.4.simg

PORT=${RSTUDIO_PORT:-8788}



################################ make or choose password for RStudio
#export PASSWORD=$(openssl rand -base64 15)
#echo "Enter new password for Rstudio"; read -s pword; export PASSWORD=$pword
export PASSWORD="your_password"
################################

HPC_ENV="local"

function get_port {
    
    until ! netstat -ln | grep "  LISTEN  " | grep -iEo  ":[0-9]+" | cut -d: -f2 | grep -wqc ${PORT};
    do
        ((PORT++))
        echo "Checking port: ${PORT}"
    done
    echo "Got one !"
}




RSHOME="/path/to/user/rstudio_session_1" # <- Change R dir "rstudio_session_2" to make isolated rsever sessions 
IMAGE_NAME=$(basename $IMAGE | sed 's#.simg\|.sif##' )
RSTUDIO_HOME=${RSHOME}/${IMAGE_NAME}/session
RSTUDIO_TMP=${RSHOME}/${IMAGE_NAME}/tmp
RSTUDIO_LOCAL=${RSHOME}/${IMAGE_NAME}/.local
R_LIBS_USER=${RSHOME}/${IMAGE_NAME}

if [ ! -e ${RSTUDIO_TMP}/var/run ] ; then
mkdir -p $RSHOME/singularity_cache
mkdir -p $RSHOME/rstudio
mkdir -p ${RSTUDIO_HOME}
mkdir -p ${R_LIBS_USER}
mkdir -p ${RSTUDIO_LOCAL}
mkdir -p ${RSTUDIO_TMP}/var/run
fi

# Use a shared cache location if unspecified
export SINGULARITY_CACHEDIR=${SINGULARITY_CACHEDIR:-"$RSHOME/singularity_cache"}
export SINGULARITYENV_RSTUDIO_SESSION_TIMEOUT=0

echo
echo "Finding an available port ..."
get_port

LOCALPORT=${PORT}
PUBLIC_IP=$(curl https://checkip.amazonaws.com)

echo "On you local machine, open an SSH tunnel like:"
# echo "  ssh -N -L ${LOCALPORT}:localhost:${PORT} ${USER}@hostname.edu.au"
echo "  ssh -N -L ${LOCALPORT}:localhost:${PORT} ${USER}@$(hostname -f)"
echo "  or"
echo "  ssh -N -L ${LOCALPORT}:localhost:${PORT} ${USER}@${PUBLIC_IP}"
echo "	ssh -N -J ${USER}@host.internal -L ${PORT}:localhost:${PORT} ${USER}@$(hostname -f)"
echo "	$(hostname -f)host.internal:${PORT} "
echo "	$(hostname -f)host.internal:${PORT} " > /home/$USER/rstudio.job.port
echo
echo "Point your web browser at http://localhost:${LOCALPORT}"
echo
echo "Login to RStudio with:"
echo "  username: ${USER}"
#echo "  password: ${PASSWORD}"
echo
echo "Starting RStudio Server (R version from image ${IMAGE} )"

# Set some locales to suppress warnings
LC_CTYPE="C"
LC_TIME="C"
LC_MONETARY="C"
LC_PAPER="C"
LC_MEASUREMENT="C"

SINGULARITYENV_PASSWORD="${PASSWORD}" \
singularity exec    --bind ${RSHOME}:/home/rstudio \
                    --bind ${RSTUDIO_HOME}:${HOME}/.rstudio \
                    --bind ${RSTUDIO_LOCAL}:${HOME}/.local \
                    --bind ${R_LIBS_USER}:${R_LIBS_USER} \
                    --bind ${RSTUDIO_TMP}:/tmp \
                    --bind ${RSTUDIO_TMP}/var:/var/lib/rstudio-server \
                    --bind ${RSTUDIO_TMP}/var/run:/var/run/rstudio-server \
                    --bind /labs/epigenetics:/labs/epigenetics \
                    --writable-tmpfs \
                    --env R_LIBS_USER=${R_LIBS_USER} \
                    ${IMAGE} \
                    rserver --server-user $USER --auth-none=0 --auth-pam-helper-path=pam-helper --www-port=${PORT} --auth-timeout-minutes=0
printf 'rserver exited' 1>&2
