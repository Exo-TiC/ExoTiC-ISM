pro limb_fit_3D_choose,grating,widek,wsdata,uLD,c1,c2,c3,c4,cp1,cp2,cp3,cp4,aLD,bLD,header,M_H,Teff,logg
;
; NAME:
;  limb_fit_3D_choose
;
; PURPOSE:
;  Calculates stellar limb-darkening coefficents for a given wavelegnth bin
;  Procedure from Sing et al. (2010, A&A, 510, A21)
;  Uses 3D limb darkening from Magic et al. (2015, A&A, 573, 90)
;  Uses photon FLUX Sum over (lambda*dlamba)
;
; CALLING SEQUENCE:
;  Edit lines 54,55 as needed
;  limb_fit_3D_choose,grating,widek,wsdata,uLD,c1,c2,c3,c4,cp1,cp2,cp3,cp4,aLD,bLD,header,M_H,Teff,logg
;
; INPUT:
;   grating - string indicationg grating to use ('G430L','G750L','WFC3','R500B','R500R')
;   wsdata  - array containing data wavelegnth solution
;   widek   - index array of wsdata, indicating bin of pixels to use
;   Teff    - Stellar effective temperature (K)
;   logg    - Stellar gravity
;   M_H     - Stellar Metalicity
;
; OUTPUT:
;   uLD             - linear limb darkening coefficient
;   aLD,bLD         - quadratic limb darkening coefficients
;   cp1,cp2,cp3,cp4 - three-parameter limb darkening coefficients
;   c1,c2,c3,c4     - non-linear limb-darkening coefficients
;
; DEPENDENCIES:
;    MPFIT
;    linterp.pro
;    3D model grid from Magic et al.
;    Grating Responce .sav Files, arrays wssens and sensitivity; where wssens is in Angstroms
;
; Note:
;    - Directories contining sensitivity files and 3D limb-darkening files are hard coded in (lines 53,54) and need to be changed
;    - ***Bug found for 7000 K atmosphere*** running into NaNs in array phot1
;    - ***Not all Grid is currently available(23/11/2015)****
;
; DKS 23/11/2015
; Version 3 - Changed to input 3D model Grid
;           - input also uses M_H,Teff,logg of Star to pick closest
;             grid model
; version 2  -also has a model specifically for the G750M model
;            -fixed bug in how "wide" was used for the responce array, off by 2 pixels before
;            -fixed another "wide" bug and now call it "widek" so it prevents a 2 pixel shift from propogating to the next program
;
; close,1
; window,4,xpos=80,ypos=0,xsize=1250,ysize=800  ;,xpos=80,ypos=500,xsize=1250,ysize=800
; window,5,xpos=80,ypos=600,xsize=500,ysize=500 ;,xpos=1450,ypos=800,xsize=1100,ysize=700

; Read config file (mainly for paths)
whereis,'W17_lightcurve_test', HST_fullpath
HST_dir = FILE_DIRNAME(HST_fullpath)

IF FILE_TEST(HST_dir + '/config_override.txt') THEN BEGIN
  structure = read_params_vm(HST_dir + '/config_override.txt')
ENDIF ELSE BEGIN
  structure = read_params_vm(HST_dir + '/config.txt')
ENDELSE

; Start code
dirsen = structure.LIMBDARKENING
direc = dirsen + '3DGrid/'
print,'Current Directories Entered:'
print,'  '+dirsen
print,'  '+direc


!path = '~/IDL/pro:'+ !path
set_plot,'x'
device,RETAIN=2



;==== Select Metalicity
M_H_Grid=[-3.0,-2.0,-1.0,0.0] ;Grid values points
M_H_Grid_load=['30','20','10','00'] ;Grid values points
  optM=where(abs(M_H-M_H_Grid) eq min(abs(M_H-M_H_Grid)))

;==== Select Teff
Teff_Grid=[4000,4500,5000,5500,5777,6000,6500,7000]
  optT=where(abs(Teff-Teff_Grid)eq min(abs(Teff-Teff_Grid)))

;==== Select logg ==

