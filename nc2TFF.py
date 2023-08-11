import os
import numpy as np
import matplotlib.pyplot as plt

import netCDF4 as nc
from tqdm import tqdm
from osgeo import gdal,osr
from utils import getfiles

import warnings
warnings.filterwarnings("ignore")


#  数组保存为tif
def array2raster(TifName, GeoTransform, ncdata):
    cols = ncdata.shape[1]  # 矩阵列数
    rows = ncdata.shape[0]  # 矩阵行数
    # 判断栅格数据的数据类型
    if 'int8' in ncdata.dtype.name:
        datatype = gdal.GDT_Byte
    elif 'int16' in ncdata.dtype.name:
        datatype = gdal.GDT_UInt16
    else:
        datatype = gdal.GDT_Float32

    driver = gdal.GetDriverByName('GTiff')
    outRaster = driver.Create(TifName, cols, rows, 1, datatype)

    outRaster.SetGeoTransform(tuple(GeoTransform))
    # 获取数据集第一个波段，是从1开始，不是从0开始
    outband = outRaster.GetRasterBand(1)
    outband.WriteArray(ncdata)

    # 数据投影信息
    outRasterSRS = osr.SpatialReference()
    # 代码4326表示WGS84坐标
    outRasterSRS.ImportFromEPSG(4326)
    outRaster.SetProjection(outRasterSRS.ExportToWkt())

    outband.FlushCache()
    out_ds=outband= None # 关闭spei_ds指针，注意必须关闭

def nc2geo(file):
    ncdata = nc.Dataset(file, mode='r')
    # longitude and latitude
    lon = ncdata.variables['lon'][:]
    lat = ncdata.variables['lat'][:]

    #获取四个脚点坐标
    LonMin,LatMax,LonMax,LatMin = [np.min(lon),np.max(lat),np.max(lon),np.min(lat)]
    # 设置图像分辨率
    row = len(lat)
    col = len(lon)
    Lon_Res=(LonMax - LonMin) / (float(col) - 1)
    Lat_Res=(LatMax- LatMin) / (float(row) - 1)

    geotransform = (LonMin,Lon_Res, 0, LatMax,0,-Lat_Res)
    return geotransform

def processNC(file,target):
    # 读取数据，处理异常值
    or_data = nc.Dataset(file, mode='r')
    var = or_data.variables[target]
    var_nans = var[:]
    _FillValue = var._FillValue
    var_nans[var_nans == _FillValue] = np.nan
    ncdata = var_nans[0,:,:]
    # 灰度值转换
    # ncdata = 256 * (tmp_data - np.min(var))/(np.max(var)-np.min(var))
    ncdata = ncdata[::-1]#这里是需要倒置一下的 这个很重要！！！！！
    return ncdata

if __name__ == '__main__':
    BASEDIR = './data2022/'
    target = 'T250'
    isHourly = False
    OUTDIR =f'./out_{target}_Hourly/' if isHourly else f'./out_{target}_AvgDaily/'
    total_gen = 0
    if not os.path.exists(OUTDIR):
        os.makedirs(OUTDIR)

    file_list = getfiles(BASEDIR, 'nc4')
    Total = len(file_list)
    # Total =2
    print(f'Total process files : {Total}')

    GeoTransform = nc2geo(file_list[0])
    print(f'GeoTransform : {GeoTransform}')
    for i in tqdm(range(Total)):
        names = os.path.basename(file_list[i]).split(".")
        # 读取数据，处理异常值
        or_data = nc.Dataset(file_list[i], mode='r')
        var = or_data.variables[target]
        var_nans = var[:]
        _FillValue = var._FillValue
        var_nans[var_nans == _FillValue] = np.nan

        if isHourly:
            times = or_data.variables['time'][:]
            for j in range(len(times)):
                ncdata = var_nans[j, :, :]
                # ncdata = 256 * (tmp_data - np.min(var))/(np.max(var)-np.min(var))   # 灰度值转换
                ncdata = ncdata[::-1]
                TifName = f'{OUTDIR}{names[0]}_{target}_{names[2]}_{j}.tiff'
                array2raster(TifName, GeoTransform, ncdata)
                total_gen += 1
        else:
            ncdata = np.mean(var_nans,axis=0) # 日均
            ncdata = ncdata[::-1]  # 这里是需要倒置一下的 这个很重要！！！！！
            TifName = f'{OUTDIR}{names[0]}_{target}_{names[2]}.tiff'
            array2raster(TifName, GeoTransform, ncdata)
            total_gen += 1


    print(f'Success!!!!! total generate: {total_gen}')
