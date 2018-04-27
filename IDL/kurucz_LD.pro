pro limb_fit_kurucz_any,kdir,grating,widek,wsdata,uLD,c1,c2,c3,c4,cp1,cp2,cp3,cp4,aLD,bLD,header,k_metal,k_temp
;get numbers straigt from kurucz himself...
; rather than using synplot
; USE photon FLUX  Sum over (lambda*dlamba)
;
; version 2  -also has a model specifically for the G750M model
;            -fixed bug in how "wide" was used for the responce array, off by 2 pixels before
;            -fixed another "wide" bug and now call it "widek" so it prevents a 2 pixel shift from propogating to the next program

;window,4,xpos=80,ypos=0,xsize=500,ysize=500  ;,xpos=80,ypos=500,xsize=1250,ysize=800
;window,5,xpos=80,ypos=600,xsize=500,ysize=500 ;,xpos=1450,ypos=800,xsize=1100,ysize=700
;restore,'list.sav'
close,1

; Read config file (mainly for paths)
whereis,'W17_lightcurve_test', HST_fullpath
HST_dir = FILE_DIRNAME(HST_fullpath)

IF FILE_TEST(HST_dir + '/config_override.txt') THEN BEGIN
  structure = read_params_vm(HST_dir + '/config_override.txt')
ENDIF ELSE BEGIN
  structure = read_params_vm(HST_dir + '/config.txt')
ENDELSE

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Start code
!path = '~/IDL/pro:'+ !path
set_plot,'x'
device,RETAIN=2

;color_plot_prep, blue, cyan, red, green, black, white, $
; purple, orange, yellow

;restore,'template_kurucz.sav' ;template_kurucz,template_kurucz_header
;  template_kurucz=template

;==== Folders
limbDir = structure.LIMBDARKENING
restore, limbDir + 'templates.sav' ;template_kurucz,template_kurucz_header
# "restore" loads the file
 restore, limbDir + 'kuruczlist.sav' ;list of kurucz models  17=solar vturub=2 km/s


;==== Select Metalicity
;M_H=[-1.0(),-0.5(),-0.3(2),-0.2(1),-0.1(0),0.0(17),0.1(20),0.2(21),0.3(22),0.5(23),1.0(24)]
;  model=li(0) ;-0.1
;  model=li(1) ;-0.2
;   model=li(2) ;-0.3 k2
;  model=li(17) ; 0.0 k2 solar
;  model=li(20) ;+0.1
;  model=li(21) ;+0.2
;  model=li(22) ;+0.3 k2
;  model=li(23) ;+0.5 k2
;  model=li(24)  ;+1.0
model = li(k_metal)   # k_metal is the INDEX of M_H position instead of M_H itself
# 'li' is the only "column" in the "kuruczlist.sav" file. It cointains a list of model names,
# and k_metal tells you which one to use.
sav = readsav(os.path.join('../Limb-darkening', 'kuruczlist.sav'))
li = sav['li']
model = sav['li'][k_metal]



direc = limbDir + 'Kurucz/'


;Teff=[3500(9),3750(20),4000(31),4250(42),4500(53),4750(64),5000(75),5250(86),5500(97),5750(108),6000(119),6250(129),6500(139)]
;==== Select Teff and Log g
;N=9   ;  TEFF   3500.  GRAVITY 4.50000 M0
;N=20  ;  TEFF   3750.  GRAVITY 4.50000 K9
;N=31  ;  TEFF   4000.  GRAVITY 4.50000 K8
;N=42  ;  TEFF   4250.  GRAVITY 4.50000 K7
;N=53  ;  TEFF   4500.  GRAVITY 4.50000 K4
;N=64  ;  TEFF   4750.  GRAVITY 4.50000 K2
;N=75  ;  TEFF   5000.  GRAVITY 4.50000 K1
;N=86    ;TEFF   5250.  GRAVITY 4.50000 G9
;N=97  ;  TEFF   5500.  GRAVITY 4.50000 G6
;N=108  ;  TEFF   5750.  GRAVITY 4.50000 G3
;N=119     ;  TEFF   6000.  GRAVITY 4.50000 G0
;N=129     ;  TEFF   6250.  GRAVITY 4.50000 F8
N = k_temp   # k_temp is the INDEX of Teff position instead of Teff itself, so that we know which part
# of the model file picked via metallicity we have to look at


 # Defining some parameter, I think it tells you where the header stops and the actual data starts