if (Teff_Grid(optT) eq 4000) then begin & logg_Grid=[1.5,2.0,2.5] & optG=where(abs(logg-logg_Grid)eq min(abs(logg-logg_Grid))) & endif
if (Teff_Grid(optT) eq 4500) then begin & logg_Grid=[2.0,2.5,3.0,3.5,4.0,4.5,5.0] & optG=where(abs(logg-logg_Grid)eq min(abs(logg-logg_Grid))) & endif
if (Teff_Grid(optT) eq 5000) then begin & logg_Grid=[2.0,2.5,3.0,3.5,4.0,4.5,5.0] & optG=where(abs(logg-logg_Grid)eq min(abs(logg-logg_Grid))) & endif
if (Teff_Grid(optT) eq 5500) then begin & logg_Grid=[3.0,3.5,4.0,4.5,5.0] & optG=where(abs(logg-logg_Grid)eq min(abs(logg-logg_Grid))) & endif
if (Teff_Grid(optT) eq 5777) then begin & logg_Grid=[4.4] & optG=0 & endif
if (Teff_Grid(optT) eq 6000) then begin & logg_Grid=[3.5,4.0,4.5] & optG=where(abs(logg-logg_Grid)eq min(abs(logg-logg_Grid))) & endif
if (Teff_Grid(optT) eq 6500) then begin & logg_Grid=[4.0,4.5] & optG=where(abs(logg-logg_Grid)eq min(abs(logg-logg_Grid))) & endif
if (Teff_Grid(optT) eq 7000) then begin & logg_Grid=[4.5] & optG=0 & endif

  ;optG=where(abs(logg-logg_Grid)eq min(abs(logg-logg_Grid)))

;==== Select Teff and Log g
mtxt=(m_h_grid_load(optm))
Ttxt=string(Teff_grid(optT)/100,format='(I02)')
  if (Teff_Grid(optT) eq 5777) then Ttxt=string(Teff_grid(optT),format='(I04)')
Gtxt=string(logg_grid(optg)*10,format='(I02)')
file='mmu_t'+Ttxt+'g'+Gtxt+'m'+mtxt+'v05.flx'
model=file
  header=file
;  if (header eq 0) then goto,skipthis
  restore,direc+file,/ver
  ws=mmd.(7) ;wavelength
    ws=ws(*,0)
  f=mmd.(8)
  Teff_model=Teff_grid(optT)
  logg_model=logg_grid(optg)
  MH_model=string(m_h_grid(optm))
  print,'  ',header
  f0=f[*,0]
  f1=f[*,1]
  f2=f[*,2]
  f3=f[*,3]
  f4=f[*,4]
  f5=f[*,5]
  f6=f[*,6]
  f7=f[*,7]
  f8=f[*,8]
  f9=f[*,9]
  f10=f[*,10]

; Mu from grid
;    0.00000    0.0100000    0.0500000     0.100000     0.200000     0.300000   0.500000     0.700000     0.800000     0.900000      1.00000
mu=mmd.(3)


;=============
; HST,GTC - load responce function and interpolate onto kurucz model grid
;==============
if (grating eq 'G430L') then begin
 restore, dirsen+'G430L.sensitivity.sav';wssens,sensitivity
 wdel=3
endif
if (grating eq 'G750M') then begin
 restore, dirsen+'G750M.sensitivity.sav';wssens,sensitivity
 wdel=0.554
endif
if (grating eq 'G750L') then begin
 restore, dirsen+'G750L.sensitivity.sav';wssens,sensitivity
 wdel=4.882D0
endif
if (grating eq 'G141') then begin ;http://www.stsci.edu/hst/acs/analysis/reference_files/synphot_tables.html
  restore,dirsen+'G141.WFC3.sensitivity.sav';wssens,sensitivity
  wdel=1
endif
if (grating eq 'G102') then begin ;http://www.stsci.edu/hst/acs/analysis/reference_files/synphot_tables.html
  restore, dirsen+'G141.WFC3.sensitivity.sav';wssens,sensitivity
  wdel=1
endif
;GTC
if (grating eq 'R500B') then begin
 restore, dirsen+'R500B.sensitivity.sav';wssens,sensitivity
 wdel=3.78201D0
endif
if (grating eq 'R500R') then begin
 restore, dirsen+'R500R.sensitivity.sav';wssens,sensitivity
 wdel=4.88D0
endif

wsHST=wssens & wsHST=[wsHST(0)-wdel-wdel,wsHST(0)-wdel,wsHST,wsHST(n_elements(wsHST)-1)+wdel,wsHST(n_elements(wsHST)-1)+wdel+wdel]
respoutHST=sensitivity/max(sensitivity) & respoutHST=[0D0,0D0,respoutHST,0D0,0D0]
linterp,wsHST,respoutHST,ws,respout  ;interpolate sensitivity curve onto model wavelength grid

