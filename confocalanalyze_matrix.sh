#!/bin/bash

# $1 is resolution, $2 is input folder, $3 is output folder,
# $4 is start well, $5 is start field, $6 is end well, $7 is remote path.

# Check that correct number of arguments are given when starting the script.
if [ $# -eq 0 ]; then
    echo "Syntax: $(basename $0) resolution input_folder output_folder" \
    "start_plate start_well end_plate remote_path"
    exit 1
fi

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
input_path="$( cd "${2}" && pwd )"
output_path="$( cd "${3}" && pwd )"
field=$5
start_letter=${field:0:1}
well_number=${field#?}
echo $well_number

#Make $well_U and $well_V

# for loop, runs for specified wells ($well)
# and fields ($field), from $4 and $5 to $6.
for (( well=${4}; well<=${6}; well++ )); do
    mkdir -p $input_path/$well
    mkdir -p $output_path/$well
    well_letters="ABCDEFGH"
    well_letters="${well_letters/*$start_letter/$start_letter}"

    # While loop, to go through the rows of the wells, A-H
    while test -n "$well_letters"; do
        # get the first character in well_letters
        well_letter=${well_letters:0:1}
        # trim the first character in well_letters
        well_letters=${well_letters:1}
        
        # for loop, to go throuhg the columns of the wells, 1-12
        for (( ${well_number}; well_number<=12; well_number++ )); do
            well="$well_U$well_V"

            rsync -rav --include '*/' --include=$well"_*.tif.gz" \
            --exclude='*' $7 $input_path/$well

            arr=( $(find $input_path/$well -type f | sort) )
            echo ${#arr[@]} #testing

            # While loop, runs as long as there are files left
            # in ../$input_path/$plate
            while [ ${#arr[@]} -ge 1 ]; do

                # Find fov_name
                fullfile="${arr[0]}"
                filename="${fullfile##*/}"
                fileend="${fullfile##*_}"
                fov_name="${filename%"${fileend}"}"
                echo $fov_name #testing

                rm -rf $dir/tmp/siIn
                rm -rf $dir/tmp/siOut
                mkdir -p $dir/tmp/siIn/in
                mkdir -p $dir/tmp/siOut
        
                gunzip -d $input_path/$well/$fov_name*.gz
                
                ln -s -t $dir/tmp/siIn/in \
                $input_path/$well/$fov_name"blue.tif"
                ln -s -t $dir/tmp/siIn/in \
                $input_path/$well/$fov_name"green.tif"
                ln -s -t $dir/tmp/siIn/in \
                $input_path/$well/$fov_name"red.tif"
                ln -s -t $dir/tmp/siIn/in \
                $input_path/$well/$fov_name"yellow.tif"

                echo $dir/tmp/siIn/in #testing

                # Check to make sure the links to four different color images
                # exists in ../tmp/siIn/in, if it does, then run matlab on them
                links="$( find "$dir/tmp/siIn/in" -type l )"
         
                for link in $links; do
                    if [ ! -e $link ] ; then
                        images_exist=0
                        break
                    else
                        images_exist=1
                    fi
                done
                
                # Run matlab
                if [ "$1" == "10" ] && [ "$images_exist" == "1" ]; then
                	matlab -nodisplay -nodesktop -nojvm -nosplash -r \
                	"cd $dir/features; [arr exit_status] = process_10x(\
                	'$dir/tmp/siIn','$dir/tmp/siOut'); exit(exit_status);"
                elif [ "$images_exist" == "1" ]; then
                	matlab -nodisplay -nodesktop -nosplash -r \
                	"cd $dir/features; [arr exit_status] = process_63x(\
                	'$dir/tmp/siIn','$dir/tmp/siOut',$1); exit(exit_status);"
                else
                    echo "no images to process"
                fi
                
                # Move output files
                if [ "$images_exist" == "1" ]; then
                    mv ./tmp/siOut/segmentation.png \
                    $output_path/$well/$fov_name"segmentation.png"

                    if [ -f $dir/tmp/siOut/features.csv ]; then
                    	mv $dir/tmp/siOut/features.csv \
                    	$output_path/$well/$fov_name"features.csv"
                    else
                    	exit 1
                    fi
                fi

                # Remove finished input files
                rm -f $input_path/$well/$fov_name*
                arr=( $(find $input_path/$well -type f) )
                echo ${#arr[@]} #testing
            done
        done
        well_number=1
    done
    start_letter="A"
done

