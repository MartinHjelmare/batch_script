#!/bin/bash

well="B1"
start_letter=${well:0:1}
well_letters="ABCDEFGH"
well_letters="${$well_letters/"*"$start_letter/$start_letter}"

while test -n "$well_letters"; do
    well_letter=${well_letters:0:1}     # get the first character in well_letters
    echo character is $well_letter
    well_letters=${well_letters:1}   # trim the first character in well_letters
done

fov_name="${filename%"${fileend}"}"
