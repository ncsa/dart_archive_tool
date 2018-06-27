#!/bin/bash

# user sets up variables here (unless they're parsed via command line)
NODES=1
ITERATIONS=3
STRIPE=8
RANK_DIVISOR=1 # =1 to fill all CPU threads with ranks, =2 for only half of them
BLOCK=4        # parfu block size in MB (if relevant)

# select the code we're testing here
#CODE="tar"
#CODE="tar_gz"
#CODE="tar_pigz"
#CODE="mpitar"
#CODE="ptar"
CODE="parfu"
#CODE="ptgz"

# select the system we're on.  
#SYSTEM="wrangler_lustre"
#SYSTEM="wrangler_gpfs"
#SYSTEM="comet"
#SYSTEM="stampede2"
SYSTEM="jyc_slurm"
#SYSTEM="jyc_moab"
#SYSTEM="bridges"

# pick the data set we're testing against
DATASET="GW"
#DATASET="Ar"
#DATASET="VC"

# find next non-existent run script name
COUNTER=0
SCRIPT_FILE_NAME=$(printf 'FPD_test_%s_%06d.bash' "$SYSTEM" "$COUNTER")
while [[ -e $SCRIPT_FILE_NAME ]]; do
    let COUNTER=COUNTER+1
    SCRIPT_FILE_NAME=$(printf 'FPD_test_%s_%06d.bash' "$SYSTEM" "$COUNTER")
done
echo "script file name=>${SCRIPT_FILE_NAME}<"
touch $SCRIPT_FILE_NAME

# populate intermediate variables according to what system we're on
case "$SYSTEM" in
    "wrangler_lustre")
	JOB_NAME="FPD_wr_LS"
	FS="lustre"
	MANAGER="slurm"
	RANKS_PER_NODE=24
	DATADIR=${DATA}
	;;
    "wrangler_hpfs")
	JOB_NAME="FPD_wr_HP"
	FS="hpfs"
	MANAGER="slurm"
	RANKS_PER_NODE=24
	;;
    "comet")
	JOB_NAME="FPD_comet"
	MANAGER="slurm"
	RANKS_PER_NODE=24
	FS="lustre"
	DATADIR=${SCRATCH}
	;;
    "stampede2")
	JOB_NAME="FPD_st2"
	RANKS_PER_NODE=64
	MANAGER="slurm"
	FS="lustre"
	QUEUE_NAME="normal"
	DATADIR='${SCRATCH}'
	MYMPIRUN_1="ibrun -n "
	MYMPIRUN_2=" -o 0"
	;;
    "jyc_slurm")
	JOB_NAME="FPD_jyc_SL"
	MANAGER="slurm"
	RANKS_PER_NODE=32
	FS="lustre"
	DATADIR="/scratch/staff/csteffen/FPD"
	MYMPIRUN_1="~jphillip/openmpi/bin/mpirun -n "
	MYMPIRUN_2=""
#	QUEUE_NAME="normal"
	;;
    "jyc_moab")
	JOB_NAME="FPD_jyc_Moab"
	RANKS_PER_NODE=32
	MANAGER="moab"
	FS="lustre"
	;;
    "bridges")
	JOB_NAME="FPD_Br"
	RANKS_PER_NODE=28   # don't actually know this one yet
	MANAGER="slurm"
	FS="lustre"
	;;	
esac

#####
# preliminary work is done; start writing to the target script

# start populating the target script 
# first the boilerplate bash definition
echo "#!/bin/bash" >> ${SCRIPT_FILE_NAME}
echo "" >> ${SCRIPT_FILE_NAME}

# write the job description lines in the target script
case "$MANAGER" in
    "slurm")
	echo "#SBATCH -J ${JOB_NAME}      # Job name" >> ${SCRIPT_FILE_NAME}
	echo "#SBATCH -o bnch.o%j         # Name of stdout output file" >> ${SCRIPT_FILE_NAME}
	echo "#SBATCH -e bnch.e%j         # Name of stderr error file" >> ${SCRIPT_FILE_NAME}
	if [ $QUEUE_NAME ]; then
	    echo "#SBATCH -p ${QUEUE_NAME}    # Queue (partition) name" >> ${SCRIPT_FILE_NAME}
	fi
	echo "#SBATCH -N ${NODES}         # number of nodes" >> ${SCRIPT_FILE_NAME}
	echo "#SBATCH --tasks-per-node=${RANKS_PER_NODE}     #rank slots per node" >> ${SCRIPT_FILE_NAME}
	echo "#SBATCH -t 12:00:00           # Run time (hh:mm:ss)" >> ${SCRIPT_FILE_NAME}
	echo "#SBATCH --mail-user=craigsteffen@gmail.com" >> ${SCRIPT_FILE_NAME}
	echo "#SBATCH --mail-type=all      # Send email at begin and end of job" >> ${SCRIPT_FILE_NAME}
	;;
    "Moab")	
esac
echo "" >> ${SCRIPT_FILE_NAME}

