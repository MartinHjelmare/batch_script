#!/bin/bash -l
#SBATCH -A snic2013-1-198
#SBATCH -p node -n 8
#SBATCH -t 2-00:00:00
#SBATCH -J feature_extract_1-32

# At Uppmax:
# Save incoming images in $HOME/glob (250 GB quota).
# Create image links and temporary files at $SNIC_TMP,
# equal to path /scratch/$SLURM_JOB_ID .
# Make sure you create $HOME/glob/feature_extract/incoming/
# and $HOME/glob/feature_extract/output before running this script.

module load matlab #Load module matlab

mkdir $SNIC_TMP/feature_extract/
cp $HOME/glob/feature_extract/confocal_feature.zip $SNIC_TMP/feature_extract/
cd $SNIC_TMP/feature_extract/
unzip feature_extract.zip

./confocalanalyze.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start well_start plate_end remote_host &
./confocalanalyze.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start well_start plate_end remote_host &
./confocalanalyze.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start well_start plate_end remote_host &
./confocalanalyze.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start well_start plate_end remote_host &
./confocalanalyze.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start well_start plate_end remote_host &
./confocalanalyze.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start well_start plate_end remote_host &
./confocalanalyze.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start well_start plate_end remote_host &
./confocalanalyze.sh 63 $HOME/glob/feature_extract/incoming/ \
$HOME/glob/feature_extract/output plate_start well_start plate_end remote_host &
wait
rm -rf $SNIC_TMP/feature_extract/
