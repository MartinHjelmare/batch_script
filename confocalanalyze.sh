#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#rsync -rav --include '*/' --include='1054_G12_1*.tif.gz' --exclude='*' \
#/home/martin/Skrivbord/feature_extract_test/1054/ /home/martin/Skrivbord/feature_extract/incoming/core2

#rsync -rav --include '*/' --include='1054_G12_10*.tif.gz' --exclude='*' \
#/home/martin/Skrivbord/feature_extract_test/1054/ /home/martin/Skrivbord/feature_extract/incoming/core2

fullfile="$(find $1 -name '1054*_blue*')"
filename="${fullfile##*/}"
fileend="${fullfile##*_}"
fov_name="${filename%"${fileend}"}"
rm -rf $dir/tmp/siIn
rm -rf $dir/tmp/siOut
mkdir -p $dir/tmp/siIn/in
mkdir -p $dir/tmp/siOut
gzip -d $1/*.gz
ln -s -t $dir/tmp/siIn/in $1/*tif
if [ "$2" == "10" ]
	then
		matlab -nodisplay -nodesktop -nojvm -nosplash -r "cd $dir/features; [arr exit_status] = process_10x('./tmp/siIn','./tmp/siOut'); exit(exit_status);"
	else 
		matlab -nodisplay -nodesktop -nosplash -r "cd $dir/features; [arr exit_status] = process_63x('$dir/tmp/siIn','$dir/tmp/siOut',$2); exit(exit_status);"
fi

mv ./tmp/siOut/segmentation.png $1/$fov_name"segmentation.png"

if [ -f $dir/tmp/siOut/features.csv ];
then
	mv $dir/tmp/siOut/features.csv $1/$fov_name"features.csv"
else
	exit 1
fi
