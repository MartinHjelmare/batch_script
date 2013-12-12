#!/bin/bash

# $1 is resolution, $2 is input folder, $3 is output folder,
# $4 is start line, $5 is end line, $6 is text file with plates

# Check that correct number of arguments are given when starting the script.
if [ $# -eq 0 ]; then
    echo "Syntax: $(basename $0) resolution input_folder output_folder" \
    "start_plate end_plate"
    exit 1
fi

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
input_path="$( cd "${2}" && pwd )"
output_path="$( cd "${3}" && pwd )"
FILE=$6
start_line=$4
end_line=$5
line_number=1

# Read txt-file with plate numbers, assign plate from start_line to end_line.

while read line; do
    echo "Line # $line_number: $line"
        
    while [ $line_number -ge start_line ] && [ $line_number -le end_line ]; do
        plate=$line

        # Find all images in plate, put into array
        arr=( $(find $input_path/images/$plate/*.tif* -type f | sort) )
        echo ${#arr[@]} #testing
    
        if [ ${#arr[@]} -ge 1 ]; then
            mkdir -p $output_path/$plate
            mkdir -p $input_path/done/$plate
        fi

        # While loop, runs as long as there are files left
        # in $input_path/images/$plate/
        while [ ${#arr[@]} -ge 1 ]; do

            # Find fov_name
            fullfile="${arr[0]}"
            filename="${fullfile##*/}"
            fileend="${fullfile##*_}"
            fov_name="${filename%"${fileend}"}"
        
            gunzip -d $input_path/images/$plate/$fov_name*.gz
        
            arr2=( $(find $input_path/images/$plate/$fov_name*.tif -type f \
            | sort) )

            rm -rf $dir/tmp/siIn
            rm -rf $dir/tmp/siOut
            mkdir -p $dir/tmp/siIn/in
            mkdir -p $dir/tmp/siOut
        
            # Check if those images are named *ch00.*,
            # *ch01.*, *ch02.*, *ch03.*,
            # if so change images field names to exclude _z0
            # and link ch00 to green, ch01 to blue, ch02 to yellow, ch03 to red.
            # Else check if those images are named *blue*,
            # if so make link to blue, green, red, yellow.
            # Else exit 1
            fullfile="${arr2[0]}"
            if [ "${fullfile##*_}" == "ch00.tif" ]; then
                ln -s $input_path/images/$plate/$fov_name"ch01.tif" \
                $dir/tmp/siIn/in/$fov_name"blue.tif"
                ln -s $input_path/images/$plate/$fov_name"ch00.tif" \
                $dir/tmp/siIn/in/$fov_name"green.tif"
                ln -s $input_path/images/$plate/$fov_name"ch03.tif" \
                $dir/tmp/siIn/in/$fov_name"red.tif"
                ln -s $input_path/images/$plate/$fov_name"ch02.tif" \
                $dir/tmp/siIn/in/$fov_name"yellow.tif"
                fov_name="${fov_name%z0_}"
            elif [ "${fullfile##*_}" == "blue.tif" ]; then
                ln -s -t $dir/tmp/siIn/in \
                $input_path/images/$plate/$fov_name*.tif
            else
                echo "image name is wrong"
                exit 1
            fi

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
                $output_path/$plate/$fov_name"segmentation.png"

                if [ -f $dir/tmp/siOut/features.csv ]; then
                   	mv $dir/tmp/siOut/features.csv \
                   	$output_path/$plate/$fov_name"features.csv"
                else
                    exit 1
                fi
            fi

            # Move finished input files
            mv $input_path/images/$plate/$fov_name* \
            $input_path/done/$plate
            arr=( $(find $input_path/images/$plate/*.tif* -type f | sort) )
            echo ${#arr[@]} #testing
        done
    done
    ((line_number++))
done < $FILE
