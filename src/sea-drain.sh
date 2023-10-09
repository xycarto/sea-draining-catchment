#!/bin/bash

# bash src/sea-drain.sh

OUT_DIR="data/nztm/vector/sea-draining-catchment"
CATCH_DIR="data/nztm/vector/catchments"
LIST="${CATCH_DIR}/catch-list.txt"

mkdir -p ${OUT_DIR}

init_vect=$(head -1 $LIST)
init_vect_for_merge=$(head -1 $LIST)
init_vect_name=$( basename ${init_vect_for_merge} .gpkg)
list=$(cat $LIST | grep -v $init_vect)


for i in $list
do
    ainput=$i
    binput=$init_vect

    abase=$(basename $i .gpkg)
    bbase=$( basename $binput .gpkg)
    overlay_name=${bbase}_overlay

    echo "running overlay"
    v.in.ogr input=$ainput output=$abase
    v.in.ogr input=$binput output=$bbase
    v.overlay ainput=$abase atype=area binput=$bbase btype=area output=$overlay_name operator=not --overwrite

    init_vect=$i

done

merge_list=$(g.list type=vector pattern=*_overlay)

input_list=$(echo $merge_list | sed "s/ /,/g")

#merge watersheds into single vector file
echo "running patch"
v.patch input=$input_list,$init_vect_name output=merged_watershed --overwrite

#output merged watersheds to SHP
echo "output merged watershed to file"
out_merged_watershed="${OUT_DIR}/merged-watershed.gpkg"
v.out.ogr input=merged_watershed output=$out_merged_watershed type=area format=GPKG --overwrite
