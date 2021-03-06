#!/bin/bash

# $1 is resolution, $2 is input folder, $3 is output folder,
# $4 is start line, $5 is end line, $6 is text file with plates

# Check that correct number of arguments are given when starting the script.
if [ $# -eq 0 ]; then
    echo "Syntax: $(basename $0) resolution input_folder output_folder" \
    "start_line end_line plate_text_file"
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
        
    if [ $line_number -ge $start_line ] && [ $line_number -le $end_line ]; then
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

            rm -rf $dir/tmp/$plate/siIn
            rm -rf $dir/tmp/$plate/siOut
            mkdir -p $dir/tmp/$plate/siIn/in
            mkdir -p $dir/tmp/$plate/siOut
        
            # Check if those images are named *ch00.*,
            # *ch01.*, *ch02.*, *ch03.*,
            # if so change images field names to exclude _z0
            # and link ch00 to green, ch01 to blue, ch02 to yellow, ch03 to red.
            # Else check if those images are named *blue*,
            # if so make link to blue, green, red, yellow.
            # Else exit 1
            if [ "${fov_name##*_z}" == "0_" ]; then
                ln -s $input_path/images/$plate/$fov_name"ch01.tif" \
                $dir/tmp/$plate/siIn/in/$fov_name"blue.tif"
                ln -s $input_path/images/$plate/$fov_name"ch00.tif" \
                $dir/tmp/$plate/siIn/in/$fov_name"green.tif"
                ln -s $input_path/images/$plate/$fov_name"ch03.tif" \
                $dir/tmp/$plate/siIn/in/$fov_name"red.tif"
                ln -s $input_path/images/$plate/$fov_name"ch02.tif" \
                $dir/tmp/$plate/siIn/in/$fov_name"yellow.tif"
                fov_name="${fov_name%z0_}"
            else
                ln -s -t $dir/tmp/$plate/siIn/in \
                $input_path/images/$plate/$fov_name*.tif
                ln -s $input_path/images/$plate/$fov_name"blue.tif" \
                $dir/tmp/$plate/siIn/in/$fov_name"blue.tif"
                ln -s $input_path/images/$plate/$fov_name"green.tif" \
                $dir/tmp/$plate/siIn/in/$fov_name"green.tif"
                ln -s $input_path/images/$plate/$fov_name"red.tif" \
                $dir/tmp/$plate/siIn/in/$fov_name"red.tif"
                ln -s $input_path/images/$plate/$fov_name"yellow.tif" \
                $dir/tmp/$plate/siIn/in/$fov_name"yellow.tif"
            fi

            # Check to make sure the links to four different color images
            # exists in ../tmp/$plate/siIn/in, if it does, then run matlab on them
            links="$( find "$dir/tmp/$plate/siIn/in" -type l )"
        
            for link in $links; do
                if [ ! -e $link ] ; then
                    images_exist=0
                    echo "Not all four images exist!"
                    break
                else
                    images_exist=1
                fi
            done
        
            # Run matlab
            if [ "$1" == "10" ] && [ "$images_exist" == "1" ]; then
                matlab -nodisplay -nodesktop -nojvm -nosplash -r \
                "cd $dir/features; [arr exit_status] = process_10x(\
                '$dir/tmp/$plate/siIn','$dir/tmp/$plate/siOut'); exit(exit_status);"
            elif [ "$images_exist" == "1" ]; then
                matlab -nodisplay -nodesktop -nosplash -r \
                "cd $dir/features; [arr exit_status] = process_63x(\
                '$dir/tmp/$plate/siIn','$dir/tmp/$plate/siOut',$1); exit(exit_status);"
            else
                echo "no images to process"
            fi
        
            # Move output and input files
            mv ./tmp/$plate/siOut/segmentation.png \
            $output_path/$plate/$fov_name"segmentation.png"
            # Compress finished input files
            gzip $input_path/images/$plate/$fov_name*

            if [ -f $dir/tmp/$plate/siOut/features.csv ]; then
                mv $dir/tmp/$plate/siOut/features.csv \
               	$output_path/$plate/$fov_name"features.csv"
                mv $input_path/images/$plate/$fov_name* \
                $input_path/done/$plate
            else
                echo "No feature output file."
                
                mkdir -p $input_path/wrong/$plate
                mv $input_path/images/$plate/$fov_name* \
                $input_path/wrong/$plate
            fi
            
            arr=( $(find $input_path/images/$plate/*.tif* -type f | sort) )
            echo ${#arr[@]} #testing
        done
    fi
    ((line_number++))
done < $FILE