# variables used for configuration
# RANKS
# BASEDIR
# STRIPE
# JOB_ID_VARIABLE
RANKS=$(( (NODES*RANKS_PER_NODE)/RANK_DIVISOR ))
EXPANDED_RANKS=$(printf '%04d' "$RANKS")
echo 'RANKS="'$EXPANDED_RANKS'"' >> ${SCRIPT_FILE_NAME}
JOB_ID_NAME='${SLURM_JOBID}'
echo "BASEDIR="$DATADIR >> ${SCRIPT_FILE_NAME}
EXPANDED_STRIPE=$(printf '%04d' "$STRIPE")
echo 'STRIPE="'$EXPANDED_STRIPE'"' >> ${SCRIPT_FILE_NAME}
echo 'DATASET="'${DATASET}'"' >> ${SCRIPT_FILE_NAME}
echo 'CODE="'${CODE}'"' >> ${SCRIPT_FILE_NAME}
EXPANDED_BLOCK=$(printf '%04d' "$BLOCK")
echo 'BLOCK="'$EXPANDED_BLOCK'"' >> ${SCRIPT_FILE_NAME}
echo 'MACH_FS="'$FS'"' >> ${SCRIPT_FILE_NAME}
echo "" >> ${SCRIPT_FILE_NAME}

# set up the data file lines in the target script
DATA_FILE_NAME=$(printf 'FPD_test_%s_data_%06d.dat' "$SYSTEM" "$COUNTER")

echo "TIMING_DATA_FILE=\"${DATA_FILE_NAME}\"" >> ${SCRIPT_FILE_NAME}
echo "" >> ${SCRIPT_FILE_NAME}
echo $'echo \"starting production running\"' >> ${SCRIPT_FILE_NAME}
echo $'echo \'${CODE} ${BLOCK}    ${MACH_FS}  ${DATASET}    ${STRIPE}    ${NODES} ${RANKS}    ${ITER} ${ELAP}\' >> ${TIMING_DATA_FILE}' >> ${SCRIPT_FILE_NAME} # 

#' (this line is to get the emacs bash parser to play ball.  It does nothing)

echo "" >> ${SCRIPT_FILE_NAME}

echo "ITER=0" >> ${SCRIPT_FILE_NAME}
echo "NUM_ITERATIONS="$ITERATIONS >> ${SCRIPT_FILE_NAME}
#echo 'echo "comparison: >$CODE< >tar<"' >> ${SCRIPT_FILE_NAME}
echo 'if [ "${CODE}" == "tar" ]; then' >> ${SCRIPT_FILE_NAME}
echo '   let RANKS="0001"' >> ${SCRIPT_FILE_NAME}
echo 'fi' >> ${SCRIPT_FILE_NAME}
echo "" >> ${SCRIPT_FILE_NAME}

# check for directories
echo 'mkdir -p output_files' >> ${SCRIPT_FILE_NAME}
echo "" >> ${SCRIPT_FILE_NAME}


# now the data-taking while loop
echo 'while [ $ITER -lt $NUM_ITERATIONS ]; do ' >> ${SCRIPT_FILE_NAME}
echo '    echo "starting iteration $ITER ranks $RANKS"' >> ${SCRIPT_FILE_NAME}
echo '    START=`date +%s`' >> ${SCRIPT_FILE_NAME}
case ${CODE} in
    "parfu")
#	echo '    ibrun -n ${RANKS} -o 0 parfu C $BASEDIR/arc_${STRIPE}/prod_'${JOB_ID_NAME}'_${ITER}.pfu $BASEDIR/${DATASET}_data/ &> output_files/out_'${JOB_ID_NAME}'_${ITER}.out 2>&1' >> ${SCRIPT_FILE_NAME}
	echo '    '$MYMPIRUN_1'${RANKS}'$MYMPIRUN_2' parfu C $BASEDIR/arc_${STRIPE}/prod_'${JOB_ID_NAME}'_${ITER}.pfu $BASEDIR/${DATASET}_data/ &> output_files/out_'${JOB_ID_NAME}'_${ITER}.out 2>&1' >> ${SCRIPT_FILE_NAME}
	;;
    "tar")
#	echo '    ibrun -n 1 -o 0 tar czf $BASEDIR/arc_${STRIPE}/prod_'${JOB_ID_NAME}'_${ITER}.tgz $BASEDIR/${DATASET}_data/ > output_files/out_'${JOB_ID_NAME}'_${ITER}.out 2>&1' >> ${SCRIPT_FILE_NAME}
	echo '    '$MYMPIRUN_1'${RANKS}'$MYMPIRUN_2' tar czf $BASEDIR/arc_${STRIPE}/prod_'${JOB_ID_NAME}'_${ITER}.tgz $BASEDIR/${DATASET}_data/ > output_files/out_'${JOB_ID_NAME}'_${ITER}.out 2>&1' >> ${SCRIPT_FILE_NAME}
esac
echo '    END=`date +%s`' >> ${SCRIPT_FILE_NAME}
echo '    ELAP=$(expr $END - $START)' >> ${SCRIPT_FILE_NAME}
echo '    echo "${CODE} ${BLOCK}    ${MACH_FS}  ${DATASET}    ${STRIPE}    ${NODES} ${RANKS}    ${ITER} ${ELAP}" >> ${TIMING_DATA_FILE}' >> ${SCRIPT_FILE_NAME}
echo '    let ITER=ITER+1' >> ${SCRIPT_FILE_NAME}
echo 'done' >> ${SCRIPT_FILE_NAME}
echo "" >> ${SCRIPT_FILE_NAME}


# now we set up the loop computation in the target script