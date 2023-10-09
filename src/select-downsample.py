import os
os.environ['USE_PYGEOS'] = '0'
import geopandas as gp
from osgeo import gdal

# python3 src/select-downsample.py 

def main():
    
    index = gp.read_file(INDEX)
    coast = gp.read_file(COAST)
    
    selection = index[index.intersects(coast.geometry.unary_union)]
    for ind, row in selection.iterrows():
        name = row.location
        dem_path = os.path.join(DEM_DIR, name)
        out_path = os.path.join(OUT_DIR, f"{RESO}m-{name}")
        gdal.Translate(
            out_path,
            dem_path,
            xRes = RESO,
            yRes = RESO,
            callback=gdal.TermProgress_nocb
        )

if __name__ in "__main__":
    DEM_DIR = "data/nztm/raster/dem_clip_nztm"
    INDEX = "data/nztm/raster/dem_clip_nztm/dem-index.gpkg"
    COAST = "data/nztm/vector/coastline-ni.gpkg"    
    OUT_DIR = "data/nztm/raster/dem-downsample"
    RESO = "20"
    
    os.makedirs(OUT_DIR, exist_ok=True)
    
    main()