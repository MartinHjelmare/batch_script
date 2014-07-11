#!/bin/bash

# $1 is path to FOV part of image-name, $2 is resolution
# Check that correct number of arguments are given when starting the script.
if [ $# -ne 3 ]; then
    echo "Syntax: $(basename $0) resolution input_path output_path"
    exit 1
fi

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
input_path="$( cd "${2}" && pwd )"
output_path="$( cd "${3}" && pwd )"

# Find all images in input folder, put into array
arr=( $(find $input_path/*.tif* -type f | sort) )
echo ${#arr[@]} #testing

if [ ${#arr[@]} -ge 1 ]; then
    mkdir -p $input_path/done
fi

# While loop, runs as long as there are files left
# in $input_path/
while [ ${#arr[@]} -ge 1 ]; do

    # Find fov_name
    fullfile="${arr[0]}"
    filename="${fullfile##*/}"
    fileend="${fullfile##*_}"
    fov_name="${filename%"${fileend}"}"

    gunzip -d $input_path/$fov_name*.gz

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
    if [ "${fov_name##*_z}" == "0_" ]; then
        ln -s $input_path/$fov_name"ch01.tif" \
        $dir/tmp/siIn/in/$fov_name"blue.tif"
        ln -s $input_path/$fov_name"ch00.tif" \
        $dir/tmp/siIn/in/$fov_name"green.tif"
        ln -s $input_path/$fov_name"ch03.tif" \
        $dir/tmp/siIn/in/$fov_name"red.tif"
        ln -s $input_path/$fov_name"ch02.tif" \
        $dir/tmp/siIn/in/$fov_name"magenta.tif"
        fov_name="${fov_name%z0_}"
    else
        ln -s -t $dir/tmp/siIn/in \
        $input_path/$fov_name*.tif
        ln -s $input_path/$fov_name"blue.tif" \
        $dir/tmp/siIn/in/$fov_name"blue.tif"
        ln -s $input_path/$fov_name"green.tif" \
        $dir/tmp/siIn/in/$fov_name"green.tif"
        ln -s $input_path/$fov_name"red.tif" \
        $dir/tmp/siIn/in/$fov_name"red.tif"
        ln -s $input_path/$fov_name"magenta.tif" \
        $dir/tmp/siIn/in/$fov_name"magenta.tif"
    fi

    # Check to make sure the links to four different color images
    # exists in ../tmp/siIn/in, if it does, then run matlab on them
    links="$( find "$dir/tmp/siIn/in" -type l )"

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
        '$dir/tmp/siIn','$dir/tmp/siOut'); exit(exit_status);"
    elif [ "$images_exist" == "1" ]; then
        matlab -nodisplay -nodesktop -nosplash -r \
        "cd $dir/features; [arr exit_status] = process_63x(\
        '$dir/tmp/siIn','$dir/tmp/siOut',$1); exit(exit_status);"
    else
        echo "no images to process"
    fi

    # Move output and input files
    mv ./tmp/siOut/segmentation.png \
    $output_path/$fov_name"segmentation.png"
    # Compress finished input files
    gzip $input_path/$fov_name*

    if [ -f $dir/tmp/siOut/features.csv ]; then
        mv $dir/tmp/siOut/features.csv \
       	$output_path/$fov_name"features.csv"
        mv $input_path/$fov_name* \
        $input_path/done
    else
        echo "No feature output file."
        mkdir -p $input_path/wrong
        mv $input_path/$fov_name* \
        $input_path/wrong
    fi

    arr=( $(find $input_path/*.tif* -type f | sort) )
    echo ${#arr[@]} #testing
done
