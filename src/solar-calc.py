import os
import boto3
import geopandas as gp
import subprocess as sub
from osgeo import gdal

# python3 solar-calc.py

def main():
    
    s3 = get_creds()
    
    gp_index = get_index(s3) 
    
    for index, row in gp_index.iterrows():
        tif_prefix = os.path.join(DSM_PATH, f"{os.path.basename(row.prefix).split('.')[0].replace('CL3', 'DSM')}.tif")                  
        if not os.path.exists(tif_prefix):
            s3.download_file(BUCKET, tif_prefix, tif_prefix, ExtraArgs={'RequestPayer':'requester'})
         
        tmp_tif_list = []   
        for day in DAYS:            
            sub.call(f"bash grass-build.sh {tif_prefix} {day}", shell=True) 
            tmp_out_tif = os.path.join(PALMY_PATH, f"{day}-{os.path.basename(row.prefix).split('.')[0].replace('CL3', 'DSM')}.tif")
            tmp_tif_list.append(tmp_out_tif)
        
        print("Creating Average...")
        tif_avg = os.path.join(SOLAR_PATH, f"solar-average-{os.path.basename(row.prefix).split('.')[0].replace('CL3', 'DSM')}.tif")
        sub.call(f"gdal_calc.py \
            --overwrite \
            -A {tmp_tif_list[0]} \
            -B {tmp_tif_list[1]} \
            -C {tmp_tif_list[2]} \
            -D {tmp_tif_list[3]} \
            --outfile={tif_avg} \
            --NoDataValue=0 \
            --projwin {row.minx} {row.maxy} {row.maxx} {row.miny} \
            --calc '(A + B + C + D)/4'", 
            shell=True)
        
        for f in tmp_tif_list:
            os.remove(f)
            
        s3.upload_file(tif_avg, BUCKET, tif_avg)
        
        # if index >= 10:
        #     break
    
    
def get_index(s3):
    if not os.path.exists(INDEX):
        s3.download_file(BUCKET, INDEX, INDEX)
    gp_index = gp.read_file(INDEX)
    
    return gp_index  
    
def get_creds():
    s3 = boto3.client(
        's3',
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY"),
    )
    
    return s3


if __name__ == "__main__":
    BUCKET = "health-hub-analysis"
    PALMY_PATH = os.path.join("data", "palm-north")
    DSM_PATH = os.path.join(PALMY_PATH, "dsm", "linz/manawatu-whanganui-palmerston-north-lidar-1m-dsm-2018")
    SOLAR_PATH = os.path.join(PALMY_PATH, "solar")
    LAZ_PATH = os.path.join(PALMY_PATH, "laz")
    INDEX = os.path.join(LAZ_PATH, "palmerston-north-laz-index.gpkg")
    DAYS = [80, 173, 266, 355]
    
    for d in [DSM_PATH, SOLAR_PATH, LAZ_PATH]:
        os.makedirs(d, exist_ok=True)
    
    main()