#!/bin/bash

# $1 is resolution, $2 is input folder, $3 is output folder,
# $4 is start plate, $5 is start well, $6 is end plate, $7 is remote path.

# Check that correct number of arguments are given when starting the script.
if [ $# -eq 0 ]; then
    echo "Syntax: $(basename $0) resolution input_folder output_folder" \
    "start_plate start_well end_plate remote_path"
    exit 1
fi

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
input_path="$( cd "${2}" && pwd )"
output_path="$( cd "${3}" && pwd )"
well=$5
start_letter=${well:0:1}
well_number=${well#?}
echo $well_number

# for loop, runs for specified plates ($plate)
# and wells ($well), from $4 and $5 to $6.
for (( plate=${4}; plate<=${6}; plate++ ))
do
    mkdir -p $input_path/$plate
    mkdir -p $output_path/$plate
    well_letters="ABCDEFGH"
    well_letters="${well_letters/*$start_letter/$start_letter}"

    while test -n "$well_letters"; do
        # get the first character in well_letters
        well_letter=${well_letters:0:1}
        # trim the first character in well_letters
        well_letters=${well_letters:1}
        for (( ${well_number}; well_number<=12; well_number++ )) 
        do
            well="$well_letter$well_number"

            rsync -rav --include '*/' --include="$plate"_"$well*.tif.gz" \
            --exclude='*' $7/$plate/ $input_path/$plate

            arr=( $(find $input_path/$plate -type f | sort) )
            echo ${#arr[@]} #testing

            # While loop, runs as long as there are files left
            # in ../$input_path/$plate
            while [ ${#arr[@]} -ge 1 ]
            do

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
        
                gunzip -d $input_path/$plate/$fov_name*.gz
                
                ln -s -t $dir/tmp/siIn/in \
                $input_path/$plate/$fov_name"blue.tif"
                ln -s -t $dir/tmp/siIn/in \
                $input_path/$plate/$fov_name"green.tif"
                ln -s -t $dir/tmp/siIn/in \
                $input_path/$plate/$fov_name"red.tif"
                ln -s -t $dir/tmp/siIn/in \
                $input_path/$plate/$fov_name"yellow.tif"

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

                if [ "$1" == "10" ] && [ "$images_exist" == "1" ]
                then
                	matlab -nodisplay -nodesktop -nojvm -nosplash -r \
                	"cd $dir/features; [arr exit_status] = process_10x(\
                	'$dir/tmp/siIn','$dir/tmp/siOut'); exit(exit_status);"
                elif [ "$images_exist" == "1" ]
                then
                	matlab -nodisplay -nodesktop -nosplash -r \
                	"cd $dir/features; [arr exit_status] = process_63x(\
                	'$dir/tmp/siIn','$dir/tmp/siOut',$1); exit(exit_status);"
                else
                    echo "no images to process"
                fi

                if [ "$images_exist" == "1" ]
                then
                    mv ./tmp/siOut/segmentation.png \
                    $output_path/$plate/$fov_name"segmentation.png"

                    if [ -f $dir/tmp/siOut/features.csv ];
                    then
                    	mv $dir/tmp/siOut/features.csv \
                    	$output_path/$plate/$fov_name"features.csv"
                    else
                    	exit 1 #temporary testing without exit
                    fi
                fi

                rm -f $input_path/$plate/$fov_name*
                arr=( $(find $input_path/$plate -type f) )
                echo ${#arr[@]} #testing
            done
        done
        well_number=1
    done
    start_letter="A"
done