wsdata=[wsdata(0)-wdel-wdel,wsdata(0)-wdel,wsdata,wsdata(n_elements(wsdata)-1)+wdel,wsdata(n_elements(wsdata)-1)+wdel+wdel] ;pad with zeros
respwavebin=wsdata/wsdata*0.0D0
widek=widek+2 ; need to add two indicies to compensate for padding with 2 zeros
respwavebin(widek)=1.0D0
linterp,wsdata,respwavebin,ws,reswavebinout  ;interpolate data onto model wavelength grid
  ;Trim elements that are not needed in calculation
  low=where(ws ge wsdata(0)) & low=low[0]
  high=where(ws le wsdata(n_elements(wsdata)-1)) & high=high(n_elements(high)-1)
  ws2=ws & ws3=ws
  ;trim,low,high,ws,respout,reswavebinout,f0,f1,f2
  ;trim,low,high,ws2,f3,f4,f5,f6,f7
  ;trim,low,high,ws3,f8,f9,f10
; plot
; wset,5
; plot,ws,f0/max(f0),xrange=[wsdata(0),wsdata(n_elements(wsdata)-1)],yrange=[0,1], title='Model 3D spectra (white), response curve (red), & Desired Wavelength bin (green)',/xstyle,/ystyle
; oplot,ws,respout,color=1000 & oplot,ws,reswavebinout,color=321321

;help,f,f10
fcalc=[[f0],[f1],[f2],[f3],[f4],[f5],[f6],[f7],[f8],[f9],[f10]]
;help,fcalc
phot1=dblarr(11)

; integrate over the spectra to make synthetic phomometric points
for i=0,10 do begin & $ ; loop over spectra at diff angles
    fcal=fcalc(*,i) & $
    Tot=INT_TABULATED(ws,ws*respout*reswavebinout) & $
    phot1(i)=(INT_TABULATED(ws,ws*respout*reswavebinout*fcal,/sort,/double))/Tot & $
endfor



;===== fit coefficients
yall=[[phot1/phot1(10)]]  ;,[phot3/phot3(0)],[phot2/phot2(0)],[phot4/phot4(0)],[phot187/phot187(0)],[phot166/phot166(0)]]
Co=dblarr(6,4)

;=====================================================================
for i=0,0 do begin
;=== Corot 4-parameter
A = [0.0,0.0,0.0,0.0]       ; c1,c2,c3,c4
x=mu(1:10)
y=yall(1:10,i)
weights = x/x
fa = {X:x, Y:y, ERR:weights}  ;create structure of data to be fitt
p0=A   ;initial guess
parinfo = replicate({value:0.D, fixed:0, limited:[0,0], limits:[0.D,0]}, n_elements(p0))
parinfo[*].value=p0
;  parinfo[0].fixed = 1         ; fixes parameter
;  parinfo[1].fixed = 1         ; fixes parameter
;  parinfo[2].fixed = 1         ; fixes parameter
;  parinfo[3].fixed = 1         ; fixes parameter
params = mpfit('nonlinmpfit', functargs=fa,BESTNORM=bestnorm,PERROR=perror,PARINFO=parinfo,niter=niter,maxiter=maxer,status=status)
 Dof     = N_ELEMENTS(X) - N_ELEMENTS(PARMS) ; deg of freedom
 PCERROR = PERROR * SQRT(BESTNORM / DOF)   ; scaled uncertainties
a=params
x2=findgen(100)*0.01
  F =  (1. - (  a[0]*(1. - x2^(1./2.)) + $
      a[1]*(1. - x2^(2./2.)) + $
      a[2]*(1. - x2^(3./2.)) + $
      a[3]*(1. - x2^(4./2.))  )  )