st = (1221.+4)*N-N & $

# Read the header from restored file
# I don't nead the header if I don't need the Teff, logg and M_H of the used model.
  header = read_ascii(direc+model,template=template_kurucz_header,num_records=1,data_start=st) & $
;  if (header eq 0) then goto,skipthis

# Read data from restored file
# I should focus on reading the data and ignore the header for now.
  data = read_ascii(direc+model,template=template_kurucz,num_records=1221,data_start=3+st) & $
  ws = data.(0)*10   # Why like this? # need later

  # strmid cuts out a part of a string strmid(string, first_char, length)
  # double makes a double precision float
  Teff_model = double(strmid(header.(0), 6, 6))
  logg_model = double(strmid(header.(0), 21, 7))
  MH_model = double(strmid(header.(0), 43.4))

  print, N, '  ', header
;  if (abs(TEff_GTC-Teff_model) gt 500) or (abs(logg_GTC)-logg_model gt 0.5) or (abs(MH_GTC)-MH_model gt 0.2) then goto,nextmodel

;  if (ws(0) ne 90.9D0) then goto,skipthis
  print,N,st,header
  header=header.(0)
  f0=data.(1)/(ws*ws)
  f1=data.(2)*f0/100000.
  f2=data.(3)*f0/100000.
  f3=data.(4)*f0/100000.
  f4=data.(5)*f0/100000.
  f5=data.(6)*f0/100000.
  f6=data.(7)*f0/100000.
  f7=data.(8)*f0/100000.
  f8=data.(9)*f0/100000.
  f9=data.(10)*f0/100000.
  f10=data.(11)*f0/100000.
  f11=data.(12)*f0/100000.
  f12=data.(13)*f0/100000.
  f13=data.(14)*f0/100000.
  f14=data.(15)*f0/100000.
  f15=data.(16)*f0/100000.
  f16=data.(17)*f0/100000.


mu=[1.000,   .900,  .800,  .700,  .600,  .500,  .400,  .300,  .250,  .200,  .150,  .125,  .100,  .075,  .050,  .025 , .010]


mu=[1.000,   .900,  .800,  .700,  .600,  .500,  .400,  .300,  .250,  .200,  .150,  .125,  .100,  .075,  .050,  .025 , .010]


;if (grating eq 'G430L') then restore,'ihd189733p.sav' ;f1..f16,mu,ws
if (grating eq 'G750M') then restore,limbDirv+'G750L.sensitivity' ;f1..f16,mu,ws

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; +++++++++++++ This is where they're basically the same? ++++++++++++
; What I need from section that differs:
  ws
  f1, f2, ..., fn
  mu
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;=============
; HST - load responce function and interpolate onto kurucz model grid
;==============
if (grating eq 'G430L') then begin
  restore, limbDir+'G430L.sensitivity.sav';wssens,sensitivity
 G=31 & wdel=3
endif

if (grating eq 'G750L') then begin
   restore, limbDir+'G750L.sensitivity'
endif

if (grating eq 'G750M') then begin
  restore, limbDir+'G750M.sensitivity.sav';wssens,sensitivity
 G=31 & wdel=0.554
endif

if (grating eq 'R500B') then begin
  restore ,limbDir+'R500B.sensitivity.sav';wssens,sensitivity
 G=31 & wdel=3.78201D0
endif
;
;
;
;
;
; -----------------------------------------------------------------------
; WE ONLY REALLY USE THESE TWO IN THIS ROUTINE
if (grating eq 'G141') then begin ;http://www.stsci.edu/hst/acs/analysis/reference_files/synphot_tables.html
  restore, limbDir+'G141.WFC3.sensitivity.sav';wssens,sensitivity
  wdel=100
