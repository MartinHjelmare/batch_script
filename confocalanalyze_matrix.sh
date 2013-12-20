#!/bin/bash

# $1 is resolution, $2 is input folder, $3 is output folder,

# Check that correct number of arguments are given when starting the script.
if [ $# -eq 0 ]; then
    echo "Syntax: $(basename $0) resolution input_folder output_folder"
    exit 1
fi

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
input_path="$( cd "${2}" && pwd )"
output_path="$( cd "${3}" && pwd )"

# Find all images in $input_path, put into array
arr=( $(find $input_path -name "*C01.ome.tif" | sort) )
echo ${#arr[@]} #testing

if [ ${#arr[@]} -ge 1 ]; then
    #find top directory in input_path
    #mkdir -p $output_path/topDir
    cd $input_path
    mkdir -p ../done/
    done_path="$( cd ../done/ && pwd )"
fi

# While loop, runs as long as there are files left in $input_path/
while [ ${#arr[@]} -ge 1 ]; do

    # Find fov_name
    fullfile="${arr[0]}"
    filename="${fullfile##*/}"
    file_path="${fullfile%%"${filename}"}"
    file_path="$( cd "${file_path}" && pwd )"
    fileend="${fullfile##*--}"
    fov_name="${filename%"${fileend}"}"
    
    echo $file_path #testing
    
    #gunzip -d $file_path/$fov_name*.gz

    rm -rf $dir/tmp/siIn
    rm -rf $dir/tmp/siOut
    mkdir -p $dir/tmp/siIn/in
    mkdir -p $dir/tmp/siOut
    
    # Check if those images are named *C00.ome.tif,
    # *C01.ome.tif, *C02.ome.tif, *C03.ome.tif,
    # and link C00 to green, C01 to blue, C02 to yellow, C03 to red.
    # Else make link to blue, green, red, yellow.
    arr2=( $(find $file_path -name "$fov_name*" | sort) )
    fullfile="${arr2[0]}"
    if [ "${fullfile##*--}" == "C00.ome.tif" ]; then
        ln -s $file_path/$fov_name"C01.ome.tif" \
        $dir/tmp/$plate/siIn/in/$fov_name"blue.tif"
        ln -s $file_path/$fov_name"C00.ome.tif" \
        $dir/tmp/$plate/siIn/in/$fov_name"green.tif"
        ln -s $file_path/$fov_name"C03.ome.tif" \
        $dir/tmp/$plate/siIn/in/$fov_name"red.tif"
        ln -s $file_path/$fov_name"C02.ome.tif" \
        $dir/tmp/$plate/siIn/in/$fov_name"yellow.tif"
        #fov_name="${fov_name%Z00--}" # To remove Z00-- from $fov_name
    else
        ln -s $file_path/$fov_name"blue.tif" \
        $dir/tmp/$plate/siIn/in/$fov_name"blue.tif"
        ln -s $file_path/$fov_name"green.tif" \
        $dir/tmp/$plate/siIn/in/$fov_name"green.tif"
        ln -s $file_path/$fov_name"red.tif" \
        $dir/tmp/$plate/siIn/in/$fov_name"red.tif"
        ln -s $file_path/$fov_name"yellow.tif" \
        $dir/tmp/$plate/siIn/in/$fov_name"yellow.tif"
    fi

    # Check to make sure the links to four different color images
    # exists in ../tmp/$plate/siIn/in, if it does, then run matlab on them
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
    
    # Move output and input files
    mv ./tmp/siOut/segmentation.png \
    $output_path/$fov_name"segmentation.png"
    # Compress finished input files
    gzip $file_path/$fov_name*

    if [ -f $dir/tmp/siOut/features.csv ]; then
        mv $dir/tmp/siOut/features.csv \
       	$output_path/$fov_name"features.csv"
        mv $file_path/$fov_name* \
        $done_path #add topDir after done
    else
        echo "No feature output file."
        cd $input_path
        mkdir -p ../wrong/
        wrong_path="$( cd ../wrong/ && pwd )"
        mv $file_path/$fov_name* \
        $wrong_path #add topDir after wrong
    fi
    
    arr=( $(find $input_path -name "*C01.ome.tif" | sort) )
    echo ${#arr[@]} #testing
done