f4=f
; wset,4
; if (i eq 0) then plot,x,y,psym=1,xtitle='Mu',ytitle='I/Io',title='model '+header
; oplot,x2,f,color=cgcolor('red', !D.Table_Size-2)
; oplot,x,y,psym=1
; oplot,x2,f,color=cgcolor('red', !D.Table_Size-2),thick=2
; print,''
; print,a
; xyouts,0.05+1*0.15,0.35,'4-parameter',color=cgcolor('red', !D.Table_Size-2)
; xyouts,0.0+1*0.15,0.3,a(0)
; xyouts,0.0+1*0.15,0.25,a(1)
; xyouts,0.0+1*0.15,0.2,a(2)
; xyouts,0.0+1*0.15,0.15,a(3)
; xyouts,0.0+1*0.15,0.05,1-total(a)
Co(0,*)=a
endfor   ;loop over bandpasses
;=====================================================================
for i=0,0 do begin
;=== Corot 3-parameter
A = [0.0,0.0,0.0,0.0]       ; c1,c2,c3,c4
x=mu(1:10)
y=yall(1:10,i)
weights = x/x
fa = {X:x, Y:y, ERR:weights}  ;create structure of data to be fitt
p0=A   ;initial guess
parinfo = replicate({value:0.D, fixed:0, limited:[0,0], limits:[0.D,0]}, n_elements(p0))
parinfo[*].value=p0
  parinfo[0].fixed = 1         ; fixes parameter
;  parinfo[1].fixed = 1         ; fixes parameter
;  parinfo[2].fixed = 1         ; fixes parameter
;  parinfo[3].fixed = 1         ; fixes parameter
params = mpfit('nonlinmpfit', functargs=fa,BESTNORM=bestnorm,PERROR=perror,PARINFO=parinfo,niter=niter,maxiter=maxer,status=status)
 Dof     = N_ELEMENTS(X) - N_ELEMENTS(PARMS) ; deg of freedom
 PCERROR = PERROR * SQRT(BESTNORM / DOF)   ; scaled uncertainties
a=params
x2=findgen(100)*0.01
  F =  (1. - (  a(0)*(1. - x2^(1./2.)) + $
      a(1)*(1. - x2^(2./2.)) + $
      a(2)*(1. - x2^(3./2.)) + $
      a(3)*(1. - x2^(4./2.))  )  )
; oplot,x2,f,color=cgcolor('Green', !D.Table_Size-2)
; oplot,x,y,psym=1
; oplot,x2,f,color=cgcolor('Green', !D.Table_Size-2)
; print,'Corot'
; print,a
; xyouts,0.05+2*0.15,0.35,'3-parameter',color=cgcolor('Green', !D.Table_Size-2)
; xyouts,0.0+2*0.15,0.3,a(0)
; xyouts,0.0+2*0.15,0.25,a(1)
; xyouts,0.0+2*0.15,0.2,a(2)
; xyouts,0.0+2*0.15,0.15,a(3)
; xyouts,0.0+2*0.15,0.05,1-total(a)
Co(1,*)=a
endfor   ;loop over bandpasses

;=====================================================================
;=== Corot quadratic
for i=0,0 do begin
A = [0.0,0.0,0.0,0.0]       ; c1,c2,c3,c4
x=mu(1:10)
y=yall(1:10,i)
weights = x/x
fa = {X:x, Y:y, ERR:weights}  ;create structure of data to be fitt
p0=A   ;initial guess
parinfo = replicate({value:0.D, fixed:0, limited:[0,0], limits:[0.D,0]}, n_elements(p0))
parinfo[*].value=p0
  parinfo[0].fixed = 1         ; fixes parameter
;  parinfo[1].fixed = 1         ; fixes parameter
  parinfo[2].fixed = 1         ; fixes parameter
;  parinfo[3].fixed = 1         ; fixes parameter
params = mpfit('quadmpfit', functargs=fa,BESTNORM=bestnorm,PERROR=perror,PARINFO=parinfo,niter=niter,maxiter=maxer,status=status)
 Dof     = N_ELEMENTS(X) - N_ELEMENTS(PARMS) ; deg of freedom
 PCERROR = PERROR * SQRT(BESTNORM / DOF)   ; scaled uncertainties
a=params
x2=findgen(100)*0.01
  F =  1. - a(1)*(1. - x2) - a(3)*(1. - x2)^(4./2.)