endif

if (grating eq 'G102') then begin ;http://www.stsci.edu/hst/acs/analysis/reference_files/synphot_tables.html
  restore, limbDir+'G102.WFC3.sensitivity.sav';wssens,sensitivity
  wdel=100
endif
; -----------------------------------------------------------------------
;
;
;
;
;

     ;resp=mrdfits('p822207no_pht.fits',1)  ; this file has all the Grating in it, parameter G then selects which one
     ;wsall=resp.(4) & wsHST=wssensall(*,G) & wsHST=[wsHST(0)-wdel-wdel,wsHST(0)-wdel,wsHST,wsHST(n_elements(wsHST)-1)+wdel,wsHST(n_elements(wsHST)-1)+wdel+wdel]
wsHST=wssens & wsHST=[wsHST(0)-wdel-wdel,wsHST(0)-wdel,wsHST,wsHST(n_elements(wsHST)-1)+wdel,wsHST(n_elements(wsHST)-1)+wdel+wdel]
;respoutall=resp.(5) & respoutHST=respoutall(*,G) & respoutHST=[0D0,0D0,respoutHST,0D0,0D0]
respoutHST=sensitivity/max(sensitivity) & respoutHST=[0D0,0D0,respoutHST,0D0,0D0]
linterp,wsHST,respoutHST,ws,respout  ;interpolate sensitivity curve onto model wavelength grid

wsdata=[wsdata(0)-wdel-wdel,wsdata(0)-wdel,wsdata,wsdata(n_elements(wsdata)-1)+wdel,wsdata(n_elements(wsdata)-1)+wdel+wdel] ;pad with zeros
respwavebin=wsdata/wsdata*0.0D0
widek=widek+2 ; need to add two indicies to compensate for padding with 2 zeros
respwavebin(widek)=1.0D0
linterp,wsdata,respwavebin,ws,reswavebinout  ;interpolate data onto model wavelength grid


; plot
;wset,5
;plot,ws,f0/max(f0),xrange=[wsdata(0),wsdata(n_elements(wsdata)-1)],yrange=[0,1], title='Model Kurucz spectra (white) , STIS response curve (red), & Desired Wavelength bin (green)',/xstyle,/ystyle
;oplot,ws,respout,color=1000 & oplot,ws,reswavebinout,color=321321

fcalc=[[f0],[f1],[f2],[f3],[f4],[f5],[f6],[f7],[f8],[f9],[f10],[f11],[f12],[f13],[f14],[f15],[f16]]
phot1=dblarr(17)

; integrate over the spectra to make synthetic phomometric points
for i=0,16 do begin & $ ; loop over spectra at diff angles
    fcal=fcalc(*,i) & $
    Tot=INT_TABULATED(ws,ws*respout*reswavebinout) & $
    phot1(i)=(INT_TABULATED(ws,ws*respout*reswavebinout*fcal,/sort,/double))/Tot & $
endfor



;===== fit coefficients
;set_plot,'ps'
;device,/landscape,/color
;device,file='limb_fit_kurucz_nicmos.ps'
;title='Non-linear limb-dark,  Kurucz ip00t5000g4.5k8, Black Points= model, Red=fitt coeff'
yall=[[phot1/phot1(0)]]  ;,[phot3/phot3(0)],[phot2/phot2(0)],[phot4/phot4(0)],[phot187/phot187(0)],[phot166/phot166(0)]]   # DIFF - first index in line
Co=dblarr(6,4)

;=====================================================================
for i=0,0 do begin
;=== Corot 4-parameter
A = [0.0,0.0,0.0,0.0]       ; c1,c2,c3,c4
x=mu(0:16)   # DIFF - not in python
y=yall(0:16,i)   # DIFF - not in python
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
  F =  (1. - (  a(0)*(1. - x2^(1./2.)) + $
      a(1)*(1. - x2^(2./2.)) + $
      a(2)*(1. - x2^(3./2.)) + $
      a(3)*(1. - x2^(4./2.))  )  )

