from netCDF4 import Dataset
import numpy as np
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
from cartopy.mpl.gridliner import LONGITUDE_FORMATTER, LATITUDE_FORMATTER
import matplotlib.ticker as mticker
from matplotlib.gridspec import GridSpec
import os
from tqdm import tqdm
from utils import getfiles

import warnings
warnings.filterwarnings("ignore")

BASEDIR = './data/'
OUTDIR ='./out'
VAR = 'TS'

def transform(file_path):
    fileName = os.path.basename(file_path).split(".")
    data = Dataset(file_path, mode='r')
    chartName = "_".join([fileName[0],VAR,fileName[-2]]);

    # longitude and latitude
    lons = data.variables['lon']
    lats = data.variables['lat']
    lon, lat = np.meshgrid(lons, lats)
    # surface_skin_temperature
    TS = data.variables['TS']

    TS_nans = TS[:]
    _FillValueTS = TS._FillValue
    TS_nans[TS_nans == _FillValueTS] = np.nan
    pltData = np.nanmean(TS, axis=0)

    # Set the figure size, projection, and extent
    dpi = 120
    w = 600
    h = 300
    # fig.set_size_inches(18, 9)
    fig = plt.figure(figsize=(w / dpi, h / dpi), dpi=dpi)
    ax = fig.add_axes([0, 0, 1, 1],projection=ccrs.PlateCarree())
    ax.set_axis_off()
    ax.set_global()
    # ax.coastlines()

    clevs = np.arange(180,350,10)
    plt.contourf(lon, lat, pltData, clevs,cmap='gray_r')

    plt.show()
    out_dir = OUTDIR+"_"+VAR
    if(os.path.exists(out_dir)==False):
        os.makedirs(out_dir)
    fig.savefig(out_dir+"/"+chartName+'.png', bbox_inches='tight',pad_inches=0.0)



if __name__ == '__main__':
    file_list = getfiles(BASEDIR,'nc')

    # Total = len(file_dir)
    Total = 2
    for i in tqdm(range(1,Total)):
        print(file_list[i])
        transform(file_list[i])