; oplot,x2,f,color=cgcolor('Blue', !D.Table_Size-2)
; print,'quadratic'
; print,a
; xyouts,0.05+3*0.15,0.35,'Quadratic',color=cgcolor('Blue', !D.Table_Size-2)
; xyouts,0.0+3*0.15,0.3,a(0)
; xyouts,0.0+3*0.15,0.25,a(1)
; xyouts,0.0+3*0.15,0.2,a(2)
; xyouts,0.0+3*0.15,0.15,a(3)
; xyouts,0.0+3*0.15,0.05,1-total(a)
Co(2,*)=a
endfor   ;loop over bandpasses
;=====================================================================
;=== Corot linear
for i=0,0 do begin
A = [0.0,0.0,0.0,0.0]       ; c1,c2,c3,c4
x=mu(1:10)
y=yall(1:10,i)
weights = x/x
fa = {X:x, Y:y, ERR:weights}  ;create structure of data to be fitt
p0=A   ;initial guess
parinfo = replicate({value:0.D, fixed:0, limited:[0,0], limits:[0.D,0]}, n_elements(p0))
parinfo[*].value=p0
  parinfo[0].fixed = 1         ; fixes parameter
;  parinfo[1].fixed = 1         ; fixes parameter
  parinfo[2].fixed = 1         ; fixes parameter
  parinfo[3].fixed = 1         ; fixes parameter
params = mpfit('nonlinmpfit', functargs=fa,BESTNORM=bestnorm,PERROR=perror,PARINFO=parinfo,niter=niter,maxiter=maxer,status=status)
 Dof     = N_ELEMENTS(X) - N_ELEMENTS(PARMS) ; deg of freedom
 PCERROR = PERROR * SQRT(BESTNORM / DOF)   ; scaled uncertainties
a=params
x2=findgen(100)*0.01
  F =  (1. - (  a(0)*(1. - x2^(1./2.)) + $
      a(1)*(1. - x2^(2./2.)) + $
      a(2)*(1. - x2^(3./2.)) + $
      a(3)*(1. - x2^(4./2.))  )  )
; oplot,x2,f,color=cgcolor('Yellow', !D.Table_Size-2)
; fl=f
; print,'quadratic'
; print,a
; xyouts,0.05+4*0.15,0.35,'Linear',color=cgcolor('Yellow', !D.Table_Size-2)
; xyouts,0.0+4*0.15,0.3,a(0)
; xyouts,0.0+4*0.15,0.25,a(1)
; xyouts,0.0+4*0.15,0.2,a(2)
; xyouts,0.0+4*0.15,0.15,a(3)
; xyouts,0.0+4*0.15,0.05,1-total(a)
; xyouts,0.05,0.3,'c1'
; xyouts,0.05,0.25,'c2, c2, aLD, uLD'
; xyouts,0.05,0.2,'c3, c3'
; xyouts,0.05,0.15,'c4, c4, bLD'
; xyouts,0.05,0.05,'1-sum(coeff.)'

Co(3,*)=a
endfor
; xyouts,0.8,0.3,'       Teff   logg    Fe/H'
; xyouts,0.8,0.25,'Input:  '+string(Teff,format='(I04)')+' '+string(logg,format='(F4.2)')+' '+string(M_H,format='(F6.3)')
; xyouts,0.8,0.20,'Grid :  '+string(Teff_grid(optT),format='(I04)')+' '+string(logg_grid(optg),format='(F4.2)')+' '+string(m_h_grid(optm),format='(F6.3)')


                          ;loop over bandpasses
print,model,' 4param ',Co(0,0),Co(0,1),Co(0,2),Co(0,3)
print,' 3param ',Co(1,1),Co(1,2),Co(1,3)
print,' Quad ',Co(2,1),Co(2,3)
print,' Linear ',Co(3,1)
openw,1,'3D.limbdarkening.photonflux.'+model,/append
printf,1,model,' 4param ',Co(0,0),Co(0,1),Co(0,2),Co(0,3)
printf,1,' 3param ',Co(1,1),Co(1,2),Co(1,3)
printf,1,' Quad ',Co(2,1),Co(2,3)
printf,1,' Linear ',Co(3,1)
close,1
uLD=Co(3,1) ;Linear
c1=Co(0,0) & c2=Co(0,1) & c3=Co(0,2) & c4=Co(0,3)
cp1=0D0 & cp2=Co(1,1) & cp3=Co(1,2) & cp4=Co(1,3) ;3parameter
aLD=Co(2,1) & bLD=Co(2,3) ;quadratic
;a=strmid(header,0,25) & print,a
;if (a eq 'TEFF  50000.  GRAVITY 5.0') then goto,skipthis ;


save, filename='3D.limbdarkinging.fit.now.sav',x,y,uld,c2,c3,c4,header

                          ;loop over individual Kurucz models
skipthis: ;

                          ; loop over Kuruczmodel grids
close,1
wset,0

end