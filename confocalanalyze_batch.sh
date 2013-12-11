#!/bin/bash

#Add txt-file with plate numbers as argument instead of start end plate
# $1 is resolution, $2 is input folder, $3 is output folder,
# $4 is start plate, $5 is end plate

# Check that correct number of arguments are given when starting the script.
if [ $# -eq 0 ]; then
    echo "Syntax: $(basename $0) resolution input_folder output_folder" \
    "start_plate start_well"
    exit 1
fi

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
input_path="$( cd "${2}" && pwd )"
output_path="$( cd "${3}" && pwd )"

# for loop, runs for specified plates ($plate)
# and wells ($well), from $4 to $5.
for (( plate=${4}; plate<=${5}; plate++ )); do
    mkdir -p $output_path/$plate
    mkdir -p $input_path/done/$plate
    # Find all images in plate, put into array
    arr=( $(find $input_path/images/$plate/*.tif* -type f | sort) )
    echo ${#arr[@]} #testing

    # While loop, runs as long as there are files left
    # in $input_path/images/$plate/
    while [ ${#arr[@]} -ge 1 ]; do

        # Find fov_name
        fullfile="${arr[0]}"
        filename="${fullfile##*/}"
        fileend="${fullfile##*_}"
        fov_name="${filename%"${fileend}"}"
        echo $fov_name #testing
        
        arr2=( $(find $input_path/images/$plate/$fov_name*.tif* -type f | sort) )
        echo ${#arr2[@]} #testing

        rm -rf $dir/tmp/siIn
        rm -rf $dir/tmp/siOut
        mkdir -p $dir/tmp/siIn/in
        mkdir -p $dir/tmp/siOut
        
        gunzip -d $input_path/images/$plate/$fov_name*.gz
        
        # Check if those images are named *ch00.*,
        # *ch01.*, *ch02.*, *ch03.*,
        # if so change images field names to exclude _z0
        # and link ch00 to green, ch01 to blue, ch02 to yellow, ch03 to red.
        # Else check if those images are named *blue*,
        # if so make link to blue, green, red, yellow.
        # Else exit 1
        fullfile="${arr2[0]}"
        echo $fullfile #testing
        filename="${fullfile##*/}"
        echo $filename #testing
        echo "${fullfile##*_}" #testing
        if [ "${fullfile##*_}" == ch0?.* ]; then
            ln -s -t $dir/tmp/siIn/in/$fov_name"blue.tif" \
            $input_path/images/$plate/$fov_name"ch01.tif"
            ln -s -t $dir/tmp/siIn/in/$fov_name"green.tif" \
            $input_path/images/$plate/$fov_name"ch00.tif"
            ln -s -t $dir/tmp/siIn/in/$fov_name"red.tif" \
            $input_path/images/$plate/$fov_name"ch03.tif"
            ln -s -t $dir/tmp/siIn/in/$fov_name"yellow.tif" \
            $input_path/images/$plate/$fov_name"ch02.tif"
            fov_name="${fov_name%z0_}"
            echo $fov_name #testing
        elif [ "${fullfile##*_}" == blue.tif* ]; then
            ln -s -t $dir/tmp/siIn/in $input_path/images/$plate/$fov_name*.tif
        else
            echo "image name is wrong"
            #exit 1
        fi

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
            echo -nodisplay -nodesktop -nosplash -r \
            "cd $dir/features; [arr exit_status] = process_63x(\
            '$dir/tmp/siIn','$dir/tmp/siOut',$1); exit(exit_status);"
        else
            echo "no images to process"
        fi
        
        # Move output files
        if [ "$images_exist" == "1" ]; then
            mv ./tmp/siOut/segmentation.png \
            $output_path/$plate/$fov_name"segmentation.png"

            if [ -f $dir/tmp/siOut/features.csv ]; then
               	mv $dir/tmp/siOut/features.csv \
               	$output_path/$plate/$fov_name"features.csv"
            else
                echo #exit 1
            fi
        fi

        # Move finished input files
        mv $input_path/images/$plate/$fov_name* \
        $input_path/done/$plate
        arr=( $(find $input_path/images/$plate/*.tif* -type f | sort) )
        echo ${#arr[@]} #testing
    done
done
