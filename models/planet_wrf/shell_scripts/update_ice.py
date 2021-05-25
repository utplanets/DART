#!/usr/bin/env python
import netCDF4
import sys
from numpy import where

def update_surface(filename,
                   h2oice_threshold = 1.,
                   co2ice_threshold = 100.,
                   nh_co2ice_emiss  = 0.50,
                   sh_co2ice_emiss  = 0.79,
                   nh_co2ice_albedo = 0.63,
                   sh_co2ice_albedo = 0.45,
                   nh_h2oice_emiss  = 1.0,
                   sh_h2oice_emiss  = 1.0,
                   nh_h2oice_albedo = 0.33,
                   sh_h2oice_albedo = 0.33):

    nc = netCDF4.Dataset(filename,'a')

    h2o    = nc["H2OICE"][:]
    co2    = nc["CO2ICE"][:]
    albbck = nc["ALBBCK"][:]
    embck  = nc["EMBCK"][:]
    albedo = nc["ALBEDO"][:]
    emiss  = nc["EMISS"][:]
    lat    = nc["XLAT"][:]
    
    #co2 goes on top
    nh = lat > 0
    sh=~nh
    ct = co2 > co2ice_threshold
    wt = h2o > h2oice_threshold

    def apply(data,value, mask):
        if(mask.any()):
            data[where(mask)]=value
        return data
            
    albedo = albbck
    emiss = embck

    apply(albedo, nh_co2ice_albedo,nh*ct)
    apply(albedo, nh_h2oice_albedo,nh*(1-ct)*wt)
    apply(albedo, sh_co2ice_emiss, sh*ct)
    apply(albedo, sh_h2oice_emiss, sh*(1-ct)*wt)
    apply(emiss , nh_co2ice_emiss, nh*ct)
    apply(emiss , nh_h2oice_emiss, nh*(1-ct)*wt)
    apply(emiss , sh_co2ice_emiss, sh*ct)
    apply(emiss , sh_h2oice_emiss, sh*(1-ct)*wt)
    
    
#    albedo = (nh*ct)*nh_co2ice_albedo +\
#             (nh*(1-ct)*wt)*nh_h2oice_albedo +\
#             (nh*(1-ct)*(1-wt))
    
#    albedo = where(nh,
#          #nh
#          where(nh&ct,
#                nh_co2ice_albedo,
#                where(nh&wt,
#                      nh_h2oice_albedo,
#                      albbck)
#                ),
#          #sh
#          where((~nh)&ct,
#                nh_co2ice_albedo,
#                where((~nh)&wt,
#                      nh_h2oice_albedo,
#                      albbck)
#                ))
#
#
#    
#    emiss = where(nh,
#          #nh
#          where(nh&ct,
#                nh_co2ice_emiss,
#                where(nh&wt,
#                      nh_h2oice_emiss,
#                      albbck)
#                ),
#          #sh
#          where((~nh)&ct,
#                nh_co2ice_emiss,
#                where((~nh)&wt,
#                      nh_h2oice_emiss,
#                      albbck)
#                ))
#

    nc["ALBEDO"][:] = albedo
    nc["EMISS"][:] = emiss

    nc.close()


if __name__=="__main__":
    for filename in sys.argv[1:]:
        print(filename)
        update_surface(filename)
