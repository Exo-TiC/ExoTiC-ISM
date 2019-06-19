plot_model

SP=['O3V','O5V','O6V','O8V','B0V','B3V','B5V','B8V','A0V','A5V','F0V','F5V','G0V','G5V','K0V','K5V','M0V','M2V','M5V','B0III','B5III','G0III','G5III','K0III','K5III','M0III','O5I','O6I','O8I','BOI','B5I','AOI','A5I','F0I','F5I','G0I','G5I','K0I','K5I','M0I','M2I']
models=['/grp/hst/cdbs/grid/k93models/kp00/kp00_50000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_45000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_40000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_35000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_30000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_19000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_15000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_12000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_9500.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_8250.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_7250.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_6500.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_6000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_5750.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_5250.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_4250.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_3750.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_3500.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_3500.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_29000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_15000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_5750.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_5250.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_4750.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_4000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_3750.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_40000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_40000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_34000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_26000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_14000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_9750.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_8500.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_7750.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_7000.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_5500.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_4750.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_4500.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_3750.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_3750.fits','/grp/hst/cdbs/grid/k93models/kp00/kp00_3500.fits']

nn=n_elements(SP)
for i=0,nn-1 do begin

   data=mrdfits(models,1,hdr1)
   filename=SP[i]+'.dat'
   openw,1,filename
   printf,1,'#  wavelegth     Flamb'
   for j=0, n_elements(data.wavelength)-1 do begin
      printf,1,data[j].wavelength,data[j].g00,format='(F10.4,E14.5)'
   endfor
endfor
end
