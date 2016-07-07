#!/bin/bash 

echo "This script must be SOURCED to correctly setup the environment prior to running any of the other HCP scripts contained here"

# Set up FSL (if not already done so in the running environment)
# Uncomment the following 2 lines (remove the leading #) and correct the FSLDIR setting for your setup
#export FSLDIR=/usr/share/fsl/5.0
#. ${FSLDIR}/etc/fslconf/fsl.sh

# Let FreeSurfer know what version of FSL to use
# FreeSurfer uses FSL_DIR instead of FSLDIR to determine the FSL version
export FSL_DIR="${FSLDIR}"

# Set up FreeSurfer (if not already done so in the running environment)
# Uncomment the following 2 lines (remove the leading #) and correct the FREESURFER_HOME setting for your setup
#export FREESURFER_HOME=/usr/local/bin/freesurfer
#. ${FREESURFER_HOME}/SetUpFreeSurfer.sh > /dev/null 2>&1

# Set up specific environment variables for the HCP Pipeline

### CfN modified

#export HCPPIPEDIR=${HOME}/projects/Pipelines
export HCPPIPEDIR=/data/jet/grosspeople/HCP/hcpPipeline/Pipelines-3.4.0/
#export CARET7DIR=${HOME}/workbench/bin_linux64
export CARET7DIR=${CFNAPPS}/workbench/workbench-1.0/bin_rh_linux64/

export FSLDIR=$CFNAPPS/fsl/5.0.6
if [ -d "$FSLDIR" ]; then
  source ${FSLDIR}/etc/fslconf/fsl.sh
else
  echo " ERROR: Can't find FSL at $FSLDIR "
fi
PATH=${FSLDIR}/bin:${PATH}

# Freesurfer uses its own FSL_DIR variable?!
export FSL_DIR=$FSLDIR

## Freesurfer
#export FREESURFER_HOME=$CFNAPPS/freesurfer/5.3.0
#Use 5.3.0-HCP for use with HCP Pipelines 3.4.0
export FREESURFER_HOME=$CFNAPPS/freesurfer/5.3.0-HCP

if [ -f "$FREESURFER_HOME/SetUpFreeSurfer.sh" ]; then
  source $FREESURFER_HOME/SetUpFreeSurfer.sh
else
  echo " ERROR: Can't find FreeSurfer at $FREESURFER_HOME "
fi

# python
# version required for HCP pipelines. Installed in parallel with system's version 2.6.6
export PyPATH=$CFNAPPS/python/Python-2.7.9/bin/
# Put this BEFORE /usr/bin so we don't get the system python.
PATH=$PyPATH:$PATH


# Run custom script to check env settings for fsl, freesurfer and python
${HCPPIPEDIR}/VerifyHCPpipelinesEnvironment.sh

### end CfN modified

export HCPPIPEDIR=/data/jet/grosspeople/HCP/CurrentPipeline/Pipelines
export CARET7DIR=${CFNAPPS}/workbench/workbench-1.0/bin_rh_linux64/

export HCPPIPEDIR_Templates=${HCPPIPEDIR}/global/templates
export HCPPIPEDIR_Bin=${HCPPIPEDIR}/global/binaries
export HCPPIPEDIR_Config=${HCPPIPEDIR}/global/config

export HCPPIPEDIR_PreFS=${HCPPIPEDIR}/PreFreeSurfer/scripts
export HCPPIPEDIR_FS=${HCPPIPEDIR}/FreeSurfer/scripts
export HCPPIPEDIR_PostFS=${HCPPIPEDIR}/PostFreeSurfer/scripts
export HCPPIPEDIR_fMRISurf=${HCPPIPEDIR}/fMRISurface/scripts
export HCPPIPEDIR_fMRIVol=${HCPPIPEDIR}/fMRIVolume/scripts
export HCPPIPEDIR_tfMRI=${HCPPIPEDIR}/tfMRI/scripts
export HCPPIPEDIR_dMRI=${HCPPIPEDIR}/DiffusionPreprocessing/scripts
export HCPPIPEDIR_dMRITract=${HCPPIPEDIR}/DiffusionTractography/scripts
export HCPPIPEDIR_Global=${HCPPIPEDIR}/global/scripts
export HCPPIPEDIR_tfMRIAnalysis=${HCPPIPEDIR}/TaskfMRIAnalysis/scripts
export MSMBin=${HCPPIPEDIR}/MSMBinaries

