#!/bin/bash -l
#SBATCH -A snic2013-1-198
#SBATCH -p node -n 8
#SBATCH -t 2-00:00:00
#SBATCH -J feature_extract_1-32
#SBATCH --mail-type=ALL

# At Uppmax:

# SLURM settings:
# Replace snic2013-1-198 with your project name.
# Specify number of nodes or cores to use.
# Specify max time
# Specify job name
# Make sure you get notified by mail, when stuff happens.


# Save incoming images in $HOME/glob (250 GB quota).
# Create image links and temporary files at $SNIC_TMP,
# equal to path /scratch/$SLURM_JOB_ID .
# Make sure you create $HOME/glob/feature_extract/incoming/
# and $HOME/glob/feature_extract/output before running this script.

# Replace plate_start and plate_end with line numbers representing start and end
# for reading from txt_file. Replace txt_file with path to a text file
# containing a plate number on each line. The file will be read from plate_start
# to plate_end and the images from those plates or folders will be used as
# input.

# Each node, eight in this case, will have its own script running. Accomplish
# this by using "&" between script calls, as below.

# Remember to load modules first, to be able to call programs, like matlab.

module load matlab #Load module matlab

mkdir $SNIC_TMP/feature_extract/
cp $HOME/glob/feature_extract/feature_extract.zip $SNIC_TMP/feature_extract/
cd $SNIC_TMP/feature_extract/
unzip feature_extract.zip

./confocalanalyze_batch.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start plate_end txt_file &
./confocalanalyze_batch.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start plate_end txt_file &
./confocalanalyze_batch.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start plate_end txt_file &
./confocalanalyze_batch.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start plate_end txt_file &
./confocalanalyze_batch.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start plate_end txt_file &
./confocalanalyze_batch.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start plate_end txt_file &
./confocalanalyze_batch.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start plate_end txt_file &
./confocalanalyze_batch.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start plate_end txt_file &
wait
rm -rf $SNIC_TMP/feature_extract/
echo "Job finished successfully!"
