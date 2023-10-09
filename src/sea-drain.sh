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
    # out_file=${OUT_DIR}/${file_name}.gpkg

    echo "running overlay"
    v.in.ogr input=$ainput output=$abase
    v.in.ogr input=$binput output=$bbase
    v.overlay ainput=$abase atype=area binput=$bbase btype=area output=$overlay_name operator=not --overwrite

    # echo "output overlays to gpkg"
    # v.out.ogr input=${fileName} output=$shpOut type=area format=GPKG --overwrite

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

# #add id column
# echo "add id column and populate"
# ogrinfo $outMergedWatershed -sql "ALTER TABLE mergedWatershed ADD COLUMN id integer" 
# ogrinfo $outMergedWatershed -dialect SQLite -sql "UPDATE mergedWatershed set id = rowid+1"

# #clean up geometries. Necessary to fix invalid geometry
# echo "running buffer"
# ogr2ogr -f "ESRI Shapefile" ${outDir}/mergedWatershed_buff.shp $outMergedWatershed -dialect sqlite -sql "select id, ST_buffer(Geometry,0) as geom from mergedWatershed" -overwrite

# g.remove -f type=vector pattern="*_overlay"