;wset,4
;if (i eq 0) then plot,x,y,psym=1,xtitle='Mu',ytitle='I/Io',title='model '+header
;oplot,x2,f,color=red
;oplot,x,y,psym=1
;oplot,x2,f,color=red
;print,'Corot'
;print,a
;xyouts,0.05+1*0.15,0.35,'4-parameter'
;xyouts,0.0+1*0.15,0.3,a(0)
;xyouts,0.0+1*0.15,0.25,a(1)
;xyouts,0.0+1*0.15,0.2,a(2)
;xyouts,0.0+1*0.15,0.15,a(3)
;xyouts,0.0+1*0.15,0.05,1-total(a)
Co(0,*)=a
endfor   ;loop over bandpasses
;=====================================================================

for i=0,0 do begin
;=== Corot 3-parameter
A = [0.0,0.0,0.0,0.0]       ; c1,c2,c3,c4
x=mu(0:14)   # DIFF
y=yall(0:14,i)   # DIFF
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
;oplot,x2,f,color=red
;oplot,x,y,psym=1
;oplot,x2,f,color=red
;print,'Corot'
;print,a
;xyouts,0.05+2*0.15,0.35,'3-parameter'
;xyouts,0.0+2*0.15,0.3,a(0)
;xyouts,0.0+2*0.15,0.25,a(1)
;xyouts,0.0+2*0.15,0.2,a(2)
;xyouts,0.0+2*0.15,0.15,a(3)
;xyouts,0.0+2*0.15,0.05,1-total(a)
Co(1,*)=a
endfor   ;loop over bandpasses

;=====================================================================
;=== Corot quadratic
for i=0,0 do begin
A = [0.0,0.0,0.0,0.0]       ; c1,c2,c3,c4
x=mu(0:14)   # DIFF
y=yall(0:14,i)   # DIFF
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
;oplot,x2,f,color=123123
;print,'quadratic'
;print,a
;xyouts,0.05+3*0.15,0.35,'Quadratic'
;xyouts,0.0+3*0.15,0.3,a(0)
;xyouts,0.0+3*0.15,0.25,a(1)
;xyouts,0.0+3*0.15,0.2,a(2)
;xyouts,0.0+3*0.15,0.15,a(3)
;xyouts,0.0+3*0.15,0.05,1-total(a)
Co(2,*)=a
endfor   ;loop over bandpasses
;=====================================================================
;=== Corot linear
for i=0,0 do begin
A = [0.0,0.0,0.0,0.0]       ; c1,c2,c3,c4
x=mu(0:14)   # DIFF
y=yall(0:14,i)   # DIFF
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
;oplot,x2,f,color=321321
;print,'quadratic'
;print,a
;xyouts,0.05+4*0.15,0.35,'Linear'
;xyouts,0.0+4*0.15,0.3,a(0)
;xyouts,0.0+4*0.15,0.25,a(1)
;xyouts,0.0+4*0.15,0.2,a(2)
;xyouts,0.0+4*0.15,0.15,a(3)
;xyouts,0.0+4*0.15,0.05,1-total(a)
Co(3,*)=a
endfor

                          ;loop over bandpasses
print,model,' 4param ',Co(0,0),Co(0,1),Co(0,2),Co(0,3)
print,' 3param ',Co(1,1),Co(1,2),Co(1,3)
print,' Quad ',Co(2,1),Co(2,3)
print,' Linear ',Co(3,1)
openw,1,'Kurucz.limbdarkening.Coeff.Kepler.photonflux.'+model,/append
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


save,filename='Kurucz.limbdarkinging.fit.now.sav',x,y,uld,c2,c3,c4,header

                          ;loop over individual Kurucz models
skipthis: ;

                          ; loop over Kuruczmodel grids
close,1
wset,0

  print,N,'  ',header


end