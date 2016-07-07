#!/bin/bash 

get_batch_options() {
    local arguments=($@)

    unset command_line_specified_study_folder
    unset command_line_specified_subj_list
    unset command_line_specified_run_local

    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --StudyFolder=*)
                command_line_specified_study_folder=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --Subjlist=*)
                command_line_specified_subj_list=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --runlocal)
                command_line_specified_run_local="TRUE"
                index=$(( index + 1 ))
                ;;
	    *)
		echo ""
		echo "ERROR: Unrecognized Option: ${argument}"
		echo ""
		exit 1
		;;
        esac
    done
}

get_batch_options $@

StudyFolder="${HOME}/projects/Pipelines_ExampleData" #Location of Subject folders (named by subjectID)
Subjlist="100307" #Space delimited list of subject IDs
EnvironmentScript="${HCPPIPEDIR}/Examples/Scripts/SetUpHCPPipeline.sh" #Pipeline environment script

# Usage text. Require a command line input or print usage and exit
USAGE="

  $0 --StudyFolder=/path/to/data --Subjlist=\"subject1 subject2\" --runlocal

  This script is for running Lifespan data from Penn's Prisma

  --StudyFolder : path to data directory. Subject data lives inside here in /path/to/data/subjectID/ directories

  --Subjlist : List of subjects, separated by spaces

  --runlocal : You should probably qsub a script that calls this script with --runlocal. Otherwise FSL's qsub gets called, which might not work

"

if [ -n "${command_line_specified_study_folder}" ]; then
    StudyFolder="${command_line_specified_study_folder}"
else
  echo "$USAGE"
  exit 1
fi

if [ -n "${command_line_specified_subj_list}" ]; then
    Subjlist="${command_line_specified_subj_list}"
else
  echo "$USAGE"
  exit 1
fi

# Requirements for this script
#  installed versions of: FSL (version 5.0.6), FreeSurfer (version 5.3.0-HCP) , gradunwarp (HCP version 1.0.2)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#Set up pipeline environment variables and software
. ${EnvironmentScript}

# Log the originating call
echo "$@"

#Assume that submission nodes have OPENMP enabled (needed for eddy - at least 8 cores suggested for HCP data)
#if [ X$SGE_ROOT != X ] ; then
#    QUEUE="-q verylong.q"
#    QUEUE="-q hcp_priority.q"
#fi

PRINTCOM=""


########################################## INPUTS ########################################## 

#Scripts called by this script do assume they run on the outputs of the PreFreeSurfer Pipeline,
#which is a prerequisite for this pipeline

#Scripts called by this script do NOT assume anything about the form of the input names or paths.
#This batch script assumes the HCP raw data naming convention, e.g.

#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_dMRI_dir98_AP.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_dMRI_dir99_AP.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_dMRI_dir97_AP.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_dMRI_dir98_PA.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_dMRI_dir99_PA.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/Diffusion/${SubjectID}_3T_dMRI_dir97_PA.nii.gz

#Change Scan Settings: Echo Spacing and PEDir to match your images
#These are set to match the HCP Protocol by default

#If using gradient distortion correction, use the coefficents from your scanner
#The HCP gradient distortion coefficents are only available through Siemens
#Gradient distortion in standard scanners like the Trio is much less than for the HCP Skyra.

######################################### DO WORK ##########################################

for Subject in $Subjlist ; do
  echo $Subject

  #Input Variables
  SubjectID="$Subject" #Subject ID Name
  RawDataDir="$StudyFolder/$SubjectID/unprocessed/3T/Diffusion" #Folder where unprocessed diffusion data are

  # Data with positive Phase encoding direction. Up to N>=1 series (here N=3), separated by @. (AP in HCP data, AP in 7T HCP data)
  PosData="${RawDataDir}/${SubjectID}_3T_dMRI_dir98_AP.nii.gz@${RawDataDir}/${SubjectID}_3T_dMRI_dir99_AP.nii.gz"

  # Data with negative Phase encoding direction. Up to N>=1 series (here N=3), separated by @. (PA in HCP data, PA in 7T HCP data)
  # If corresponding series is missing (e.g. 2 AP series and 1 PA) use EMPTY.
  NegData="${RawDataDir}/${SubjectID}_3T_dMRI_dir98_PA.nii.gz@${RawDataDir}/${SubjectID}_3T_dMRI_dir99_PA.nii.gz"

  #Scan Settings
  # JSP: Set this to NONE? If we're using topup, shouldn't be necessary.

  EchoSpacing=0.78 #Echo Spacing or Dwelltime of dMRI image, set to NONE if not used. Dwelltime = 1/(BandwidthPerPixelPhaseEncode * # of phase encoding samples): DICOM field (0019,1028) = BandwidthPerPixelPhaseEncode, DICOM field (0051,100b) AcquisitionMatrixText first value (# of phase encoding samples).  On Siemens, iPAT/GRAPPA factors have already been accounted for.
  PEdir=2 #Use 1 for Left-Right Phase Encoding, 2 for Anterior-Posterior

  #Config Settings
   Gdcoeffs="${HCPPIPEDIR_Config}/coeff.grad" #Coefficients that describe spatial variations of the scanner gradients. Use NONE if not available.
  #Gdcoeffs="NONE" # Set to NONE to skip gradient distortion correction

  if [ -n "${command_line_specified_run_local}" ] ; then
      echo "About to run ${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh"
      queuing_command=""
  else
      echo "About to use fsl_sub to queue or run ${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh"
      queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
  fi

  ${queuing_command} ${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh \
      --posData="${PosData}" --negData="${NegData}" \
      --path="${StudyFolder}" --subject="${SubjectID}" \
      --echospacing="${EchoSpacing}" --PEdir=${PEdir} \
      --gdcoeffs="${Gdcoeffs}" \
      --printcom=$PRINTCOM

done

