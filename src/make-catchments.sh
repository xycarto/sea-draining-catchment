#!/bin/bash

# bash src/grass-route-distance.sh

DEM="data/nztm/raster/dem-downsample/20m-dem.tif"
OUT_DIR="data/nztm/vector/catchments"
LIST="${OUT_DIR}/catch-list.txt"

if [[ -f $LIST ]] 
then
    rm $LIST
fi

mkdir -p ${OUT_DIR}

r.in.gdal --overwrite input=${DEM} output=dem

g.region --overwrite raster=dem -p

# Fill sinks
fillDEM="filldem"
directionDEM="directiondem"
areasDEM="areasDEM"

r.fill.dir input=dem output=$fillDEM direction=$directionDEM areas=$areasDEM --overwrite


list=$(echo 1000000 500000 250000 100000 50000 25000 10000)
for i in $list
do
    # Run watershed operation on fill sink raster
    threshold=$i
    accumulation=accumulation_${i}
    drainage=drainage_${i}
    stream=stream_${i}
    basin=basin_${i}
    r.watershed elevation=$fillDEM threshold=$threshold accumulation=$accumulation drainage=$drainage stream=$stream basin=$basin --overwrite

    # Convert Basin (watershed) to vector format
    basinVect=basinVect_${i}
    r.to.vect input=$basin output=$basinVect type=area column=bnum --overwrite

    # Export catchment to vector format
    basinVectOut=${OUT_DIR}/catchment_${i}.gpkg
    v.out.ogr input=$basinVect output=$basinVectOut type=area format=GPKG --overwrite

    echo $basinVectOut >> ${LIST}
done


