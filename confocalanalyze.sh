#!/bin/bash

# $1 is resolution, $2 is input folder, $3 is output folder, $4 is start plate, $5 is start well, $6 is end plate, $7 is remote host path.

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
well=$5

#Make for loop, runs for specified plates ($plate) and wells ($well), from $4 and $5 to $6.
for (( plate=${4}; plate<=${6}; plate++ ))
do  
    well_letters="ABCDEFGH"
    
    while test -n "$well_letters"; do
        well_letter=${well_letters:0:1}     # get the first character in well_letters
        echo character is $well_letter
        well_letters=${well_letters:1}   # trim the first character in well_letters
    done
    
    echo $plate $well #testing

    mkdir $2/$plate

    rsync -rav --include '*/' --include="$plate"_"$well*.tif.gz" --exclude='*' \
    $7/$plate/ $2/$plate
    #here

    arr=( $(find $2/$plate -type f | sort) )
    echo ${#arr[@]} #testing

    # While loop, runs as long as there are files left in ../$2/$plate
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
        
        gunzip -d $2/$plate/$fov_name*.gz

        ln -s -t $dir/tmp/siIn/in $2/$plate/$fov_name"blue.tif"
        ln -s -t $dir/tmp/siIn/in $2/$plate/$fov_name"green.tif"
        ln -s -t $dir/tmp/siIn/in $2/$plate/$fov_name"red.tif"
        ln -s -t $dir/tmp/siIn/in $2/$plate/$fov_name"yellow.tif"

        echo $dir/tmp/siIn/in #testing

        # Check to make sure the links to four different color images exists in ../tmp/siIn/in, if it does, then run matlab on them
        links="$( find "$dir/tmp/siIn/in" -type l )"
         
        for link in $links; do
            echo $link #testing
            if [ ! -e $link ] ; then
                images_exist=0
                break
            else
                images_exist=1
            fi
        done

        if [ "$1" == "10" ] && [ "$images_exist" == "1" ]
        then
        	matlab -nodisplay -nodesktop -nojvm -nosplash -r "cd $dir/features; [arr exit_status] = process_10x('./tmp/siIn','./tmp/siOut'); exit(exit_status);"
        elif [ "$images_exist" == "1" ]
        then
        	echo -nodisplay -nodesktop -nosplash -r "cd $dir/features; [arr exit_status] = process_63x('$dir/tmp/siIn','$dir/tmp/siOut',$1); exit(exit_status);"
        else
            echo "no images to process"
        fi

        if [ "$images_exist" == "1" ]
        then
            mv ./tmp/siOut/segmentation.png $3/$plate/$fov_name"segmentation.png"

            if [ -f $dir/tmp/siOut/features.csv ];
            then
            	mv $dir/tmp/siOut/features.csv $3/$plate/$fov_name"features.csv"
            else
            	exit 1 #temporary testing without exit
            fi
        fi

        rm -f $2/$plate/$fov_name*
        arr=( $(find $2/$plate -type f) )
        echo ${#arr[@]} #testing
    done
done

