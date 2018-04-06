
PRO G141_lightcurve_circle, x, y, err, sh, data_params, LD3D, wavelength, grid_selection, out_folder, run_name, plotting
  
 ;+
;  NAME:
;       G141_LIGHTCURVE_CIRCLE
;  
;  AUTHOR:
;     Hannah R. Wakeford,
;     stellarplanet@gmail.com
;
;  CITATIONS:
;     This procedure follows the method outlined in Wakeford, et
;     al. (2016, ApJ, 819, 1), using marginalisation across a stochastic
;     grid of models.
;     The program makes use of the analytic transit model in Mandel &
;     Agol (2002, ApJ Letters, 580, L171-175)
;     and Lavenberg-Markwardt least squares minimisation using the IDL
;     routine MPFIT (Markwardt, 2009, Book:Astronomical Data Analysis
;     Software and Systems XVIII, 411, 251, Astronomical Society of
;     the Pacific Conference Series) 
;     Here a 4-parameter limb darkening law is used as outlined in
;     Claret, 2010 and Sing et al. 2010. 
;
;  PURPOSE:
;     Perform Levenberg-Marquardt least-squares minimization across a
;     grid of stochastic systematic models to produce marginalised
;     transit parameters given a WFC3 G141 lightcurve for a specified
;     wavelength range. 
;     
;  MAJOR PROGRAMS INCLUDED IN THIS ROUTINE:
;     KURUCZ LIMB-DARKENING procedure (kurucz_limb_fit_any.pro or limb_fit_3D_choose.pro)
;                           This requires the
;                           G141.WFC3.sensitivity.sav file,
;                           template.sav, kuruczlist.sav, and the
;                           kurucz folder with all models
;     MANDEL & AGOL (2002) transit model (occultnl.pro)
;     GRID OF SYSTEMATIC MODELS for WFC3 to test against the data
;                       (wfc3_systematic_model_grid_selection.pro)
;     IMPACT PARAMETER caluclated if given an eccentricity (tap_transite2.pro)
;
;  CALLING SEQUENCE:
;                   G141_lightcurve_circle, x, y, err, sh, data_params, LD3D, wavelength, grid_selection, out_folder, run_name, plotting
;
;  INPUTS:
;     X - array of times
;
;     Y - array of normalised flux values equal to the length of the x array.
;
;     ERR - array of error values corresponding to the flux values in
;           y
;
;     SH - array corresponding to the shift in wavelength position on
;          the detector throughout the visit. (same length as x, y,
;          and err)
;
;
;     DATA_PARAMS - priors for each parameter used in the fit passed in
;                an array in the form
;                data_params = [rl,epoch,inclin,MsMpR,ecc,omega,Per,FeH,Teff,logg]
;
;                rl - transit depth  (Rp/R*)
;                epoch - center of transit time (in MJD)
;                inclin - inclination of the planetary orbit
;                MsMpR - density of the system where MsMpR =
;                        (Ms+Mp)/(R*^3D0) this can also be calculated
;                        from the a/R* following
;                        constant1 = (G*Per*Per/(4*!pi*!pi))^(1D0/3D0) 
;                        MsMpR = (a_Rs/constant1)^3D0
;                ecc - eccentricity of the system
;                omega - omega of the system (degrees)
;                Per - Period of the planet in days
;                FeH - Stellar metallicity index
;                      M_H=[-5.0(14),-4.5(13),-4.0(12),-3.5(11),-3.0(10),
;                       -2.5(9),-2.0(8),-1.5(7),-1.0(5),-0.5(3),-0.3(2),
;                       -0.2(1),-0.1(0),0.0(17),0.1(20),0.2(21),0.3(22),
;                       0.5(23),1.0(24)]
;                Teff - Stellar Temperature index
;                    FOR stellar log(g) = 4.0
;                       Teff=[3500(8),3750(19),4000(30),4250(41),4500(52),
;                       4750(63),5000(74),5250(85),5500(96),5750(107),6000(118),
;                       6250(129),6500(139)]
;                    FOR stellar log(g) = 4.5
;                       Teff=[3500(9),3750(20),4000(31),4250(42),4500(53),
;                       4750(64),5000(75),5250(86),5500(97),5750(108),6000(119),
;                       6250(129),6500(139)]
;                    FOR stellar log(g) = 5.0
;                       Teff=[3500(10),3750(21),4000(32),4250(43),4500(54),
;                       4750(65),5000(76),5250(87),5500(98),5750(109),6000(120),
;                       6250(130),6500(140)]
;    
;     WAVELENGTH: array of wavelengths covered to compute y
;
;     GRID_SELECTION: 'fix_time', 'fit_time', 'fit_inclin',
;                                'fit_msmpr', 'fit_ecc'
;
;     OUT_FOLDER: string of folder path to save the data too. 
;                 e.g. '/Volumes/DATA1/user/HST/Planet/sav_file/'
;
;     RUN_NAME - string of the individual run name
;                 e.g. 'whitelight', or 'bin1', or '115-120micron'
;
;

PRINT, 'Welcome to the Wakeford WFC3 analysis pipeline. All data will now be marginalised according to quality and usefulness. If results are not as expected - a new observation stratgy is reccomended, or you can bloody well wait for JWST to make your lives better. PRESS control+C now if this was an unintended action.'

; SET THE CONSTANTS 
;constant = [GAIN,READNOISE,G,JD,DAY_TO_SEC,Rjup,Rsun,MJup,Msun,HST_SECOND,HST_PERIOD]
  constant = [2.5,20.2,6.67259D-11,2400000.5,86400,7.15D7,6.96D8,1.9D27,1.99D30,5781.6,0.06691666]
  JD = 2400000.5D0              
  Gr = 6.67259D-11
  HSTper = 96.36D0 / (24D0*60D0)
  
; TOTAL NUMBER OF EXPOSURES IN THE OBSERVATION
nexposure = n_elements(x)
  
;;SET THE PLANET STARTING PARAMETERS
;data_params = [rl,epoch,inclin,MsMpR,ecc,omega,Per,FeH,Teff]
rl = data_params(0)
epoch = data_params(1)
inclin = data_params(2) * ((2*!pi)/360D0)
MsMpR = data_params(3)
ecc = data_params(4)
omega = data_params(5) * ((2*!pi)/360D0)
Per = data_params(6) * constant(4)
constant1 = ((constant(2)*Per*Per)/(4*!pi*!pi))^(1D0/3D0)
aval = constant1*(MsMpR)^0.33333D0

FeH = data_params(7)
Teff = data_params(8)

flux0 = y(0)
T0 = x(0)

img_date = x

; SET THE STARTING PARAMETERS FOR THE SYSTEMATICS & LD
m = 0.0D      ; Linear Slope
HSTP1 = 0.0   ; Correct HST orbital phase
HSTP2 = 0.0   ; Correct HST orbital phase^2
HSTP3 = 0.0   ; Correct HST orbital phase^3
HSTP4 = 0.0   ; Correct HST orbital phase^4
xshift1 = 0.0 ; X-shift in wavelength
xshift2 = 0.0 ; X-shift in wavelength^2
xshift3 = 0.0 ; X-shift in wavelength^3
xshift4 = 0.0 ; X-shift in wavelength^4

PRINT, 'As you have clearly decided to proceed, we will now determine the stellar limb-darkening parameters given the input stellar metallicity and effective temperature which was selected dependent on the stellar log(g).'


;......................................
;     LIMB DARKENING     ;
IF (LD3D EQ 'no') THEN BEGIN
kdir = '' 
grating = 'G141'
wsdata = wavelength
widek=indgen(n_elements(wavelength))
k_metal = data_params(6)
k_temp = data_params(7)

limb_fit_kurucz_any,kdir,grating,widek,wsdata,uLD,c1,c2,c3,c4,cp1,cp2,cp3,cp4,aLD,bLD,header,k_metal,k_temp
ENDIF


IF (LD3D eq 'yes') THEN BEGIN
grating = 'G141'
wsdata = wavelength
widek=indgen(n_elements(wavelength))
M_H = data_params(6)
Teff = data_params(7)
logg = data_params(8)

limb_fit_3D_choose,grating,widek,wsdata,uLD,c1,c2,c3,c4,cp1,cp2,cp3,cp4,aLD,bLD,header,M_H,Teff,logg
ENDIF



PRINT, 'Thank you for your patience. Next up is the lightcurve fitting with MPFIT using L-M minimization.'
;....................................
  ;PLACE ALL THE PRIORS IN AN ARRAY
p0 = [rl,flux0,epoch,inclin,msmpr,ecc,omega,per,T0,c1,c2,c3,c4,m,HSTP1,HSTP2,HSTP3,HSTP4,xshift1,xshift2,xshift3,xshift4]

; SELECT THE SYSTEMATIC GRID OF MODELS TO USE ;
selection = grid_selection
wfc3_systematic_model_grid_selection, selection, wfc3_grid
grid = TRANSPOSE(wfc3_grid)
nsys = n_elements(grid(*,0))
nparams = n_elements(grid(0,*))

;  SET UP THE ARRAYS  ;
; sav arrays for the first step throught to get the err inflation
w_scatter = DBLARR(nsys)
w_params = DBLARR(nsys,nparams)
; final sav arrays for each systematic model
; stats
sys_stats = DBLARR(nsys,5) 
; img_date
sys_date = DBLARR(nsys,nexposure)
; phase
sys_phase = DBLARR(nsys,nexposure)
; raw lightcurve flux
sys_rawflux = DBLARR(nsys,nexposure)
sys_rawflux_err = DBLARR(nsys,nexposure)
; corrected lightcurve flux
sys_flux = DBLARR(nsys,nexposure)
sys_flux_err = DBLARR(nsys,nexposure)
; residuals
sys_residuals = DBLARR(nsys,nexposure)
; smooth model
sys_model = DBLARR(nsys,4000)
; smooth phase
sys_model_phase = DBLARR(nsys,4000)
; systematic model
sys_systematic_model = DBLARR(nsys,nexposure)
; parameters
sys_params = DBLARR(nsys,nparams)
; parameter errors
sys_params_err = DBLARR(nsys,nparams)
; depth
sys_depth = DBLARR(nsys)
; depth error
sys_depth_err = DBLARR(nsys)
; transit time
sys_epoch = DBLARR(nsys)
; transit time error
sys_epoch_err = DBLARR(nsys)
; evidence AIC
sys_evidenceAIC = DBLARR(nsys)
; evidence BIC
sys_evidenceBIC = DBLARR(nsys)

;'----------      ------------     ------------'
;'          1ST FIT         '
;'----------      ------------     ------------'
PRINT,'..........................................'
PRINT, 'The first run through of the data for each of the WFC3 stochastic models outlined in Table 2 of Wakeford et al. (2016a) is now being preformed. Using this fit we will scale the uncertainties you input to incorporate the inherent scatter in the data for each model.'
FOR s = 0, n_elements(grid(*,0))-1 DO BEGIN
PRINT, '................................'
PRINT, ' SYSTEMATIC MODEL ', s
systematics = [grid(s,*)]
PRINT, TRANSPOSE(systematics)
PRINT, '  '

; - -- --- ---- --- -- - ;
;          PHASE         ;
HSTphase = DBLARR(nexposure)
HSTphase = ((img_date)-(T0))/(constant(10))                        
 phase2 = FLOOR(HSTphase)
 HSTphase = HSTphase - phase2
 k = WHERE(HSTphase GT 0.5)
 IF (k(0) NE -1) THEN HSTphase(k) = HSTphase(k) - 1.0D0

 phase = DBLARR(nexposure) 
FOR j = 0, nexposure-1 DO phase(j) = ((img_date(j))-(epoch))/(Per/constant(4)) 
 phase2 = FLOOR(phase)
 phase = phase - phase2
 a = WHERE(phase GT 0.5)
 IF (a(0) NE -1) THEN phase(a) = phase(a) - 1.0D0


;      MPFIT - ONE       ;
 p0 = [rl,flux0,epoch,inclin,msmpr,ecc,omega,per,T0,c1,c2,c3,c4,m,HSTP1,HSTP2,HSTP3,HSTP4,xshift1,xshift2,xshift3,xshift4]

fa = {X:x, Y:y, ERR:err, SH:sh}
parinfo = REPLICATE({value:0.D, fixed:0, limited:[0,0], limits:[0.D,0]}, N_ELEMENTS(p0))

  parinfo[*].value= p0
  parinfo[*].fixed = 1
  parinfo[*].fixed = TRANSPOSE(systematics) 
; ==  Comment out the following to fit fot the parameter    == ;
    ;parinfo[0].fixed = 1          ; Radius Ratio
    ;parinfo[1].fixed = 1          ; Baseline stellar flux level
    ;parinfo[2].fixed = 1          ; Center of transit time
    ;parinfo[3].fixed = 1          ; Inclination
    ;parinfo[4].fixed = 1          ; MsMpR
    ;parinfo[5].fixed = 1          ; Eccentricity
    ;parinfo[6].fixed = 1          ; Omega
    ;parinfo[7].fixed = 1          ; Orbital preiod
    ;parinfo[8].fixed = 1          ; HST T0 phase
    ;parinfo[9].fixed = 1          ; Limb-darkening parameter c1
    ;parinfo[10].fixed = 1         ; Limb-darkening parameter c2
    ;parinfo[11].fixed = 1         ; Limb-darkening parameter c3
    ;parinfo[12].fixed = 1         ; Limb-darkening parameter c4
  
    ;parinfo[13].fixed = 1         ; Linear slope in time
    ;parinfo[14].fixed = 1         ; Linear HST phase
    ;parinfo[15].fixed = 1         ; HST phase^2
    ;parinfo[16].fixed = 1         ; HST phase^3
    ;parinfo[17].fixed = 1         ; HST phase^4
    ;parinfo[18].fixed = 1         ; Linear shift in wavelength
    ;parinfo[19].fixed = 1         ; Shift in wavelength^2
    ;parinfo[20].fixed = 1         ; Shift in wavelength^3
    ;parinfo[21].fixed = 1         ; Shift in wavelength^4

  params_w = MPFIT('transit_circle',functargs=fa,BESTNORM=bestnorm,COVAR=covar,PERROR=perror,PARINFO=parinfo,niter=niter,maxiter=maxiter,status=status,Nfree=nfree)
  pcerror = perror

  ;END MPFIT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; FROM MPFIT DEFINE THE DOF, BIC, AIC, & CHI  
BIC = bestnorm + nfree*ALOG(n_elements(x))
AIC = bestnorm + nfree
DOF = n_elements(X) - n_elements(WHERE(parinfo.fixed NE 1)) ;nfree
CHI = bestnorm

;...........................................
; Redefine all of the parameters given the MPFIT output
w_params(s,*) = params_w

rl = params_w(0) & rl_err = pcerror(0)
flux0 = params_w(1) & flux0_err = pcerror(1)
epoch = params_w(2) & epoch_err = pcerror(2)
inclin = params_w(3) & inclin_err = pcerror(3)
msmpr = params_w(4) & msmpr_err = pcerror(4)
ecc = params_w(5) & ecc_err = pcerror(5)
omega = params_w(6) & omega_err = pcerror(6)
per = params_w(7) & per_err = pcerror(7)
T0 = params_w(8) & t0_err = pcerror(8)
c1 = params_w(9) & c1_err = pcerror(9)
c2 = params_w(10) & c2_err = pcerror(10)
c3 = params_w(11) & c3_err = pcerror(11)
c4 = params_w(12) & c4_err = pcerror(12)

m = params_w(13) & m_err = pcerror(13)
hst1 = params_w(14) & hst1_err = pcerror(14)
hst2 = params_w(15) & hst2_err = pcerror(15)
hst3 = params_w(16) & hst3_err = pcerror(16)
hst4 = params_w(17) & hst4_err = pcerror(17)
sh1 = params_w(18) & sh1_err = pcerror(18)
sh2 = params_w(19) & sh2_err = pcerror(19)
sh3 = params_w(20) & sh3_err = pcerror(20)
sh4 = params_w(21) & sh4_err = pcerror(21)

;Recalculate a/R*
constant1 = (constant(2)*Per*Per/(4*!pi*!pi))^(1D0/3D0)
aval = constant1*(MsMpR)^0.33333D0

;.......................................
PRINT, 'Transit depth = ', rl, ' +/- ', rl_err, '     centered at  ', epoch
;.......................................

; OUTPUTS
; Re-Calculate each of the arrays dependent on the output parameters
phase = ((x)-(epoch))/(Per/86400D0) 
 phase2 = FLOOR(phase)
 phase = phase - phase2
 a = WHERE(phase GT 0.5)
 IF (a(0) NE -1) THEN phase(a) = phase(a) - 1.0D0

HSTphase = ((x)-(T0))/(constant(10))                        
 phase2 = FLOOR(HSTphase)
 HSTphase = HSTphase - phase2
 k = WHERE(HSTphase GT 0.5)
 IF (k(0) NE -1) THEN HSTphase(k) = HSTphase(k) - 1.0D0

;...........................................
; TRANSIT MODEL fit to the data
;Calculate the impact parameter based on the eccentricity function
b0 = (Gr*Per*Per/(4*!pi*!pi))^(1D0/3D0) * (msmpr^(1D0/3D0)) * [(sin(phase*2*!pi))^2D0 + (cos(inclin)*cos(phase*2*!pi))^(2D0)]^(0.5D0)


                                ;Use the MANDEL & AGOL (2002) analytic
                                ;transit function to get the model
                                ;lightcurve
plotquery = 0
occultnl, rl, c1, c2,c3, c4, b0, mulimb01, mulimbf1, plotquery
b01=b0
;...........................................

systematic_model = (phase*m + 1.0) * (HSTphase*hst1 + HSTphase^2.*hst2 + HSTphase^3.*hst3 + HSTphase^4.*hst4 + 1.0) * (sh*sh1 + sh^2.*sh2 + sh^3.*sh3 + sh^4.*sh4 + 1.0)

w_model = mulimb01 * flux0 * systematic_model

w_residuals = (y - w_model)/flux0

corrected_data = y / (flux0 * systematic_model)

w_scatter(s) = (STDDEV(w_residuals))
print, 'Scatter on the residuals = ', w_scatter(s)




;..........................................
;..........................................
; CHOPPING OUT THE BAD PARTS
;..........................................

cut_down = 2.57 ; Play around with this value if you want. 
; This currently just takes the data that is not good and replaces it with a null value while inflating the uncertainty using the standard deviation, although this is only a very timy inflation of the uncertainty and I need to find a more statistically riggrous way to do this. 
; Ultimately, I would like it to remove the point completely and reformat the x, y, err and sh arrays to account for the new shape of the array.

IF (plotting EQ 'on') THEN BEGIN
window,0, title=s
plot, phase, w_residuals, psym=4, ystyle=3, xstyle=3, yrange=[-0.01,0.01]
hline, 0.0+STDDEV(w_residuals)*cut_down, color=cgcolor('RED') 
hline, 0.0
hline, 0.0-STDDEV(w_residuals)*cut_down, color=cgcolor('RED') 
ENDIF


;remove
bad_up = where(w_residuals GT (0.0+STDDEV(w_residuals)*3) )
bad_down = where(w_residuals LT (0.0-STDDEV(w_residuals)*3) )

print, 'up', bad_up
print, 'down', bad_down

lon = n_elements(bad_up)
FOR i = 0, lon-1 DO BEGIN
IF (bad_up(i) GT -1) THEN BEGIN
 y(bad_up(i)) = y(bad_up(i))-STDDEV(w_residuals)*cut_down
 err(bad_up(i)) = err(bad_up(i))*(1+STDDEV(w_residuals))
ENDIF
ENDFOR

lon = n_elements(bad_down)
FOR i = 0, lon-1 DO BEGIN
IF (bad_down(i) GT -1) THEN BEGIN
 y(bad_down(i)) = y(bad_down(i))+STDDEV(w_residuals)*cut_down
 err(bad_down(i)) = err(bad_down(i))*(1+STDDEV(w_residuals))
ENDIF
ENDFOR



;remove
bad_up = where(w_residuals GT (0.0+STDDEV(w_residuals)*cut_down) )
bad_down = where(w_residuals LT (0.0-STDDEV(w_residuals)*cut_down) )

print, 'up', bad_up
print, 'down', bad_down

lon = n_elements(bad_up)
FOR i = 0, lon-1 DO BEGIN
IF (bad_up(i) GT -1) THEN BEGIN
 y(bad_up(i)) = y(bad_up(i))-STDDEV(w_residuals)*cut_down
 err(bad_up(i)) = err(bad_up(i))*(1+STDDEV(w_residuals))
ENDIF
ENDFOR

lon = n_elements(bad_down)
FOR i = 0, lon-1 DO BEGIN
IF (bad_down(i) GT -1) THEN BEGIN
 y(bad_down(i)) = y(bad_down(i))+STDDEV(w_residuals)*cut_down
 err(bad_down(i)) = err(bad_down(i))*(1+STDDEV(w_residuals))
ENDIF
ENDFOR


IF (plotting EQ 'on') THEN BEGIN
window,2, title=s
plot, phase, corrected_data, ystyle=3, xstyle=3, psym=4
oplot, phase, y, psym=1
oploterror, phase, corrected_data, err, psym=4, color=321321
oplot, phase, systematic_model, color=5005005, psym=2
ENDIF



ENDFOR





;..........................................
;..........................................
; SECOND RUN THROUGH with MPFIT
;..........................................
PRINT,'..........................................'
PRINT, 'As we seem to have found how shit each of the systematic models are at fitting the data compared to a Mandel&Agol transit model we can now use the scatter on their residuals to inflate the uncertainties for the data. We will then go ahead and refit for each systematic model if that is okay with you. If not control+c is still a valid option.'
FOR s = 0, n_elements(grid(*,0))-1 DO BEGIN
PRINT, '................................'
PRINT, ' SYSTEMATIC MODEL ', s
systematics = [grid(s,*)]
PRINT, TRANSPOSE(systematics)
PRINT, '  '

x = x
y = y
err = err*(1.0 - (w_scatter(s)))


p0 = w_params(s,*)
                                ;[rl,flux0,epoch,inclin,msmpr,ecc,omega,per,T0,c1,c2,c3,c4,m,HSTP1,HSTP2,HSTP3,HSTP4,xshift1,xshift2,xshift3,xshift4]

T0 = p0(8)
epoch = p0(2)
Per = p0(7)

; - -- --- ---- --- -- - ;
;          PHASE         ;
HSTphase = DBLARR(nexposure)
HSTphase = ((x)-(T0))/(constant(10))                        
 phase2 = FLOOR(HSTphase)
 HSTphase = HSTphase - phase2
 k = WHERE(HSTphase GT 0.5)
 IF (k(0) NE -1) THEN HSTphase(k) = HSTphase(k) - 1.0D0

 phase = DBLARR(nexposure) 
FOR j = 0, nexposure-1 DO phase(j) = ((x(j))-(epoch))/(Per/constant(4)) 
 phase2 = FLOOR(phase)
 phase = phase - phase2
 a = WHERE(phase GT 0.5)
 IF (a(0) NE -1) THEN phase(a) = phase(a) - 1.0D0

 p0 = TRANSPOSE(p0)

;      MPFIT - TWO       ;
fa = {X:x, Y:y, ERR:err, SH:sh}
parinfo = REPLICATE({value:0.D, fixed:0, limited:[0,0], limits:[0.D,0]}, N_ELEMENTS(p0))

  parinfo[*].value= p0
  parinfo[*].fixed = 1
  parinfo[*].fixed = TRANSPOSE(systematics) 
; ==  Comment out the following to fit fot the parameter    == ;
    ;parinfo[0].fixed = 1          ; Radius Ratio
    ;parinfo[1].fixed = 1          ; Baseline stellar flux level
    ;parinfo[2].fixed = 1          ; Center of transit time
    ;parinfo[3].fixed = 1          ; Inclination
    ;parinfo[4].fixed = 1          ; MsMpR
    ;parinfo[5].fixed = 1          ; Eccentricity
    ;parinfo[6].fixed = 1          ; Omega
    ;parinfo[7].fixed = 1          ; Orbital preiod
    ;parinfo[8].fixed = 1          ; HST T0 phase
    ;parinfo[9].fixed = 1          ; Limb-darkening parameter c1
    ;parinfo[10].fixed = 1         ; Limb-darkening parameter c2
    ;parinfo[11].fixed = 1         ; Limb-darkening parameter c3
    ;parinfo[12].fixed = 1         ; Limb-darkening parameter c4
  
    ;parinfo[13].fixed = 1         ; Linear slope in time
    ;parinfo[14].fixed = 1         ; Linear HST phase
    ;parinfo[15].fixed = 1         ; HST phase^2
    ;parinfo[16].fixed = 1         ; HST phase^3
    ;parinfo[17].fixed = 1         ; HST phase^4
    ;parinfo[18].fixed = 1         ; Linear shift in wavelength
    ;parinfo[19].fixed = 1         ; Shift in wavelength^2
    ;parinfo[20].fixed = 1         ; Shift in wavelength^3
    ;parinfo[21].fixed = 1         ; Shift in wavelength^4

  params = MPFIT('transit_circle',functargs=fa,BESTNORM=bestnorm,COVAR=covar,PERROR=perror,PARINFO=parinfo,niter=niter,maxiter=maxiter,status=status,Nfree=nfree)
  pcerror = perror

  ;END MPFIT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; FROM MPFIT DEFINE THE DOF, BIC, AIC, & CHI  
BIC = bestnorm + nfree*ALOG(n_elements(x))
AIC = bestnorm + nfree
DOF = n_elements(X) - n_elements(WHERE(parinfo.fixed NE 1)) ;nfree
CHI = bestnorm

; EVIDENCE BASED on the AIC and BIC
Mpoint = n_elements(WHERE(parinfo.fixed NE 1))
Npoint = n_elements(X)
sigma_points = MEDIAN(err)

evidence_BIC = -Npoint*ALOG(sigma_points) -0.5*Npoint*ALOG(2*!pi) -0.5*BIC
evidence_AIC = -Npoint*ALOG(sigma_points) -0.5*Npoint*ALOG(2*!pi) -0.5*AIC
;.............................................

;...........................................
; Redefine all of the parameters given the MPFIT output
rl = params(0) & rl_err = pcerror(0)/2.
flux0 = params(1) & flux0_err = pcerror(1)
epoch = params(2) & epoch_err = pcerror(2)
inclin = params(3) & inclin_err = pcerror(3)
msmpr = params(4) & msmpr_err = pcerror(4)
ecc = params(5) & ecc_err = pcerror(5)
omega = params(6) & omega_err = pcerror(6)
per = params(7) & per_err = pcerror(7)
T0 = params(8) & t0_err = pcerror(8)
c1 = params(9) & c1_err = pcerror(9)
c2 = params(10) & c2_err = pcerror(10)
c3 = params(11) & c3_err = pcerror(11)
c4 = params(12) & c4_err = pcerror(12)

m = params(13) & m_err = pcerror(13)
hst1 = params(14) & hst1_err = pcerror(14)
hst2 = params(15) & hst2_err = pcerror(15)
hst3 = params(16) & hst3_err = pcerror(16)
hst4 = params(17) & hst4_err = pcerror(17)
sh1 = params(18) & sh1_err = pcerror(18)
sh2 = params(19) & sh2_err = pcerror(19)
sh3 = params(20) & sh3_err = pcerror(20)
sh4 = params(21) & sh4_err = pcerror(21)

;Recalculate a/R*
constant1 = (constant(2)*Per*Per/(4*!pi*!pi))^(1D0/3D0)
aval = constant1*(MsMpR)^0.33333D0

;............................................
PRINT, 'Transit depth = ', rl, ' +/- ', rl_err, '     centered at  ', epoch
;............................................

; OUTPUTS
; Re-Calculate each of the arrays dependent on the output parameters
phase = ((x)-(epoch))/(Per/86400D0) 
 phase2 = FLOOR(phase)
 phase = phase - phase2
 a = WHERE(phase GT 0.5)
 IF (a(0) NE -1) THEN phase(a) = phase(a) - 1.0D0

HSTphase = ((x)-(T0))/(constant(10))                        
 phase2 = FLOOR(HSTphase)
 HSTphase = HSTphase - phase2
 k = WHERE(HSTphase GT 0.5)
 IF (k(0) NE -1) THEN HSTphase(k) = HSTphase(k) - 1.0D0
 
;...........................................
; TRANSIT MODEL fit to the data
;Calculate the impact parameter based on the eccentricity function
b0 = (Gr*Per*Per/(4*!pi*!pi))^(1D0/3D0) * (msmpr^(1D0/3D0)) * [(sin(phase*2*!pi))^2D0 + (cos(inclin)*cos(phase*2*!pi))^(2D0)]^(0.5D0)


                                ;Use the MANDEL & AGOL (2002) analytic
                                ;transit function to get the model
                                ;lightcurve
plotquery = 0
occultnl, rl, c1, c2,c3, c4, b0, mulimb01, mulimbf1, plotquery
b01=b0
;...........................................


;...........................................
; SMOOTH TRANSIT MODEL across all phase
;Calculate the impact parameter based on the eccentricity function
x2 = FINDGEN(4000)*0.0001-0.2

b0 = (Gr*Per*Per/(4*!pi*!pi))^(1D0/3D0) * (msmpr^(1D0/3D0)) * [(sin(x2*2*!pi))^2D0 + (cos(inclin)*cos(x2*2*!pi))^(2D0)]^(0.5D0)


                                ;Use the MANDEL & AGOL (2002) analytic
                                ;transit function to get the model
                                ;lightcurve
plotquery = 0
occultnl, rl, c1, c2,c3, c4, b0, mulimb02, mulimbf2, plotquery
b02=b0
;...........................................

systematic_model = (phase*m + 1.0) * (HSTphase*hst1 + HSTphase^2.*hst2 + HSTphase^3.*hst3 + HSTphase^4.*hst4 + 1.0) * (sh*sh1 + sh^2.*sh2 + sh^3.*sh3 + sh^4.*sh4 + 1.0)

fit_model = mulimb01 * flux0 * systematic_model

residuals = (y - fit_model)/flux0
resid_scatter = STDDEV(residuals)

fit_data = y / (flux0 * systematic_model)
fit_err = err ;* (1.0 + resid_scatter)

IF (plotting EQ 'on') THEN BEGIN
window,2, title=s
plot, phase, y, ystyle=3, xstyle=3, psym=1
oplot, x2, mulimb02, color=5005005
oploterror, phase, fit_data, err, psym=4, color=100100100
ENDIF
;.............................
; Arrays to save to file

; stats
sys_stats(s,*) = [AIC, BIC, DOF, CHI, resid_scatter] 
; img_date
sys_date(s,*) = x
; phase
sys_phase(s,*) = phase
; raw lightcurve flux
;sys_rawflux(s,*) = y
;sys_rawflux_err(s,*) = err
; corrected lightcurve flux
sys_flux(s,*) = fit_data
sys_flux_err(s,*) = fit_err
; residuals
sys_residuals(s,*) = residuals
; smooth model
sys_model(s,*) = mulimb02
; smooth phase
sys_model_phase(s,*) = x2
; systematic model
sys_systematic_model(s,*) = systematic_model
; parameters
sys_params(s,*) = params
; parameter errors
sys_params_err(s,*) = pcerror
; depth
sys_depth(s) = rl
; depth error
sys_depth_err(s) = rl_err
; transit time
sys_epoch(s) = epoch
; transit time error
sys_epoch_err(s) = epoch_err
; evidence AIC
sys_evidenceAIC(s) = evidence_AIC
; evidence BIC
sys_evidenceBIC(s) = evidence_BIC

ENDFOR

SAVE, filename=out_folder+'analysis_circle_G141_'+run_name+'.sav', sys_stats, sys_date, sys_phase, sys_rawflux, sys_rawflux_err, sys_flux, sys_flux_err, sys_residuals, sys_model, sys_model_phase, sys_systematic_model, sys_params, sys_params_err, sys_depth, sys_depth_err, sys_epoch, sys_epoch_err, sys_evidenceAIC, sys_evidenceBIC




;.......................................
; MARGINALISATION
a = REVERSE(SORT(sys_evidenceAIC))
PRINT, 'TOP 10 SYSTEMATIC MODELS'
PRINT, a[0:9]

print, sys_evidenceAIC
; REFORMAT all arrays with just positive values
pos = WHERE(sys_evidenceAIC GT -500)
npos = n_elements(pos)
print, 'POS positions = ', pos

count_AIC = sys_evidenceAIC(pos)

count_depth = sys_depth(pos)
count_depth_err = sys_depth_err(pos)

count_epoch = sys_epoch(pos)
count_epoch_err = sys_epoch_err(pos)

count_residuals = sys_residuals(pos,*)
count_date = sys_date(pos,*)
count_flux = sys_flux(pos,*)
count_flux_err = sys_flux_err(pos,*)
count_phase = sys_phase(pos,*)
count_model_y = sys_model(pos,*)
count_model_x = sys_model_phase(pos,*)

beta = MIN(count_AIC)
w_q = (EXP(count_AIC - beta))/TOTAL(EXP(count_AIC - beta))


n01 = WHERE(w_q GE 0.05)
  print,string(n_elements(n01),format='(I2)')+' models have a weight over 0.1. Models:',n01, w_q(n01)
  print,'Most likely model is number '+string(where(w_q eq max(w_q)),format='(I2)')+' at w_q=',string(w_q(where(w_q eq max(w_q))),format='(f4.2)')

  best_sys = MAX(w_q)

rl_sdnr = DBLARR(n_elements(w_q)) & FOR i = 0, n_elements(w_q)-1 DO rl_sdnr(i) = (STDDEV(count_residuals(i,*))/SQRT(2))*1D6
best_sys =  WHERE(rl_sdnr EQ min(rl_sdnr))


; Radius ratio
rl_array = count_depth
rl_err_array = count_depth_err

  mean_rl = TOTAL(w_q*rl_array,/double)
  bestfit_theta_rlq = rl_array
  variance_theta_rlq = rl_err_array
  variance_theta_rl = SQRT(total(w_q * [(bestfit_theta_rlq - mean_rl)^2D0 + (variance_theta_rlq)^2D0], /DOUBLE))
  print,'Rp/R* = ', string(mean_rl,format='(f17.7)'),' +/- ',string(variance_theta_rl,format='(f17.7)')

marg_rl = mean_rl
marg_rl_err = variance_theta_rl

print, marg_rl, marg_rl_err
print, 'SDNR best model = ', (STDDEV(count_residuals(best_sys,*))/SQRT(2))*1D6

print, 'SDNR best = ', min(rl_sdnr), ' for model ', WHERE(rl_sdnr EQ min(rl_sdnr))

;IF (plotting EQ 'on') THEN BEGIN
   window,4
!p.multi=[0,1,3]
   plot, w_q
   plot, rl_sdnr
   ploterror, rl_array, rl_err_array
!p.multi=[0,1,1]   

window,6
!p.multi=[0,1,3]
plot, sys_phase(0,*), sys_flux(0,*), psym=4, ystyle=3, yrange=[min(sys_flux(0,*))-0.001,max(sys_flux(0,*))+0.001], background=cgcolor('white'), color=cgcolor('black')

plot, count_phase(best_sys,*), count_flux(best_sys,*), psym=4, ystyle=3, yrange=[min(count_flux(0,*))-0.001,max(count_flux(0,*))+0.001], background=cgcolor('white'), color=cgcolor('black')
oplot, count_model_x(best_sys,*), count_model_y(best_sys,*), color=cgcolor('red')

ploterror, count_phase(best_sys,*), count_residuals(best_sys,*)*1d6, count_flux_err(best_sys,*)*1d6, psym=4, ystyle=3, yrange=[-1000,1000], background=cgcolor('white'), color=cgcolor('black')
hline, 0.0, linestyle=2, color=cgcolor('red')
hline, 0.0-(rl_sdnr(best_sys)*2.57), linestyle=1, color=cgcolor('red')
hline, 0.0+(rl_sdnr(best_sys)*2.57), linestyle=1, color=cgcolor('red')
!p.multi=[0,1,1]   

print, MEDIAN(count_flux_err(best_sys,*)*1d6)
;ENDIF


; Center of transit time
epoch_array = count_epoch
epoch_err_array = count_epoch_err

  mean_epoch = TOTAL(w_q*epoch_array)
  bestfit_theta_epoch = epoch_array
  variance_theta_epochq = epoch_err_array
  variance_theta_epoch = SQRT(total(w_q * [(bestfit_theta_epoch - mean_epoch)^2D0 + (variance_theta_epochq)^2D0], /DOUBLE))
  print,'Epoch = ', string(mean_epoch,format='(f17.9)'),' +/- ',string(variance_theta_epoch,format='(f7.5)')

  marg_epoch = mean_epoch
  marg_epoch_err = variance_theta_epoch
  print, marg_epoch, marg_epoch_err
  
; Inclination
inclin_array = sys_params(*,3)
inclin_err_array = sys_params_err(*,3)

  mean_inc = TOTAL(w_q * inclin_array)
  bestfit_theta_inc = inclin_array
  variance_theta_incq = inclin_err_array
  variance_theta_inc = TOTAL(w_q * ((bestfit_theta_inc - mean_inc)^2D0 + variance_theta_incq))
  print,'inc (rads) = ', string(mean_inc,format='(f17.9)'),' +/- ',string(variance_theta_inc,format='(f17.9)')

    marg_inclin_rad = mean_inc
    marg_inclin_rad_err = variance_theta_inc
        print, marg_inclin_rad, marg_inclin_rad_err

inclin_arrayd = sys_params(*,3)/(2*!pi/360D0)
inclin_err_arrayd = sys_params_err(*,3)/(2*!pi/360D0)

  mean_incd = TOTAL(w_q * inclin_arrayd)
  bestfit_theta_incd = inclin_arrayd
  variance_theta_incdq = inclin_err_arrayd
  variance_theta_incd = TOTAL(w_q * ((bestfit_theta_incd - mean_incd)^2D0 + variance_theta_incdq))
  print,'inc (deg) = ', string(mean_incd,format='(f17.9)'),' +/- ',string(variance_theta_incd,format='(f17.9)')
  
    marg_inclin_deg = mean_incd
    marg_inclin_deg_err = variance_theta_incd
        print, marg_inclin_deg, marg_inclin_rad_err

; MsMpR
msmpr_array = sys_params(*,4)
msmpr_err_array = sys_params_err(*,4)

  mean_msmpr = TOTAL(w_q*msmpr_array)
  bestfit_theta_msmpr = msmpr_array
  variance_theta_msmprq = msmpr_err_array
  variance_theta_msmpr = TOTAL(w_q * ((bestfit_theta_msmpr - mean_msmpr)^2.0 + variance_theta_msmprq))
  print,'MsMpR = ', string(mean_msmpr,format='(f17.9)'),' +/- ',string(variance_theta_msmpr,format='(f17.9)')
mean_aor = constant1*((mean_msmpr)^0.333D0)
variance_theta_aor = constant1*((variance_theta_msmpr)^0.3333D0)/mean_aor
  print,'a/R* = ', string(mean_aor,format='(f17.9)'),' +/- ',string(variance_theta_aor,format='(f17.9)')

  marg_msmpr = mean_msmpr
  marg_msmpr_err = variance_theta_msmpr
  print, marg_msmpr, marg_msmpr_err
  
  marg_aors = mean_aor
  marg_aors_err = variance_theta_aor
  print, marg_aors, marg_aors_err

SAVE, filename=out_folder+'analysis_circle_G141_marginalised_'+run_name+'.sav', w_q, best_sys, marg_rl, marg_rl_err, marg_epoch, marg_epoch_err, marg_inclin_rad, marg_inclin_rad_err, marg_inclin_deg, marg_inclin_deg_err, marg_msmpr, marg_msmpr_err, marg_aors, marg_aors_err, rl_sdnr, pos 


set_plot, 'x'
END




; TRANSIT FUNCTION
FUNCTION transit_circle, p, X=x, Y=y, ERR=err, SH=sh

; SET THE CONSTANTS 
;constant = [GAIN,READNOISE,G,JD,DAY_TO_SEC,Rjup,Rsun,MJup,Msun,HST_SECOND,HST_PERIOD]
  constant = [2.5,20.2,6.67259D-11,2400000.5,86400,7.15D7,6.96D8,1.9D27,1.99D30,5781.6,0.06691666]

;p0 = [rl,flux0,epoch,inclin,MsMpR,ecc,omega,Per,T0,c1,c2,c3,c4,m,HSTP1,HSTP2,HSTP3,HSTP4,xshift1,xshift2,xshift3,xshift4]
    ;parinfo[0].fixed = 1          ; Radius Ratio
    ;parinfo[1].fixed = 1          ; Baseline stellar flux level
    ;parinfo[2].fixed = 1          ; Center of transit time
    ;parinfo[3].fixed = 1          ; Inclination
    ;parinfo[4].fixed = 1          ; MsMpR
    ;parinfo[5].fixed = 1          ; Eccentricity
    ;parinfo[6].fixed = 1          ; Omega
    ;parinfo[7].fixed = 1          ; Orbital preiod
    ;parinfo[8].fixed = 1          ; HST T0 phase
    ;parinfo[9].fixed = 1          ; Limb-darkening parameter c1
    ;parinfo[10].fixed = 1         ; Limb-darkening parameter c2
    ;parinfo[11].fixed = 1         ; Limb-darkening parameter c3
    ;parinfo[12].fixed = 1         ; Limb-darkening parameter c4
  
    ;parinfo[13].fixed = 1         ; Linear slope in time
    ;parinfo[14].fixed = 1         ; Linear HST phase
    ;parinfo[15].fixed = 1         ; HST phase^2
    ;parinfo[16].fixed = 1         ; HST phase^3
    ;parinfo[17].fixed = 1         ; HST phase^4
    ;parinfo[18].fixed = 1         ; Linear shift in wavelength
    ;parinfo[19].fixed = 1         ; Shift in wavelength^2
    ;parinfo[20].fixed = 1         ; Shift in wavelength^3
    ;parinfo[21].fixed = 1         ; Shift in wavelength^4

  JD = 2400000.5D0              
  Gr = 6.67259D-11
  HSTper = 96.36D0 / (24D0*60D0)    

  rl = p(0)
  epoch = p(2)
  inclin = p(3)
  ecc = p(5)
  omega = p(6)
  Per = p(7)   
  T0 = p(8)
  c1 = p(9)
  c2 = p(10)
  c3 = p(11)
  c4 = p(12)

  MsMpR = p(4)
    constant1 = (constant(2)*Per*Per/(4*!pi*!pi))^(1D0/3D0) 
    aval = constant1*(msmpr)^0.333D0
    
  phase = ((X)-epoch)/(Per/86400D0) ;convert to days
  phase2 = FLOOR(phase)
  phase = phase - phase2
    a = WHERE(phase GT 0.5)
   IF (a(0) NE -1) THEN phase(a) = phase(a)-1.0D0
  PRINT, 'phase(0) =', phase(0)

  HSTphase = ((X)-(T0))/(HSTper) ;convert to days
  phase2 = FLOOR(HSTphase)
  HSTphase = HSTphase - phase2
    k = WHERE(HSTphase GT 0.5)
    IF (k(0) NE -1) THEN HSTphase(k) = HSTphase(k) - 1.0D0


      b0 = (Gr*Per*Per/(4*!pi*!pi))^(1D0/3D0) * (msmpr^(1D0/3D0)) * [(sin(phase*2*!pi))^2D0 + (cos(inclin)*cos(phase*2*!pi))^(2D0)]^(0.5D0)

 plotquery = 0

  occultnl,rl,c1,c2,c3,c4,b0,mulimb0,mulimbf,plotquery,_extra=e

systematic_model = (phase*p(13) + 1.0) * (HSTphase*p(14) + HSTphase^2.*p(15) + HSTphase^3.*p(16) + HSTphase^4.*p(17) + 1.0) * (sh*p(18) + sh^2.*p(19) + sh^3.*p(20) + sh^4.*p(21) + 1.0)

;model fit to data = transit model * baseline flux * systematic model
  model = mulimb0 * p(1) * systematic_model 

print, 'Rp/R* = ', p(0)
;  plot,phase,y,/ystyle,psym=4, yrange=[min(y)-0.0001,max(y)+0.0001]
;  oplot,phase,model,psym=-2,color=1000
;  oplot, phase, mulimb0
  
resids = (y-model)/p(1)

print, 'Scatter = ', STDDEV(resids)
print, '-----------------------------------'
print, ' '

  RETURN, (y-model)/err
END





; SYSTEMATIC MODEL GRID
 ;+
; SYSTEMATIC GRID
;
;
;
PRO wfc3_systematic_model_grid_selection, selection, wfc3_grid

; MODEL GRID UPTO THE 4th ORDER for HST & DELTA_lambda, with linear T

;p0 = [flux0,rl,epoch,inclin,msmpr,ecc,omega,per,T0,c1,c2,c3,c4,m,HSTP1,HSTP2,HSTP3,HSTP4,xshift1,xshift2,xshift3,xshift4]
;0 means free to fit
;1 means closed and not fit

;selection = 'fix_time', 'fit_time' , 'fit_inclin', 'fit_msmpr', 'fit_ecc'

;.........................................................
; FIX TIME
;.........................................................
IF (selection EQ 'fix_time') THEN BEGIN
grid_WFC3_fix_time = FLTARR(50,22)
grid_WFC3_fix_time =[[0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],$
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],$
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],$ 
[0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]]

wfc3_grid = grid_WFC3_fix_time
ENDIF
;.........................................................




;.........................................................
; FIT for TIME
;.........................................................
IF (selection EQ 'fit_time') THEN BEGIN
grid_WFC3_fit_time = FLTARR(50,22)
grid_WFC3_fit_time =[[0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],$
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],$
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],$ 
[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]]

wfc3_grid = grid_WFC3_fit_time
ENDIF
;.........................................................




;.........................................................
; FIT for INCLINATION
;.........................................................
IF (selection EQ 'fit_inclin') THEN BEGIN
grid_WFC3_fit_inclin = FLTARR(50,22)
grid_WFC3_fit_inclin =[[0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],$
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],$
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],$ 
[0,0,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]]

wfc3_grid = grid_WFC3_fit_inclin
ENDIF
;.........................................................





;.........................................................
; FIT for MsMpR
;.........................................................
IF (selection EQ 'fit_msmpr') THEN BEGIN
grid_WFC3_fit_msmpr = FLTARR(50,22)
grid_WFC3_fit_msmpr =[[0,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],$
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],$
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],$ 
[0,0,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]]

wfc3_grid = grid_WFC3_fit_msmpr
ENDIF
;.........................................................



IF (selection EQ 'fit_all') THEN BEGIN
grid_WFC3_fit_all = FLTARR(50,22)
grid_WFC3_fit_all =[[0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],$
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],$
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],$ 
[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]]
wfc3_grid = grid_WFC3_fit_all
ENDIF
;.........................................................

;.........................................................
; FIT for ECCENTRICITY
;.........................................................
IF (selection EQ 'fit_ecc') THEN BEGIN
grid_WFC3_fit_ecc = FLTARR(50,22)
grid_WFC3_fit_ecc =[[0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],$
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,0,0,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,0],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,0,0,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,0,0,0,0],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,0,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,1,0,0,0,0],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,0,0,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0],$
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,1,1,1,0,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,1,1,1,0,0,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,1,1,0,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,1,1,0,0,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],$ 
[0,0,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0]]

wfc3_grid = grid_WFC3_fit_ecc
ENDIF
;.........................................................


RETURN
END









;
;
;
;
;
;
;-----------------------------------------------------------
; LIMB_DARKEING TIME!
; In both of these limb-darkening routines it is possible that a lot can be trimmed, it is a semi-black-box to me but I do understand what it is doing so it can be easily replaced in the routine with any limb-darkeing that we want to include. 

;-----------------------------------------------------------
;
;
;
;
;
;

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

; Start code
!path = '~/IDL/pro:'+ !path
set_plot,'x'
device,RETAIN=2

;color_plot_prep, blue, cyan, red, green, black, white, $
; purple, orange, yellow

;restore,'template_kurucz.sav' ;template_kurucz,template_kurucz_header
;  template_kurucz=template
limbDir = structure.LIMBDARKENING
restore, limbDir + 'templates.sav' ;template_kurucz,template_kurucz_header

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
model = li(k_metal)

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
N = k_temp

st = (1221.+4)*N-N & $    
  header = read_ascii(direc+model,template=template_kurucz_header,num_records=1,data_start=st) & $ 
;  if (header eq 0) then goto,skipthis 
  data = read_ascii(direc+model,template=template_kurucz,num_records=1221,data_start=3+st) & $
  ws = data.(0)*10   
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
yall=[[phot1/phot1(0)]]  ;,[phot3/phot3(0)],[phot2/phot2(0)],[phot4/phot4(0)],[phot187/phot187(0)],[phot166/phot166(0)]]
Co=dblarr(6,4)

;=====================================================================
for i=0,0 do begin
;=== Corot 4-parameter
A = [0.0,0.0,0.0,0.0]       ; c1,c2,c3,c4
x=mu(0:16)
y=yall(0:16,i)
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
x=mu(0:14)
y=yall(0:14,i)
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
x=mu(0:14)
y=yall(0:14,i)
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
x=mu(0:14)
y=yall(0:14,i)
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



;======================================



FUNCTION quadmpfit,p,X=x,Y=y,ERR=err

  model =  1. - p(1)*(1. - x) - p(3)*(1. - x)^(4./2.)     

return,(y-model)/err
end


FUNCTION nonlinmpfit,p,X=x,Y=y,ERR=err

  model =  (1. - (p(0)*(1. - x^(1./2)) + $
      p(1)*(1. - x^(2./2)) + $
      p(2)*(1. - x^(3./2)) + $
      p(3)*(1. - x^(4./2))  )  )

return,(y-model)/err
end


pro tap_transite2, times, x, flux,b0, trend=trend       
  ;; Computes a transit lightcurve, normalized to unity, as a
  ;; function of time, t, usually in HJD or BJD.
  ;;
  ;; Input parameters (x) are:
  ;; x(0) = per = period in days
  ;; x(1) = inc = inclination in degrees
  ;; x(2) = rsource = R_*/a 
  ;; x(3) = p = R_p/R_*
  ;; x(4) = t0 = mid-point of transit (JD)
  ;; x(5) = u1
  ;; x(6) = u2
  ;; x(7) = ecc
  ;; x(8) = pomega [RADIANS!]
  
  ;; z0=sqrt(x(1)^2+((t-x(3))*x(0))^2)  
  per = x[0]
  inc = x[1]*(!dpi/180d0)
  
  rsource = x[2]
  p = x[3]
;;; t0 (x[4]) comes in as T_mid, so I need to convert to Tperi for this code
  u1 = x[5]
  u2 = x[6]
  ecc = x[7]
  pom = x[8]

  if ecc gt 0 then begin
     f = !dpi/2d0-pom
     E = 2d0*atan(sqrt((1d0-ecc)/(1d0+ecc))*sin(f/2d0), cos(f/2d0))
     n = 2d0*!dpi/per
     tperi = x[4] - (E-ecc*sin(E))/n
  endif else tperi = x[4] + per/4d0
  
  m=(2.d0*!dpi*(times-tperi)/per) mod (2.d0*!dpi) ; (2.39)
  
  if(ecc ne 0d0) then begin
     kepler_ma,m,ecc,f          ; solved (2.64)
  endif else begin
     f=m
  endelse
  radius=(1d0-ecc^2)/(1d0+ecc*cos(f))           ; (2.20)
  gmsun = 1.32712440018d26                    ; cm^3/s^2
  rpsky=radius*sqrt(1d0-(sin(inc)*sin(pom+f))^2) ; from (2.122) 
  
  occultquad_vec,rpsky/rsource,u1,u2,p,flux,F0
  b0=rpsky/rsource
  if keyword_set(trend) then begin
     th = (times-min(times))*24d0
     flux /= poly(th, [x[9],x[10]])
   ;  F0 += poly(th, [x[9]-1d0,x[10]])
  endif
end








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



;======================================



FUNCTION quadmpfit,p,X=x,Y=y,ERR=err

  model =  1. - p[1]*(1. - x) - p[3]*(1. - x)^(4./2.)     

return,(y-model)/err
end


FUNCTION nonlinmpfit,p,X=x,Y=y,ERR=err

  model =  (1. - (p[0]*(1. - x^(1./2)) + $
      p[1]*(1. - x^(2./2)) + $
      p[2]*(1. - x^(3./2)) + $
      p[3]*(1. - x^(4./2))  )  )
return,(y-model)/err
end


;*****************************************************************************
;+
;*NAME:
;
;    TRIM     JULY 13,1981
;  
;*CLASS:
;
;    Spectral Data Reduction
;  
;*CATEGORY:
;  
;*PURPOSE:
;
;    Use the values of the wave vector to eliminate all points not within the
;    specified range (LOW to HIGH) of the first vector from the other supplied
;    vectors.
;  
;*CALLING SEQUENCE:
;
;    TRIM,LOW,HIGH,V1,V2,v3,v4,header=header
;  
;*PARAMETERS:
;
;    LOW  (REQ) (I) (0) (I L R D)
;   Lowest valid value of first supplied vector, V1.
;
;    HIGH (REQ) (I) (0) (I L R D)
;   Highest valid value of first supplied vector, V1.
;
;    V1   (REQ) (I/O) (1) (I L R D)
;   Fisrt vector.  Values for LOW and HIGH based on.  V1 will be
;   trimmed accorfing to the LOW and HIGH values.
;
;    V2   (REQ) (I/O) (1) (I L R D)
;   Second vector to be trimmed.
;
;    V3...V6  (OPT) (I/O) (1) (I L R D)
;   Additional vectors to be trimmed.
;
;    HEADER (KEY) (I/O) (1) (S)
;   The fits header.
;  
;*EXAMPLES:
;
;    To plot only the IUESIPS fluxes from 1000 to 2000 angstroms for a low
;    dispersion spectrum:
;
;         iuespec,imaget,h,wave,flux,eps
;         trim,1000,2000,wave,flux,eps
;         iueplot,h,wave,flux,eps
;   
;    To eliminate points with EPS values < -400:
;
;         trim,-400,max(eps),eps,wave,flux
;         iueplot,h,wave,flux,eps
;
;    For NEWSIPS,
;
;   readmx,filename,main,wave,flux,flags,sigma,bkgrd,net
;   trim,1000,2000,wave,flux,flags,sigma,bkgrd,net,header=main
;   nsplot,main,wave,flux,flags,sigma
;  
;*SYSTEM VARIABLES USED:
;
;    none
;
;*INTERACTIVE INPUT:
;
;    none
;
;*SUBROUTINES CALLED:
;
;    PARCHECK
;    ADDPAR
;  
;*FILES USED:
;
;    none
;
;*SIDE EFFECTS:
;  
;*RESTRICTIONS:
;  
;*NOTES:
;
;    The original vectors V1, V2, V3, V4, V5, and V6 are changed to include
;    only the points between LOW and HIGH.
;
;    tested with IDL Version 2.1.2  (sunos sparc)     23 Jul 91
;    tested with IDL Version 2.1.0  (ultrix mipsel)   23 Jul 91
;    tested with IDL Version 2.1.2  (vms vax)         23 Jul 91
;  
;*PROCEDURE:
;
;    All points in the V1 vector less than LOW and greater than HIGH are
;    eliminated and the V1, V2, V3, V4, V5, and V6 vectors are reordered to
;    include only the remaining points.  If the HEADER keyword is set, a
;    HISTORY line is added about the use of trim.
;  
;*I_HELP nn:
;  
;*MODIFICATION HISTORY:
;
;    F.H. SCHIFFER 3RD  VERSION 0  13-JULY-1981
;    4-30-87 RWT add PARCHECK
;    7-19-91 GRA Converted code to lowercase; cleaned up; tested on
;                SUN, DEC, VAX; updated prolog
; 19 Nov 91  PJL  corrected typos in prolog
; 25 Jun 93  PJL  generalized;  made third vector optional;  added 3 more
;     optional vectors;  added fits header keyword
; 22 Sep 93  PJL  added else to npar case statement
;       28 Sep 93  LLT  fix minor typo in prolog
;-
;******************************************************************************
 pro trim,low,high,v1,v2,v3,v4,v5,v6,header=header
;
 npar = n_params(0)
 if (npar eq 0) then begin
    print,'TRIM,LOW,HIGH,V1,V2,v3,v4,v5,v6,header=header'
    retall 
 endif  ; npar
 parcheck,npar,[4,5,6,7,8],'TRIM'
;
 i = where(((v1 ge low) and (v1 le high)),ct)
;
;  no data remain
;
 if (ct le 0) then begin
    print,'No data available between ' + strtrim(low,2) + ' and ' +   $
       strtrim(high,2) + '.'
    print,'No points removed.'
    return
 endif  ; ct le 0
;
 v1 = v1(i)
 v2 = v2(i)
;
;  optional vectors
;
 case npar of
    5:  v3 = v3(i)
    6:  begin
           v3 = v3(i)
           v4 = v4(i)
        end  ; npar eq 6
    7:  begin
           v3 = v3(i)
           v4 = v4(i)
           v5 = v5(i)
        end  ; npar eq 7
    8:  begin
           v3 = v3(i)
           v4 = v4(i)
           v5 = v5(i)
           v6 = v6(i)
        end  ; npar eq 8
    else:
 endcase  ; npar
;
;  fits header
;
 if keyword_set(header) then addpar,header,'HISTORY',   $
    'TRIM used with LOW = ' + strtrim(low,2) + ' and HIGH = ' +    $
    strtrim(high,2) + '   ' + !stime,'','IUEDAC'
;
 return 
 end  ; trim




pro occultnl,rl,c1,c2,c3,c4,b0,mulimb0,mulimbf,plotquery,_extra=e
; Please cite Mandel & Agol (2002) if making use of this routine.
timing=systime(1)
; This routine uses the results for a uniform source to
; compute the lightcurve for a limb-darkened source
; (5-1-02 notes)
;Input:
;  rl        radius of the lens   in units of the source radius
;  c1-c4     limb-darkening coefficients
;  b0        impact parameter normalized to source radius
;  plotquery =1 to plot magnification,  =0 for no plots
;  _extra=e  plot parameters
;Output:
; mulimb0 limb-darkened magnification
; mulimbf lightcurves for each component
; 
; First, make grid in radius:
; Call magnification of uniform source:
;resolve_routine,'occultuniform'
occultuniform,b0,rl,mulimb0
bt0=b0
fac=max(abs(mulimb0-1.d0))
if (fac eq 0d0) then fac=1d-6  ;DKS edit
;print,rl
omega=4.d0*((1.d0-c1-c2-c3-c4)/4.d0+c1/5.d0+c2/6.d0+c3/7.d0+c4/8.d0)
nb=n_elements(b0)
indx=where(mulimb0 ne 1.d0)
mulimb=mulimb0(indx)
mulimbf=dblarr(nb,5)
mulimbf(*,0)=mulimbf(*,0)+1.d0
mulimbf(*,1)=mulimbf(*,1)+0.8d0
mulimbf(*,2)=mulimbf(*,2)+2.d0/3.d0
mulimbf(*,3)=mulimbf(*,3)+4.d0/7.d0
mulimbf(*,4)=mulimbf(*,4)+0.5d0
nr=long64(2);dks edit
dmumax=1.d0
;while (dmumax gt fac*1.d-10 and nr le 16) do begin
;while ((dmumax gt fac*1.d-3) and (nr le 8192)) do begin ;dks edit
while ((dmumax gt fac*1.d-3) and (nr le 131072)) do begin ;dks edit
;while (dmumax gt 1.d-6 and nr le 4) do begin
  mulimbp=mulimb
  nr=nr*2
  dt=0.5d0*!pi/double(nr)
  t=dt*dindgen(nr+1)
  th=t+0.5d0*dt
  r=sin(t)
  sig=sqrt(cos(th(nr-1)))
  mulimbhalf =sig^3*mulimb0(indx)/(1.d0-r(nr-1))
  mulimb1    =sig^4*mulimb0(indx)/(1.d0-r(nr-1))
  mulimb3half=sig^5*mulimb0(indx)/(1.d0-r(nr-1))
  mulimb2    =sig^6*mulimb0(indx)/(1.d0-r(nr-1))
  for i=1,nr-1 do begin
; Calculate uniform magnification at intermediate radii:
    occultuniform,b0(indx)/r(i),rl/r(i),mu
; Equation (29):
    sig1=sqrt(cos(th(i-1)))
    sig2=sqrt(cos(th(i)))
    mulimbhalf =mulimbhalf +r(i)^2*mu*(sig1^3/(r(i)-r(i-1))-sig2^3/(r(i+1)-r(i)))
    mulimb1    =mulimb1    +r(i)^2*mu*(sig1^4/(r(i)-r(i-1))-sig2^4/(r(i+1)-r(i)))
    mulimb3half=mulimb3half+r(i)^2*mu*(sig1^5/(r(i)-r(i-1))-sig2^5/(r(i+1)-r(i)))
    mulimb2    =mulimb2    +r(i)^2*mu*(sig1^6/(r(i)-r(i-1))-sig2^6/(r(i+1)-r(i)))
  endfor
  mulimb=((1.d0-c1-c2-c3-c4)*mulimb0(indx)+c1*mulimbhalf*dt+c2*mulimb1*dt+$
           c3*mulimb3half*dt+c4*mulimb2*dt)/omega
  ix1=where(mulimb+mulimbp ne 0.d0)
  dmumax=max(abs(mulimb(ix1)-mulimbp(ix1))/(mulimb(ix1)+mulimbp(ix1)))
  ;print,'Difference ',dmumax,fac*1.d-3,' nr ',nr
endwhile
mulimbf(indx,0)=mulimb0(indx)
mulimbf(indx,1)=mulimbhalf*dt
mulimbf(indx,2)=mulimb1*dt
mulimbf(indx,3)=mulimb3half*dt
mulimbf(indx,4)=mulimb2*dt
mulimb0(indx)=mulimb
if(plotquery eq 1) then plot,bt0,mulimb0,_extra=e
if(plotquery eq 1) then oplot,bt0,mulimbf(*,0),linestyle=2
b0=bt0
;print,'Time ',systime(1)-timing
return
end


pro occultuniform,b0,w,muo1
if(abs(w-0.5d0) lt 1.d-3) then w=0.5d0
; This routine computes the lightcurve for occultation
; of a uniform source without microlensing  (Mandel & Agol 2002).
;Input:
;
; rs   radius of the source (set to unity)
; b0   impact parameter in units of rs
; w    occulting star size in units of rs
;
;Output:
; muo1 fraction of flux at each b0 for a uniform source
;
; Now, compute pure occultation curve:
nb=n_elements(b0)
muo1=dblarr(nb)
for i=0,nb-1 do begin
; substitute z=b0(i) to shorten expressions
z=b0(i)
; the source is unocculted:
; Table 3, I.
if(z ge 1.d0+w) then begin
  muo1(i)=1.d0
  goto,next
endif
; the  source is completely occulted:
; Table 3, II.
if(w ge 1.d0 and z le w-1.d0) then begin
  muo1(i)=0.d0
  goto,next
endif
; the source is partly occulted and the occulting object crosses the limb:
; Equation (26):
if(z ge abs(1.d0-w) and z le 1.d0+w) then begin
  kap1=acos(min([(1.d0-w^2+z^2)/2.d0/z,1.d0]))
  kap0=acos(min([(w^2+z^2-1.d0)/2.d0/w/z,1.d0]))
  lambdae=w^2*kap0+kap1
  lambdae=(lambdae-0.5d0*sqrt(max([4.d0*z^2-(1.d0+z^2-w^2)^2,0.d0])))/!pi
  muo1(i)=1.d0-lambdae
endif
; the occulting object transits the source star (but doesn't
; completely cover it):
if(z le 1.d0-w) then muo1(i)=1.d0-w^2
next:
endfor
;muo1=1.d0-lambdae
return
end




;+
; NAME:
;   MPFIT
;
; AUTHOR:
;   Craig B. Markwardt, NASA/GSFC Code 662, Greenbelt, MD 20770
;   craigm@lheamail.gsfc.nasa.gov
;   UPDATED VERSIONs can be found on my WEB PAGE: 
;      http://cow.physics.wisc.edu/~craigm/idl/idl.html
;
; PURPOSE:
;   Perform Levenberg-Marquardt least-squares minimization (MINPACK-1)
;
; MAJOR TOPICS:
;   Curve and Surface Fitting
;
; CALLING SEQUENCE:
;   parms = MPFIT(MYFUNCT, start_parms, FUNCTARGS=fcnargs, NFEV=nfev,
;                 MAXITER=maxiter, ERRMSG=errmsg, NPRINT=nprint, QUIET=quiet, 
;                 FTOL=ftol, XTOL=xtol, GTOL=gtol, NITER=niter, 
;                 STATUS=status, ITERPROC=iterproc, ITERARGS=iterargs,
;                 COVAR=covar, PERROR=perror, BESTNORM=bestnorm,
;                 PARINFO=parinfo)
;
; DESCRIPTION:
;
;  MPFIT uses the Levenberg-Marquardt technique to solve the
;  least-squares problem.  In its typical use, MPFIT will be used to
;  fit a user-supplied function (the "model") to user-supplied data
;  points (the "data") by adjusting a set of parameters.  MPFIT is
;  based upon MINPACK-1 (LMDIF.F) by More' and collaborators.
;
;  For example, a researcher may think that a set of observed data
;  points is best modelled with a Gaussian curve.  A Gaussian curve is
;  parameterized by its mean, standard deviation and normalization.
;  MPFIT will, within certain constraints, find the set of parameters
;  which best fits the data.  The fit is "best" in the least-squares
;  sense; that is, the sum of the weighted squared differences between
;  the model and data is minimized.
;
;  The Levenberg-Marquardt technique is a particular strategy for
;  iteratively searching for the best fit.  This particular
;  implementation is drawn from MINPACK-1 (see NETLIB), and seems to
;  be more robust than routines provided with IDL.  This version
;  allows upper and lower bounding constraints to be placed on each
;  parameter, or the parameter can be held fixed.
;
;  The IDL user-supplied function should return an array of weighted
;  deviations between model and data.  In a typical scientific problem
;  the residuals should be weighted so that each deviate has a
;  gaussian sigma of 1.0.  If X represents values of the independent
;  variable, Y represents a measurement for each value of X, and ERR
;  represents the error in the measurements, then the deviates could
;  be calculated as follows:
;
;    DEVIATES = (Y - F(X)) / ERR
;
;  where F is the analytical function representing the model.  You are
;  recommended to use the convenience functions MPFITFUN and
;  MPFITEXPR, which are driver functions that calculate the deviates
;  for you.  If ERR are the 1-sigma uncertainties in Y, then
;
;    TOTAL( DEVIATES^2 ) 
;
;  will be the total chi-squared value.  MPFIT will minimize the
;  chi-square value.  The values of X, Y and ERR are passed through
;  MPFIT to the user-supplied function via the FUNCTARGS keyword.
;
;  Simple constraints can be placed on parameter values by using the
;  PARINFO keyword to MPFIT.  See below for a description of this
;  keyword.
;
;  MPFIT does not perform more general optimization tasks.  See TNMIN
;  instead.  MPFIT is customized, based on MINPACK-1, to the
;  least-squares minimization problem.
;
; USER FUNCTION
;
;  The user must define a function which returns the appropriate
;  values as specified above.  The function should return the weighted
;  deviations between the model and the data.  For applications which
;  use finite-difference derivatives -- the default -- the user
;  function should be declared in the following way:
;
;    FUNCTION MYFUNCT, p, X=x, Y=y, ERR=err
;     ; Parameter values are passed in "p"
;     model = F(x, p)
;     return, (y-model)/err
;    END
;
;  See below for applications with analytical derivatives.
;
;  The keyword parameters X, Y, and ERR in the example above are
;  suggestive but not required.  Any parameters can be passed to
;  MYFUNCT by using the FUNCTARGS keyword to MPFIT.  Use MPFITFUN and
;  MPFITEXPR if you need ideas on how to do that.  The function *must*
;  accept a parameter list, P.
;  
;  In general there are no restrictions on the number of dimensions in
;  X, Y or ERR.  However the deviates *must* be returned in a
;  one-dimensional array, and must have the same type (float or
;  double) as the input arrays.
;
;  User functions may also indicate a fatal error condition using the
;  ERROR_CODE common block variable, as described below under the
;  MPFIT_ERROR common block definition (by setting ERROR_CODE to a
;  number between -15 and -1).
;
; ANALYTIC DERIVATIVES
; 
;  In the search for the best-fit solution, MPFIT by default
;  calculates derivatives numerically via a finite difference
;  approximation.  The user-supplied function need not calculate the
;  derivatives explicitly.  However, if you desire to compute them
;  analytically, then the AUTODERIVATIVE=0 keyword must be passed.  As
;  a practical matter, it is often sufficient and even faster to allow
;  MPFIT to calculate the derivatives numerically, and so
;  AUTODERIVATIVE=0 is not necessary.
;
;  Also, the user function must be declared with one additional
;  parameter, as follows:
;
;    FUNCTION MYFUNCT, p, dp, X=x, Y=y, ERR=err
;     model = F(x, p)
;     
;     if n_params() GT 1 then begin
;       ; Compute derivatives
;       dp = make_array(n_elements(x), n_elements(p), value=x(0)*0)
;       for i = 0, n_elements(p)-1 do $
;         dp(*,i) = FGRAD(x, p, i)
;     endif
;    
;     return, (y-model)/err
;    END
;
;  where FGRAD(x, p, i) is a user function which must compute the
;  derivative of the model with respect to parameter P(i) at X.  When
;  finite differencing is used for computing derivatives (ie, when
;  AUTODERIVATIVE=1), the parameter DP is not passed.  Therefore
;  functions can use N_PARAMS() to indicate whether they must compute
;  the derivatives or not.
;
;  Derivatives should be returned in the DP array. DP should be an m x
;  n array, where m is the number of data points and n is the number
;  of parameters.  dp(i,j) is the derivative at the ith point with
;  respect to the jth parameter.  
;  
;  The derivatives with respect to fixed parameters are ignored; zero
;  is an appropriate value to insert for those derivatives.  Upon
;  input to the user function, DP is set to a vector with the same
;  length as P, with a value of 1 for a parameter which is free, and a
;  value of zero for a parameter which is fixed (and hence no
;  derivative needs to be calculated).  This input vector may be
;  overwritten as needed.
;
;  If the data is higher than one dimensional, then the *last*
;  dimension should be the parameter dimension.  Example: fitting a
;  50x50 image, "dp" should be 50x50xNPAR.
;  
; CONSTRAINING PARAMETER VALUES WITH THE PARINFO KEYWORD
;
;  The behavior of MPFIT can be modified with respect to each
;  parameter to be fitted.  A parameter value can be fixed; simple
;  boundary constraints can be imposed; limitations on the parameter
;  changes can be imposed; properties of the automatic derivative can
;  be modified; and parameters can be tied to one another.
;
;  These properties are governed by the PARINFO structure, which is
;  passed as a keyword parameter to MPFIT.
;
;  PARINFO should be an array of structures, one for each parameter.
;  Each parameter is associated with one element of the array, in
;  numerical order.  The structure can have the following entries
;  (none are required):
;  
;     .VALUE - the starting parameter value (but see the START_PARAMS
;              parameter for more information).
;  
;     .FIXED - a boolean value, whether the parameter is to be held
;              fixed or not.  Fixed parameters are not varied by
;              MPFIT, but are passed on to MYFUNCT for evaluation.
;  
;     .LIMITED - a two-element boolean array.  If the first/second
;                element is set, then the parameter is bounded on the
;                lower/upper side.  A parameter can be bounded on both
;                sides.  Both LIMITED and LIMITS must be given
;                together.
;  
;     .LIMITS - a two-element float or double array.  Gives the
;               parameter limits on the lower and upper sides,
;               respectively.  Zero, one or two of these values can be
;               set, depending on the values of LIMITED.  Both LIMITED
;               and LIMITS must be given together.
;  
;     .PARNAME - a string, giving the name of the parameter.  The
;                fitting code of MPFIT does not use this tag in any
;                way.  However, the default ITERPROC will print the
;                parameter name if available.
;  
;     .STEP - the step size to be used in calculating the numerical
;             derivatives.  If set to zero, then the step size is
;             computed automatically.  Ignored when AUTODERIVATIVE=0.
;             This value is superceded by the RELSTEP value.
;
;     .RELSTEP - the *relative* step size to be used in calculating
;                the numerical derivatives.  This number is the
;                fractional size of the step, compared to the
;                parameter value.  This value supercedes the STEP
;                setting.  If the parameter is zero, then a default
;                step size is chosen.
;
;     .MPSIDE - the sidedness of the finite difference when computing
;               numerical derivatives.  This field can take four
;               values:
;
;                  0 - one-sided derivative computed automatically
;                  1 - one-sided derivative (f(x+h) - f(x)  )/h
;                 -1 - one-sided derivative (f(x)   - f(x-h))/h
;                  2 - two-sided derivative (f(x+h) - f(x-h))/(2*h)
;
;              Where H is the STEP parameter described above.  The
;              "automatic" one-sided derivative method will chose a
;              direction for the finite difference which does not
;              violate any constraints.  The other methods do not
;              perform this check.  The two-sided method is in
;              principle more precise, but requires twice as many
;              function evaluations.  Default: 0.
;
;     .MPMAXSTEP - the maximum change to be made in the parameter
;                  value.  During the fitting process, the parameter
;                  will never be changed by more than this value in
;                  one iteration.
;
;                  A value of 0 indicates no maximum.  Default: 0.
;  
;     .TIED - a string expression which "ties" the parameter to other
;             free or fixed parameters as an equality constraint.  Any
;             expression involving constants and the parameter array P
;             are permitted.
;             Example: if parameter 2 is always to be twice parameter
;             1 then use the following: parinfo(2).tied = '2 * P(1)'.
;             Since they are totally constrained, tied parameters are
;             considered to be fixed; no errors are computed for them.
;             [ NOTE: the PARNAME can't be used in expressions. ]
;
;     .MPPRINT - if set to 1, then the default ITERPROC will print the
;                parameter value.  If set to 0, the parameter value
;                will not be printed.  This tag can be used to
;                selectively print only a few parameter values out of
;                many.  Default: 1 (all parameters printed)
;
;     .MPFORMAT - IDL format string to print the parameter within
;                 ITERPROC.  Default: '(G20.6)' An empty string will
;                 also use the default.
;
;  
;  Future modifications to the PARINFO structure, if any, will involve
;  adding structure tags beginning with the two letters "MP".
;  Therefore programmers are urged to avoid using tags starting with
;  the same letters; otherwise they are free to include their own
;  fields within the PARINFO structure, and they will be ignored.
;  
;  PARINFO Example:
;  parinfo = replicate({value:0.D, fixed:0, limited:[0,0], $
;                       limits:[0.D,0]}, 5)
;  parinfo(0).fixed = 1
;  parinfo(4).limited(0) = 1
;  parinfo(4).limits(0)  = 50.D
;  parinfo(*).value = [5.7D, 2.2, 500., 1.5, 2000.]
;  
;  A total of 5 parameters, with starting values of 5.7,
;  2.2, 500, 1.5, and 2000 are given.  The first parameter
;  is fixed at a value of 5.7, and the last parameter is
;  constrained to be above 50.
;
;
; HARD-TO-COMPUTE FUNCTIONS: "EXTERNAL" EVALUATION
;
;  The normal mode of operation for MPFIT is for the user to pass a
;  function name, and MPFIT will call the user function multiple times
;  as it iterates toward a solution.
;
;  Some user functions are particularly hard to compute using the
;  standard model of MPFIT.  Usually these are functions that depend
;  on a large amount of external data, and so it is not feasible, or
;  at least highly impractical, to have MPFIT call it.  In those cases
;  it may be possible to use the "(EXTERNAL)" evaluation option.
;
;  In this case the user is responsible for making all function *and
;  derivative* evaluations.  The function and Jacobian data are passed
;  in through the EXTERNAL_FVEC and EXTERNAL_FJAC keywords,
;  respectively.  The user indicates the selection of this option by
;  specifying a function name (MYFUNCT) of "(EXTERNAL)".  No
;  user-function calls are made when EXTERNAL evaluation is being
;  used.
;
;  At the end of each iteration, control returns to the user, who must
;  reevaluate the function at its new parameter values.  Users should
;  check the return value of the STATUS keyword, where a value of 9
;  indicates the user should supply more data for the next iteration,
;  and re-call MPFIT.  The user may refrain from calling MPFIT
;  further; as usual, STATUS will indicate when the solution has
;  converged and no more iterations are required.
;
;  Because MPFIT must maintain its own data structures between calls,
;  the user must also pass a named variable to the EXTERNAL_STATE
;  keyword.  This variable must be maintained by the user, but not
;  changed, throughout the fitting process.  When no more iterations
;  are desired, the named variable may be discarded.
;
;
; INPUTS:
;   MYFUNCT - a string variable containing the name of the function to
;             be minimized.  The function should return the weighted
;             deviations between the model and the data, as described
;             above.
;
;             For EXTERNAL evaluation of functions, this parameter
;             should be set to a value of "(EXTERNAL)".
;
;   START_PARAMS - An array of starting values for each of the
;                  parameters of the model.  The number of parameters
;                  should be fewer than the number of measurements.
;                  Also, the parameters should have the same data type
;                  as the measurements (double is preferred).
;
;                  This parameter is optional if the PARINFO keyword
;                  is used (but see PARINFO).  The PARINFO keyword
;                  provides a mechanism to fix or constrain individual
;                  parameters.  If both START_PARAMS and PARINFO are
;                  passed, then the starting *value* is taken from
;                  START_PARAMS, but the *constraints* are taken from
;                  PARINFO.
; 
; RETURNS:
;
;   Returns the array of best-fit parameters.
;
;
; KEYWORD PARAMETERS:
;
;   AUTODERIVATIVE - If this is set, derivatives of the function will
;                    be computed automatically via a finite
;                    differencing procedure.  If not set, then MYFUNCT
;                    must provide the (analytical) derivatives.
;                    Default: set (=1) 
;                    NOTE: to supply your own analytical derivatives,
;                      explicitly pass AUTODERIVATIVE=0
;
;   BESTNORM - the value of the summed squared weighted residuals for
;              the returned parameter values, i.e. TOTAL(DEVIATES^2).
;
;   COVAR - the covariance matrix for the set of parameters returned
;           by MPFIT.  The matrix is NxN where N is the number of
;           parameters.  The square root of the diagonal elements
;           gives the formal 1-sigma statistical errors on the
;           parameters IF errors were treated "properly" in MYFUNC.
;           Parameter errors are also returned in PERROR.
;
;           To compute the correlation matrix, PCOR, use this example:
;           IDL> PCOR = COV * 0
;           IDL> FOR i = 0, n-1 DO FOR j = 0, n-1 DO $
;                PCOR(i,j) = COV(i,j)/sqrt(COV(i,i)*COV(j,j))
;
;           If NOCOVAR is set or MPFIT terminated abnormally, then
;           COVAR is set to a scalar with value !VALUES.D_NAN.
;
;   DOF - number of degrees of freedom, computed as
;             DOF = N_ELEMENTS(DEVIATES) - NFREE
;         Note that this doesn't account for pegged parameters (see
;         NPEGGED).
;
;   ERRMSG - a string error or warning message is returned.
;
;   EXTERNAL_FVEC - upon input, the function values, evaluated at
;                   START_PARAMS.  This should be an M-vector, where M
;                   is the number of data points.
;
;   EXTERNAL_FJAC - upon input, the Jacobian array of partial
;                   derivative values.  This should be a M x N array,
;                   where M is the number of data points and N is the
;                   number of parameters.  NOTE: that all FIXED or
;                   TIED parameters must *not* be included in this
;                   array.
;
;   EXTERNAL_STATE - a named variable to store MPFIT-related state
;                    information between iterations (used in input and
;                    output to MPFIT).  The user must not manipulate
;                    or discard this data until the final iteration is
;                    performed.
;
;   FASTNORM - set this keyword to select a faster algorithm to
;              compute sum-of-square values internally.  For systems
;              with large numbers of data points, the standard
;              algorithm can become prohibitively slow because it
;              cannot be vectorized well.  By setting this keyword,
;              MPFIT will run faster, but it will be more prone to
;              floating point overflows and underflows.  Thus, setting
;              this keyword may sacrifice some stability in the
;              fitting process.
;              
;   FTOL - a nonnegative input variable. Termination occurs when both
;          the actual and predicted relative reductions in the sum of
;          squares are at most FTOL (and STATUS is accordingly set to
;          1 or 3).  Therefore, FTOL measures the relative error
;          desired in the sum of squares.  Default: 1D-10
;
;   FUNCTARGS - A structure which contains the parameters to be passed
;               to the user-supplied function specified by MYFUNCT via
;               the _EXTRA mechanism.  This is the way you can pass
;               additional data to your user-supplied function without
;               using common blocks.
;
;               Consider the following example:
;                if FUNCTARGS = { XVAL:[1.D,2,3], YVAL:[1.D,4,9],
;                                 ERRVAL:[1.D,1,1] }
;                then the user supplied function should be declared
;                like this:
;                FUNCTION MYFUNCT, P, XVAL=x, YVAL=y, ERRVAL=err
;
;               By default, no extra parameters are passed to the
;               user-supplied function, but your function should
;               accept *at least* one keyword parameter.  [ This is to
;               accomodate a limitation in IDL's _EXTRA
;               parameter-passing mechanism. ]
;
;   GTOL - a nonnegative input variable. Termination occurs when the
;          cosine of the angle between fvec and any column of the
;          jacobian is at most GTOL in absolute value (and STATUS is
;          accordingly set to 4). Therefore, GTOL measures the
;          orthogonality desired between the function vector and the
;          columns of the jacobian.  Default: 1D-10
;
;   ITERARGS - The keyword arguments to be passed to ITERPROC via the
;              _EXTRA mechanism.  This should be a structure, and is
;              similar in operation to FUNCTARGS.
;              Default: no arguments are passed.
;
;   ITERPRINT - The name of an IDL procedure, equivalent to PRINT,
;               that ITERPROC will use to render output.  ITERPRINT
;               should be able to accept at least four positional
;               arguments.  In addition, it should be able to accept
;               the standard FORMAT keyword for output formatting; and
;               the UNIT keyword, to redirect output to a logical file
;               unit (default should be UNIT=1, standard output).
;               These keywords are passed using the ITERARGS keyword
;               above.  The ITERPRINT procedure must accept the _EXTRA
;               keyword.
;
;   ITERPROC - The name of a procedure to be called upon each NPRINT
;              iteration of the MPFIT routine.  ITERPROC is always
;              called in the final iteration.  It should be declared
;              in the following way:
;
;              PRO ITERPROC, MYFUNCT, p, iter, fnorm, FUNCTARGS=fcnargs, $
;                PARINFO=parinfo, QUIET=quiet, DOF=dof, ...
;                ; perform custom iteration update
;              END
;         
;              ITERPROC must either accept all three keyword
;              parameters (FUNCTARGS, PARINFO and QUIET), or at least
;              accept them via the _EXTRA keyword.
;          
;              MYFUNCT is the user-supplied function to be minimized,
;              P is the current set of model parameters, ITER is the
;              iteration number, and FUNCTARGS are the arguments to be
;              passed to MYFUNCT.  FNORM should be the chi-squared
;              value.  QUIET is set when no textual output should be
;              printed.  DOF is the number of degrees of freedom,
;              normally the number of points less the number of free
;              parameters.  See below for documentation of PARINFO.
;
;              In implementation, ITERPROC can perform updates to the
;              terminal or graphical user interface, to provide
;              feedback while the fit proceeds.  If the fit is to be
;              stopped for any reason, then ITERPROC should set the
;              common block variable ERROR_CODE to negative value
;              between -15 and -1 (see MPFIT_ERROR common block
;              below).  In principle, ITERPROC should probably not
;              modify the parameter values, because it may interfere
;              with the algorithm's stability.  In practice it is
;              allowed.
;
;              Default: an internal routine is used to print the
;                       parameter values.
;
;   ITERSTOP - Set this keyword if you wish to be able to stop the
;              fitting by hitting the predefined ITERKEYSTOP key on
;              the keyboard.  This only works if you use the default
;              ITERPROC.
;
;   ITERKEYSTOP - A keyboard key which will halt the fit (and if
;                 ITERSTOP is set and the default ITERPROC is used).
;                 ITERSTOPKEY may either be a one-character string
;                 with the desired key, or a scalar integer giving the
;                 ASCII code of the desired key.  
;                 Default: 7b (control-g)
;
;                 NOTE: the default value of ASCI 7 (control-G) cannot
;                 be read in some windowing environments, so you must
;                 change to a printable character like 'q'.
;
;   MAXITER - The maximum number of iterations to perform.  If the
;             number is exceeded, then the STATUS value is set to 5
;             and MPFIT returns.
;             Default: 200 iterations
;
;   NFEV - the number of MYFUNCT function evaluations performed.
;
;   NFREE - the number of free parameters in the fit.  This includes
;           parameters which are not FIXED and not TIED, but it does
;           include parameters which are pegged at LIMITS.
;
;   NITER - the number of iterations completed.
;
;   NOCOVAR - set this keyword to prevent the calculation of the
;             covariance matrix before returning (see COVAR)
;
;   NPEGGED - the number of free parameters which are pegged at a
;             LIMIT.
;
;   NPRINT - The frequency with which ITERPROC is called.  A value of
;            1 indicates that ITERPROC is called with every iteration,
;            while 2 indicates every other iteration, etc.  Be aware
;            that several Levenberg-Marquardt attempts can be made in
;            a single iteration.  Also, the ITERPROC is *always*
;            called for the final iteration, regardless of the
;            iteration number.
;            Default value: 1
;
;   PARINFO - Provides a mechanism for more sophisticated constraints
;             to be placed on parameter values.  When PARINFO is not
;             passed, then it is assumed that all parameters are free
;             and unconstrained.  Values in PARINFO are never 
;             modified during a call to MPFIT.
;
;             See description above for the structure of PARINFO.
;
;             Default value:  all parameters are free and unconstrained.
;
;   PERROR - The formal 1-sigma errors in each parameter, computed
;            from the covariance matrix.  If a parameter is held
;            fixed, or if it touches a boundary, then the error is
;            reported as zero.
;
;            If the fit is unweighted (i.e. no errors were given, or
;            the weights were uniformly set to unity), then PERROR
;            will probably not represent the true parameter
;            uncertainties.  
;
;            *If* you can assume that the true reduced chi-squared
;            value is unity -- meaning that the fit is implicitly
;            assumed to be of good quality -- then the estimated
;            parameter uncertainties can be computed by scaling PERROR
;            by the measured chi-squared value.
;
;              DOF     = N_ELEMENTS(X) - N_ELEMENTS(PARMS) ; deg of freedom
;              PCERROR = PERROR * SQRT(BESTNORM / DOF)   ; scaled uncertainties
;
;   QUIET - set this keyword when no textual output should be printed
;           by MPFIT
;
;   RESDAMP - a scalar number, indicating the cut-off value of
;             residuals where "damping" will occur.  Residuals with
;             magnitudes greater than this number will be replaced by
;             their logarithm.  This partially mitigates the so-called
;             large residual problem inherent in least-squares solvers
;             (as for the test problem CURVI, http://www.maxthis.com/-
;             curviex.htm).  A value of 0 indicates no damping.
;             Default: 0
;
;             Note: RESDAMP doesn't work with AUTODERIV=0
;
;   STATUS - an integer status code is returned.  All values greater
;            than zero can represent success (however STATUS EQ 5 may
;            indicate failure to converge).  It can have one of the
;            following values:
;
;        -16  a parameter or function value has become infinite or an
;             undefined number.  This is usually a consequence of
;             numerical overflow in the user's model function, which
;             must be avoided.
;
;        -15 to -1 
;             these are error codes that either MYFUNCT or ITERPROC
;             may return to terminate the fitting process (see
;             description of MPFIT_ERROR common below).  If either
;             MYFUNCT or ITERPROC set ERROR_CODE to a negative number,
;             then that number is returned in STATUS.  Values from -15
;             to -1 are reserved for the user functions and will not
;             clash with MPFIT.
;
;    0  improper input parameters.
;         
;    1  both actual and predicted relative reductions
;       in the sum of squares are at most FTOL.
;         
;    2  relative error between two consecutive iterates
;       is at most XTOL
;         
;    3  conditions for STATUS = 1 and STATUS = 2 both hold.
;         
;    4  the cosine of the angle between fvec and any
;       column of the jacobian is at most GTOL in
;       absolute value.
;         
;    5  the maximum number of iterations has been reached
;         
;    6  FTOL is too small. no further reduction in
;       the sum of squares is possible.
;         
;    7  XTOL is too small. no further improvement in
;       the approximate solution x is possible.
;         
;    8  GTOL is too small. fvec is orthogonal to the
;       columns of the jacobian to machine precision.
;
;          9  A successful single iteration has been completed, and
;             the user must supply another "EXTERNAL" evaluation of
;             the function and its derivatives.  This status indicator
;             is neither an error nor a convergence indicator.
;
;   XTOL - a nonnegative input variable. Termination occurs when the
;          relative error between two consecutive iterates is at most
;          XTOL (and STATUS is accordingly set to 2 or 3).  Therefore,
;          XTOL measures the relative error desired in the approximate
;          solution.  Default: 1D-10
;
;
; EXAMPLE:
;
;   p0 = [5.7D, 2.2, 500., 1.5, 2000.]
;   fa = {X:x, Y:y, ERR:err}
;   p = mpfit('MYFUNCT', p0, functargs=fa)
;
;   Minimizes sum of squares of MYFUNCT.  MYFUNCT is called with the X,
;   Y, and ERR keyword parameters that are given by FUNCTARGS.  The
;   resulting parameter values are returned in p.
;
;
; COMMON BLOCKS:
;
;   COMMON MPFIT_ERROR, ERROR_CODE
;
;     User routines may stop the fitting process at any time by
;     setting an error condition.  This condition may be set in either
;     the user's model computation routine (MYFUNCT), or in the
;     iteration procedure (ITERPROC).
;
;     To stop the fitting, the above common block must be declared,
;     and ERROR_CODE must be set to a negative number.  After the user
;     procedure or function returns, MPFIT checks the value of this
;     common block variable and exits immediately if the error
;     condition has been set.  This value is also returned in the
;     STATUS keyword: values of -1 through -15 are reserved error
;     codes for the user routines.  By default the value of ERROR_CODE
;     is zero, indicating a successful function/procedure call.
;
;   COMMON MPFIT_PROFILE
;   COMMON MPFIT_MACHAR
;   COMMON MPFIT_CONFIG
;
;     These are undocumented common blocks are used internally by
;     MPFIT and may change in future implementations.
;
; THEORY OF OPERATION:
;
;   There are many specific strategies for function minimization.  One
;   very popular technique is to use function gradient information to
;   realize the local structure of the function.  Near a local minimum
;   the function value can be taylor expanded about x0 as follows:
;
;      f(x) = f(x0) + f'(x0) . (x-x0) + (1/2) (x-x0) . f''(x0) . (x-x0)
;             -----   ---------------   -------------------------------  (1)
;     Order    0th          1st                      2nd
;
;   Here f'(x) is the gradient vector of f at x, and f''(x) is the
;   Hessian matrix of second derivatives of f at x.  The vector x is
;   the set of function parameters, not the measured data vector.  One
;   can find the minimum of f, f(xm) using Newton's method, and
;   arrives at the following linear equation:
;
;      f''(x0) . (xm-x0) = - f'(x0)                            (2)
;
;   If an inverse can be found for f''(x0) then one can solve for
;   (xm-x0), the step vector from the current position x0 to the new
;   projected minimum.  Here the problem has been linearized (ie, the
;   gradient information is known to first order).  f''(x0) is
;   symmetric n x n matrix, and should be positive definite.
;
;   The Levenberg - Marquardt technique is a variation on this theme.
;   It adds an additional diagonal term to the equation which may aid the
;   convergence properties:
;
;      (f''(x0) + nu I) . (xm-x0) = -f'(x0)                  (2a)
;
;   where I is the identity matrix.  When nu is large, the overall
;   matrix is diagonally dominant, and the iterations follow steepest
;   descent.  When nu is small, the iterations are quadratically
;   convergent.
;
;   In principle, if f''(x0) and f'(x0) are known then xm-x0 can be
;   determined.  However the Hessian matrix is often difficult or
;   impossible to compute.  The gradient f'(x0) may be easier to
;   compute, if even by finite difference techniques.  So-called
;   quasi-Newton techniques attempt to successively estimate f''(x0)
;   by building up gradient information as the iterations proceed.
;
;   In the least squares problem there are further simplifications
;   which assist in solving eqn (2).  The function to be minimized is
;   a sum of squares:
;
;       f = Sum(hi^2)                                         (3)
;
;   where hi is the ith residual out of m residuals as described
;   above.  This can be substituted back into eqn (2) after computing
;   the derivatives:
;
;       f'  = 2 Sum(hi  hi')     
;       f'' = 2 Sum(hi' hj') + 2 Sum(hi hi'')                (4)
;
;   If one assumes that the parameters are already close enough to a
;   minimum, then one typically finds that the second term in f'' is
;   negligible [or, in any case, is too difficult to compute].  Thus,
;   equation (2) can be solved, at least approximately, using only
;   gradient information.
;
;   In matrix notation, the combination of eqns (2) and (4) becomes:
;
;        hT' . h' . dx = - hT' . h                          (5)
;
;   Where h is the residual vector (length m), hT is its transpose, h'
;   is the Jacobian matrix (dimensions n x m), and dx is (xm-x0).  The
;   user function supplies the residual vector h, and in some cases h'
;   when it is not found by finite differences (see MPFIT_FDJAC2,
;   which finds h and hT').  Even if dx is not the best absolute step
;   to take, it does provide a good estimate of the best *direction*,
;   so often a line minimization will occur along the dx vector
;   direction.
;
;   The method of solution employed by MINPACK is to form the Q . R
;   factorization of h', where Q is an orthogonal matrix such that QT .
;   Q = I, and R is upper right triangular.  Using h' = Q . R and the
;   ortogonality of Q, eqn (5) becomes
;
;        (RT . QT) . (Q . R) . dx = - (RT . QT) . h
;                     RT . R . dx = - RT . QT . h         (6)
;                          R . dx = - QT . h
;
;   where the last statement follows because R is upper triangular.
;   Here, R, QT and h are known so this is a matter of solving for dx.
;   The routine MPFIT_QRFAC provides the QR factorization of h, with
;   pivoting, and MPFIT_QRSOLV provides the solution for dx.
;   
; REFERENCES:
;
;   MINPACK-1, Jorge More', available from netlib (www.netlib.org).
;   "Optimization Software Guide," Jorge More' and Stephen Wright, 
;     SIAM, *Frontiers in Applied Mathematics*, Number 14.
;   More', Jorge J., "The Levenberg-Marquardt Algorithm:
;     Implementation and Theory," in *Numerical Analysis*, ed. Watson,
;     G. A., Lecture Notes in Mathematics 630, Springer-Verlag, 1977.
;
; MODIFICATION HISTORY:
;   Translated from MINPACK-1 in FORTRAN, Apr-Jul 1998, CM
;   Fixed bug in parameter limits (x vs xnew), 04 Aug 1998, CM
;   Added PERROR keyword, 04 Aug 1998, CM
;   Added COVAR keyword, 20 Aug 1998, CM
;   Added NITER output keyword, 05 Oct 1998
;      D.L Windt, Bell Labs, windt@bell-labs.com;
;   Made each PARINFO component optional, 05 Oct 1998 CM
;   Analytical derivatives allowed via AUTODERIVATIVE keyword, 09 Nov 1998
;   Parameter values can be tied to others, 09 Nov 1998
;   Fixed small bugs (Wayne Landsman), 24 Nov 1998
;   Added better exception error reporting, 24 Nov 1998 CM
;   Cosmetic documentation changes, 02 Jan 1999 CM
;   Changed definition of ITERPROC to be consistent with TNMIN, 19 Jan 1999 CM
;   Fixed bug when AUTDERIVATIVE=0.  Incorrect sign, 02 Feb 1999 CM
;   Added keyboard stop to MPFIT_DEFITER, 28 Feb 1999 CM
;   Cosmetic documentation changes, 14 May 1999 CM
;   IDL optimizations for speed & FASTNORM keyword, 15 May 1999 CM
;   Tried a faster version of mpfit_enorm, 30 May 1999 CM
;   Changed web address to cow.physics.wisc.edu, 14 Jun 1999 CM
;   Found malformation of FDJAC in MPFIT for 1 parm, 03 Aug 1999 CM
;   Factored out user-function call into MPFIT_CALL.  It is possible,
;     but currently disabled, to call procedures.  The calling format
;     is similar to CURVEFIT, 25 Sep 1999, CM
;   Slightly changed mpfit_tie to be less intrusive, 25 Sep 1999, CM
;   Fixed some bugs associated with tied parameters in mpfit_fdjac, 25
;     Sep 1999, CM
;   Reordered documentation; now alphabetical, 02 Oct 1999, CM
;   Added QUERY keyword for more robust error detection in drivers, 29
;     Oct 1999, CM
;   Documented PERROR for unweighted fits, 03 Nov 1999, CM
;   Split out MPFIT_RESETPROF to aid in profiling, 03 Nov 1999, CM
;   Some profiling and speed optimization, 03 Nov 1999, CM
;     Worst offenders, in order: fdjac2, qrfac, qrsolv, enorm.
;     fdjac2 depends on user function, qrfac and enorm seem to be
;     fully optimized.  qrsolv probably could be tweaked a little, but
;     is still <10% of total compute time.
;   Made sure that !err was set to 0 in MPFIT_DEFITER, 10 Jan 2000, CM
;   Fixed small inconsistency in setting of QANYLIM, 28 Jan 2000, CM
;   Added PARINFO field RELSTEP, 28 Jan 2000, CM
;   Converted to MPFIT_ERROR common block for indicating error
;     conditions, 28 Jan 2000, CM
;   Corrected scope of MPFIT_ERROR common block, CM, 07 Mar 2000
;   Minor speed improvement in MPFIT_ENORM, CM 26 Mar 2000
;   Corrected case where ITERPROC changed parameter values and
;     parameter values were TIED, CM 26 Mar 2000
;   Changed MPFIT_CALL to modify NFEV automatically, and to support
;     user procedures more, CM 26 Mar 2000
;   Copying permission terms have been liberalized, 26 Mar 2000, CM
;   Catch zero value of zero a(j,lj) in MPFIT_QRFAC, 20 Jul 2000, CM
;      (thanks to David Schlegel <schlegel@astro.princeton.edu>)
;   MPFIT_SETMACHAR is called only once at init; only one common block
;     is created (MPFIT_MACHAR); it is now a structure; removed almost
;     all CHECK_MATH calls for compatibility with IDL5 and !EXCEPT;
;     profiling data is now in a structure too; noted some
;     mathematical discrepancies in Linux IDL5.0, 17 Nov 2000, CM
;   Some significant changes.  New PARINFO fields: MPSIDE, MPMINSTEP,
;     MPMAXSTEP.  Improved documentation.  Now PTIED constraints are
;     maintained in the MPCONFIG common block.  A new procedure to
;     parse PARINFO fields.  FDJAC2 now computes a larger variety of
;     one-sided and two-sided finite difference derivatives.  NFEV is
;     stored in the MPCONFIG common now.  17 Dec 2000, CM
;   Added check that PARINFO and XALL have same size, 29 Dec 2000 CM
;   Don't call function in TERMINATE when there is an error, 05 Jan
;     2000
;   Check for float vs. double discrepancies; corrected implementation
;     of MIN/MAXSTEP, which I still am not sure of, but now at least
;     the correct behavior occurs *without* it, CM 08 Jan 2001
;   Added SCALE_FCN keyword, to allow for scaling, as for the CASH
;     statistic; added documentation about the theory of operation,
;     and under the QR factorization; slowly I'm beginning to
;     understand the bowels of this algorithm, CM 10 Jan 2001
;   Remove MPMINSTEP field of PARINFO, for now at least, CM 11 Jan
;     2001
;   Added RESDAMP keyword, CM, 14 Jan 2001
;   Tried to improve the DAMP handling a little, CM, 13 Mar 2001
;   Corrected .PARNAME behavior in _DEFITER, CM, 19 Mar 2001
;   Added checks for parameter and function overflow; a new STATUS
;     value to reflect this; STATUS values of -15 to -1 are reserved
;     for user function errors, CM, 03 Apr 2001
;   DAMP keyword is now a TANH, CM, 03 Apr 2001
;   Added more error checking of float vs. double, CM, 07 Apr 2001
;   Fixed bug in handling of parameter lower limits; moved overflow
;     checking to end of loop, CM, 20 Apr 2001
;   Failure using GOTO, TERMINATE more graceful if FNORM1 not defined,
;     CM, 13 Aug 2001
;   Add MPPRINT tag to PARINFO, CM, 19 Nov 2001
;   Add DOF keyword to DEFITER procedure, and print degrees of
;     freedom, CM, 28 Nov 2001
;   Add check to be sure MYFUNCT is a scalar string, CM, 14 Jan 2002
;   Addition of EXTERNAL_FJAC, EXTERNAL_FVEC keywords; ability to save
;     fitter's state from one call to the next; allow '(EXTERNAL)'
;     function name, which implies that user will supply function and
;     Jacobian at each iteration, CM, 10 Mar 2002
;   Documented EXTERNAL evaluation code, CM, 10 Mar 2002
;   Corrected signficant bug in the way that the STEP parameter, and
;     FIXED parameters interacted (Thanks Andrew Steffl), CM, 02 Apr
;     2002
;   Allow COVAR and PERROR keywords to be computed, even in case of
;     '(EXTERNAL)' function, 26 May 2002
;   Add NFREE and NPEGGED keywords; compute NPEGGED; compute DOF using
;     NFREE instead of n_elements(X), thanks to Kristian Kjaer, CM 11
;     Sep 2002
;   Hopefully PERROR is all positive now, CM 13 Sep 2002
;   Documented RELSTEP field of PARINFO (!!), CM, 25 Oct 2002
;   Error checking to detect missing start pars, CM 12 Apr 2003
;   Add DOF keyword to return degrees of freedom, CM, 30 June 2003
;   Always call ITERPROC in the final iteration; add ITERKEYSTOP
;     keyword, CM, 30 June 2003
;   Correct bug in MPFIT_LMPAR of singularity handling, which might
;     likely be fatal for one-parameter fits, CM, 21 Nov 2003
;     (with thanks to Peter Tuthill for the proper test case)
;   Minor documentation adjustment, 03 Feb 2004, CM
;   Correct small error in QR factorization when pivoting; document
;     the return values of QRFAC when pivoting, 21 May 2004, CM
;   Add MPFORMAT field to PARINFO, and correct behavior of interaction
;     between MPPRINT and PARNAME in MPFIT_DEFITERPROC (thanks to Tim
;     Robishaw), 23 May 2004, CM
;   Add the ITERPRINT keyword to allow redirecting output, 26 Sep
;     2004, CM
;   Correct MAXSTEP behavior in case of a negative parameter, 26 Sep
;     2004, CM
;   Fix bug in the parsing of MINSTEP/MAXSTEP, 10 Apr 2005, CM
;   Fix bug in the handling of upper/lower limits when the limit was
;     negative (the fitting code would never "stick" to the lower
;     limit), 29 Jun 2005, CM
;   Small documentation update for the TIED field, 05 Sep 2005, CM
;
;  $Id: mpfit.pro,v 1.2 2006/02/07 22:38:32 schlegel Exp $
;-
; Copyright (C) 1997-2003, 2004, 2005, Craig Markwardt
; This software is provided as is without any warranty whatsoever.
; Permission to use, copy, modify, and distribute modified or
; unmodified copies is granted, provided this copyright and disclaimer
; are included unchanged.
;-

pro mpfit_dummy
  ;; Enclose in a procedure so these are not defined in the main level
  FORWARD_FUNCTION mpfit_fdjac2, mpfit_enorm, mpfit_lmpar, mpfit_covar, $
    mpfit, mpfit_call

  COMMON mpfit_error, error_code  ;; For error passing to user function
  COMMON mpfit_config, mpconfig   ;; For internal error configrations
end

;; Reset profiling registers for another run.  By default, and when
;; uncommented, the profiling registers simply accumulate.

pro mpfit_resetprof
  common mpfit_profile, mpfit_profile_vals

  mpfit_profile_vals = { status: 1L, fdjac2: 0D, lmpar: 0D, mpfit: 0D, $
                         qrfac: 0D,  qrsolv: 0D, enorm: 0D}
  return
end

;; Following are machine constants that can be loaded once.  I have
;; found that bizarre underflow messages can be produced in each call
;; to MACHAR(), so this structure minimizes the number of calls to
;; one.

pro mpfit_setmachar, double=isdouble
  common mpfit_profile, profvals
  if n_elements(profvals) EQ 0 then mpfit_resetprof

  common mpfit_machar, mpfit_machar_vals

  ;; In earlier versions of IDL, MACHAR itself could produce a load of
  ;; error messages.  We try to mask some of that out here.
  if (!version.release) LT 5 then dummy = check_math(1, 1)

  mch = 0.
  mch = machar(double=keyword_set(isdouble))
  dmachep = mch.eps
  dmaxnum = mch.xmax
  dminnum = mch.xmin
  dmaxlog = alog(mch.xmax)
  dminlog = alog(mch.xmin)
  if keyword_set(isdouble) then $
    dmaxgam = 171.624376956302725D $
  else $
    dmaxgam = 171.624376956302725
  drdwarf = sqrt(dminnum*1.5) * 10
  drgiant = sqrt(dmaxnum) * 0.1

  mpfit_machar_vals = {machep: dmachep, maxnum: dmaxnum, minnum: dminnum, $
                       maxlog: dmaxlog, minlog: dminlog, maxgam: dmaxgam, $
                       rdwarf: drdwarf, rgiant: drgiant}

  if (!version.release) LT 5 then dummy = check_math(0, 0)

  return
end



;; Call user function or procedure, with _EXTRA or not, with
;; derivatives or not.
function mpfit_call, fcn, x, fjac, _EXTRA=extra

  on_error, 2
  common mpfit_config, mpconfig

  if keyword_set(mpconfig.qanytied) then mpfit_tie, x, mpconfig.ptied
    
  ;; Decide whether we are calling a procedure or function
  if mpconfig.proc then proc = 1 else proc = 0
  mpconfig.nfev = mpconfig.nfev + 1

  if proc then begin
      if n_params() EQ 3 then begin
          if n_elements(extra) GT 0 then $
            call_procedure, fcn, x, f, fjac, _EXTRA=extra $
          else $
            call_procedure, fcn, x, f, fjac
      endif else begin
          if n_elements(extra) GT 0 then $
            call_procedure, fcn, x, f, _EXTRA=extra $
          else $
            call_procedure, fcn, x, f
      endelse
  endif else begin
      if n_params() EQ 3 then begin
          if n_elements(extra) GT 0 then $
            f = call_function(fcn, x, fjac, _EXTRA=extra) $
          else $
            f = call_function(fcn, x, fjac)
      endif else begin
          if n_elements(extra) GT 0 then $
            f = call_function(fcn, x, _EXTRA=extra) $
          else $
            f = call_function(fcn, x)
      endelse
  endelse  

  if n_params() EQ 2 AND mpconfig.damp GT 0 then begin
      damp = mpconfig.damp(0)
      
      ;; Apply the damping if requested.  This replaces the residuals
      ;; with their hyperbolic tangent.  Thus residuals larger than
      ;; DAMP are essentially clipped.
      f = tanh(f/damp)
  endif

  return, f
end

function mpfit_fdjac2, fcn, x, fvec, step, ulimited, ulimit, dside, $
                 iflag=iflag, epsfcn=epsfcn, autoderiv=autoderiv, $
                 FUNCTARGS=fcnargs, xall=xall, ifree=ifree, dstep=dstep

  common mpfit_machar, machvals
  common mpfit_profile, profvals
  common mpfit_error, mperr

;  prof_start = systime(1)
  MACHEP0 = machvals.machep
  DWARF   = machvals.minnum

  if n_elements(epsfcn) EQ 0 then epsfcn = MACHEP0
  if n_elements(xall)   EQ 0 then xall = x
  if n_elements(ifree)  EQ 0 then ifree = lindgen(n_elements(xall))
  if n_elements(step)   EQ 0 then step = x * 0.
  nall = n_elements(xall)

  eps = sqrt(max([epsfcn, MACHEP0]));
  m = n_elements(fvec)
  n = n_elements(x)

  ;; Compute analytical derivative if requested
  if NOT keyword_set(autoderiv) then begin
      mperr = 0
      fjac = intarr(nall)
      fjac(ifree) = 1      ;; Specify which parameters need derivatives
      fp = mpfit_call(fcn, xall, fjac, _EXTRA=fcnargs)
      iflag = mperr

      if n_elements(fjac) NE m*nall then begin
          message, 'ERROR: Derivative matrix was not computed properly.', /info
          iflag = 1
;          profvals.fdjac2 = profvals.fdjac2 + (systime(1) - prof_start)
          return, 0
      endif

      ;; This definition is consistent with CURVEFIT
      ;; Sign error found (thanks Jesus Fernandez <fernande@irm.chu-caen.fr>)
      fjac = reform(-temporary(fjac), m, nall, /overwrite)

      ;; Select only the free parameters
      if n_elements(ifree) LT nall then $
        fjac = reform(fjac(*,ifree), m, n, /overwrite)
;      profvals.fdjac2 = profvals.fdjac2 + (systime(1) - prof_start)
      return, fjac
  endif

  fjac = make_array(m, n, value=fvec(0)*0.)
  fjac = reform(fjac, m, n, /overwrite)

  h = eps * abs(x)

  ;; if STEP is given, use that
  if n_elements(step) GT 0 then begin
      stepi = step(ifree)
      wh = where(stepi GT 0, ct)
      if ct GT 0 then h(wh) = stepi(wh)
  endif

  ;; if relative step is given, use that
  if n_elements(dstep) GT 0 then begin
      dstepi = dstep(ifree)
      wh = where(dstepi GT 0, ct)
      if ct GT 0 then h(wh) = abs(dstepi(wh)*x(wh))
  endif

  ;; In case any of the step values are zero
  wh = where(h EQ 0, ct)
  if ct GT 0 then h(wh) = eps

  ;; Reverse the sign of the step if we are up against the parameter
  ;; limit, or if the user requested it.
  mask = dside EQ -1
  if n_elements(ulimited) GT 0 AND n_elements(ulimit) GT 0 then $
    mask = mask OR (ulimited AND (x GT ulimit-h))
  wh = where(mask, ct)
  if ct GT 0 then h(wh) = -h(wh)

  ;; Loop through parameters, computing the derivative for each
  for j=0L, n-1 do begin
      xp = xall
      xp(ifree(j)) = xp(ifree(j)) + h(j)
      
      mperr = 0
      fp = mpfit_call(fcn, xp, _EXTRA=fcnargs)
      
      iflag = mperr
      if iflag LT 0 then return, !values.d_nan

      if abs(dside(j)) LE 1 then begin
          ;; COMPUTE THE ONE-SIDED DERIVATIVE
          ;; Note optimization fjac(0:*,j)
          fjac(0,j) = (fp-fvec)/h(j)

      endif else begin
          ;; COMPUTE THE TWO-SIDED DERIVATIVE
          xp(ifree(j)) = xall(ifree(j)) - h(j)

          mperr = 0
          fm = mpfit_call(fcn, xp, _EXTRA=fcnargs)
          
          iflag = mperr
          if iflag LT 0 then return, !values.d_nan
          
          ;; Note optimization fjac(0:*,j)
          fjac(0,j) = (fp-fm)/(2*h(j))
      endelse          
          
  endfor

;  profvals.fdjac2 = profvals.fdjac2 + (systime(1) - prof_start)
  return, fjac
end

function mpfit_enorm, vec

  ;; NOTE: it turns out that, for systems that have a lot of data
  ;; points, this routine is a big computing bottleneck.  The extended
  ;; computations that need to be done cannot be effectively
  ;; vectorized.  The introduction of the FASTNORM configuration
  ;; parameter allows the user to select a faster routine, which is 
  ;; based on TOTAL() alone.
  common mpfit_profile, profvals
;  prof_start = systime(1)

  common mpfit_config, mpconfig
; Very simple-minded sum-of-squares
  if n_elements(mpconfig) GT 0 then if mpconfig.fastnorm then begin
      ans = sqrt(total(vec^2))
      goto, TERMINATE
  endif

  common mpfit_machar, machvals

  agiant = machvals.rgiant / n_elements(vec)
  adwarf = machvals.rdwarf * n_elements(vec)

  ;; This is hopefully a compromise between speed and robustness.
  ;; Need to do this because of the possibility of over- or underflow.
  mx = max(vec, min=mn)
  mx = max(abs([mx,mn]))
  if mx EQ 0 then return, vec(0)*0.

  if mx GT agiant OR mx LT adwarf then ans = mx * sqrt(total((vec/mx)^2))$
  else                                 ans = sqrt( total(vec^2) )

  TERMINATE:
;  profvals.enorm = profvals.enorm + (systime(1) - prof_start)
  return, ans
end

;     **********
;
;     subroutine qrfac
;
;     this subroutine uses householder transformations with column
;     pivoting (optional) to compute a qr factorization of the
;     m by n matrix a. that is, qrfac determines an orthogonal
;     matrix q, a permutation matrix p, and an upper trapezoidal
;     matrix r with diagonal elements of nonincreasing magnitude,
;     such that a*p = q*r. the householder transformation for
;     column k, k = 1,2,...,min(m,n), is of the form
;
;         t
;     i - (1/u(k))*u*u
;
;     where u has zeros in the first k-1 positions. the form of
;     this transformation and the method of pivoting first
;     appeared in the corresponding linpack subroutine.
;
;     the subroutine statement is
;
; subroutine qrfac(m,n,a,lda,pivot,ipvt,lipvt,rdiag,acnorm,wa)
;
;     where
;
; m is a positive integer input variable set to the number
;   of rows of a.
;
; n is a positive integer input variable set to the number
;   of columns of a.
;
; a is an m by n array. on input a contains the matrix for
;   which the qr factorization is to be computed. on output
;   the strict upper trapezoidal part of a contains the strict
;   upper trapezoidal part of r, and the lower trapezoidal
;   part of a contains a factored form of q (the non-trivial
;   elements of the u vectors described above).
;
; lda is a positive integer input variable not less than m
;   which specifies the leading dimension of the array a.
;
; pivot is a logical input variable. if pivot is set true,
;   then column pivoting is enforced. if pivot is set false,
;   then no column pivoting is done.
;
; ipvt is an integer output array of length lipvt. ipvt
;   defines the permutation matrix p such that a*p = q*r.
;   column j of p is column ipvt(j) of the identity matrix.
;   if pivot is false, ipvt is not referenced.
;
; lipvt is a positive integer input variable. if pivot is false,
;   then lipvt may be as small as 1. if pivot is true, then
;   lipvt must be at least n.
;
; rdiag is an output array of length n which contains the
;   diagonal elements of r.
;
; acnorm is an output array of length n which contains the
;   norms of the corresponding columns of the input matrix a.
;   if this information is not needed, then acnorm can coincide
;   with rdiag.
;
; wa is a work array of length n. if pivot is false, then wa
;   can coincide with rdiag.
;
;     subprograms called
;
; minpack-supplied ... dpmpar,enorm
;
; fortran-supplied ... dmax1,dsqrt,min0
;
;     argonne national laboratory. minpack project. march 1980.
;     burton s. garbow, kenneth e. hillstrom, jorge j. more
;
;     **********
;
; PIVOTING / PERMUTING:
;
; Upon return, A(*,*) is in standard parameter order, A(*,IPVT) is in
; permuted order.
;
; RDIAG is in permuted order.
;
; ACNORM is in standard parameter order.
;
; NOTE: in IDL the factors appear slightly differently than described
; above.  The matrix A is still m x n where m >= n.  
;
; The "upper" triangular matrix R is actually stored in the strict
; lower left triangle of A under the standard notation of IDL.
;
; The reflectors that generate Q are in the upper trapezoid of A upon
; output.
;
;  EXAMPLE:  decompose the matrix [[9.,2.,6.],[4.,8.,7.]]
;    aa = [[9.,2.,6.],[4.,8.,7.]]
;    mpfit_qrfac, aa, aapvt, rdiag, aanorm
;     IDL> print, aa
;          1.81818*     0.181818*     0.545455*
;         -8.54545+      1.90160*     0.432573*
;     IDL> print, rdiag
;         -11.0000+     -7.48166+
;
; The components marked with a * are the components of the
; reflectors, and those marked with a + are components of R.
;
; To reconstruct Q and R we proceed as follows.  First R.
;    r = fltarr(m, n)
;    for i = 0, n-1 do r(0:i,i) = aa(0:i,i)  ; fill in lower diag
;    r(lindgen(n)*(m+1)) = rdiag
;
; Next, Q, which are composed from the reflectors.  Each reflector v
; is taken from the upper trapezoid of aa, and converted to a matrix
; via (I - 2 vT . v / (v . vT)).
;
;   hh = ident                                    ;; identity matrix
;   for i = 0, n-1 do begin
;    v = aa(*,i) & if i GT 0 then v(0:i-1) = 0    ;; extract reflector
;    hh = hh ## (ident - 2*(v # v)/total(v * v))  ;; generate matrix
;   endfor
;
; Test the result:
;    IDL> print, hh ## transpose(r)
;          9.00000      4.00000
;          2.00000      8.00000
;          6.00000      7.00000
;
; Note that it is usually never necessary to form the Q matrix
; explicitly, and MPFIT does not.

pro mpfit_qrfac, a, ipvt, rdiag, acnorm, pivot=pivot

  sz = size(a)
  m = sz(1)
  n = sz(2)

  common mpfit_machar, machvals
  common mpfit_profile, profvals
;  prof_start = systime(1)

  MACHEP0 = machvals.machep
  DWARF   = machvals.minnum
  
  ;; Compute the initial column norms and initialize arrays
  acnorm = make_array(n, value=a(0)*0.)
  for j = 0L, n-1 do $
    acnorm(j) = mpfit_enorm(a(*,j))
  rdiag = acnorm
  wa = rdiag
  ipvt = lindgen(n)

  ;; Reduce a to r with householder transformations
  minmn = min([m,n])
  for j = 0L, minmn-1 do begin
      if NOT keyword_set(pivot) then goto, HOUSE1
      
      ;; Bring the column of largest norm into the pivot position
      rmax = max(rdiag(j:*))
      kmax = where(rdiag(j:*) EQ rmax, ct) + j
      if ct LE 0 then goto, HOUSE1
      kmax = kmax(0)
      
      ;; Exchange rows via the pivot only.  Avoid actually exchanging
      ;; the rows, in case there is lots of memory transfer.  The
      ;; exchange occurs later, within the body of MPFIT, after the
      ;; extraneous columns of the matrix have been shed.
      if kmax NE j then begin
          temp     = ipvt(j)   & ipvt(j)    = ipvt(kmax) & ipvt(kmax)  = temp
          rdiag(kmax) = rdiag(j)
          wa(kmax)    = wa(j)
      endif
      
      HOUSE1:

      ;; Compute the householder transformation to reduce the jth
      ;; column of A to a multiple of the jth unit vector
      lj     = ipvt(j)
      ajj    = a(j:*,lj)
      ajnorm = mpfit_enorm(ajj)
      if ajnorm EQ 0 then goto, NEXT_ROW
      if a(j,lj) LT 0 then ajnorm = -ajnorm
      
      ajj     = ajj / ajnorm
      ajj(0)  = ajj(0) + 1
      ;; *** Note optimization a(j:*,j)
      a(j,lj) = ajj
      
      ;; Apply the transformation to the remaining columns
      ;; and update the norms

      ;; NOTE to SELF: tried to optimize this by removing the loop,
      ;; but it actually got slower.  Reverted to "for" loop to keep
      ;; it simple.
      if j+1 LT n then begin
          for k=j+1, n-1 do begin
              lk = ipvt(k)
              ajk = a(j:*,lk)
              ;; *** Note optimization a(j:*,lk) 
              ;; (corrected 20 Jul 2000)
              if a(j,lj) NE 0 then $
                a(j,lk) = ajk - ajj * total(ajk*ajj)/a(j,lj)

              if keyword_set(pivot) AND rdiag(k) NE 0 then begin
                  temp = a(j,lk)/rdiag(k)
                  rdiag(k) = rdiag(k) * sqrt((1.-temp^2) > 0)
                  temp = rdiag(k)/wa(k)
                  if 0.05D*temp*temp LE MACHEP0 then begin
                      rdiag(k) = mpfit_enorm(a(j+1:*,lk))
                      wa(k) = rdiag(k)
                  endif
              endif
          endfor
      endif

      NEXT_ROW:
      rdiag(j) = -ajnorm
  endfor

;  profvals.qrfac = profvals.qrfac + (systime(1) - prof_start)
  return
end

;     **********
;
;     subroutine qrsolv
;
;     given an m by n matrix a, an n by n diagonal matrix d,
;     and an m-vector b, the problem is to determine an x which
;     solves the system
;
;           a*x = b ,     d*x = 0 ,
;
;     in the least squares sense.
;
;     this subroutine completes the solution of the problem
;     if it is provided with the necessary information from the
;     qr factorization, with column pivoting, of a. that is, if
;     a*p = q*r, where p is a permutation matrix, q has orthogonal
;     columns, and r is an upper triangular matrix with diagonal
;     elements of nonincreasing magnitude, then qrsolv expects
;     the full upper triangle of r, the permutation matrix p,
;     and the first n components of (q transpose)*b. the system
;     a*x = b, d*x = 0, is then equivalent to
;
;                  t       t
;           r*z = q *b ,  p *d*p*z = 0 ,
;
;     where x = p*z. if this system does not have full rank,
;     then a least squares solution is obtained. on output qrsolv
;     also provides an upper triangular matrix s such that
;
;            t   t               t
;           p *(a *a + d*d)*p = s *s .
;
;     s is computed within qrsolv and may be of separate interest.
;
;     the subroutine statement is
;
;       subroutine qrsolv(n,r,ldr,ipvt,diag,qtb,x,sdiag,wa)
;
;     where
;
;       n is a positive integer input variable set to the order of r.
;
;       r is an n by n array. on input the full upper triangle
;         must contain the full upper triangle of the matrix r.
;         on output the full upper triangle is unaltered, and the
;         strict lower triangle contains the strict upper triangle
;         (transposed) of the upper triangular matrix s.
;
;       ldr is a positive integer input variable not less than n
;         which specifies the leading dimension of the array r.
;
;       ipvt is an integer input array of length n which defines the
;         permutation matrix p such that a*p = q*r. column j of p
;         is column ipvt(j) of the identity matrix.
;
;       diag is an input array of length n which must contain the
;         diagonal elements of the matrix d.
;
;       qtb is an input array of length n which must contain the first
;         n elements of the vector (q transpose)*b.
;
;       x is an output array of length n which contains the least
;         squares solution of the system a*x = b, d*x = 0.
;
;       sdiag is an output array of length n which contains the
;         diagonal elements of the upper triangular matrix s.
;
;       wa is a work array of length n.
;
;     subprograms called
;
;       fortran-supplied ... dabs,dsqrt
;
;     argonne national laboratory. minpack project. march 1980.
;     burton s. garbow, kenneth e. hillstrom, jorge j. more
;
pro mpfit_qrsolv, r, ipvt, diag, qtb, x, sdiag

  sz = size(r)
  m = sz(1)
  n = sz(2)
  delm = lindgen(n) * (m+1) ;; Diagonal elements of r

  common mpfit_profile, profvals
;  prof_start = systime(1)

  ;; copy r and (q transpose)*b to preserve input and initialize s.
  ;; in particular, save the diagonal elements of r in x.

  for j = 0L, n-1 do $
    r(j:n-1,j) = r(j,j:n-1)
  x = r(delm)
  wa = qtb
  ;; Below may look strange, but it's so we can keep the right precision
  zero = qtb(0)*0.
  half = zero + 0.5
  quart = zero + 0.25

  ;; Eliminate the diagonal matrix d using a givens rotation
  for j = 0L, n-1 do begin
      l = ipvt(j)
      if diag(l) EQ 0 then goto, STORE_RESTORE
      sdiag(j:*) = 0
      sdiag(j) = diag(l)

      ;; The transformations to eliminate the row of d modify only a
      ;; single element of (q transpose)*b beyond the first n, which
      ;; is initially zero.

      qtbpj = zero
      for k = j, n-1 do begin
          if sdiag(k) EQ 0 then goto, ELIM_NEXT_LOOP
          if abs(r(k,k)) LT abs(sdiag(k)) then begin
              cotan  = r(k,k)/sdiag(k)
              sine   = half/sqrt(quart + quart*cotan*cotan)
              cosine = sine*cotan
          endif else begin
              tang   = sdiag(k)/r(k,k)
              cosine = half/sqrt(quart + quart*tang*tang)
              sine   = cosine*tang
          endelse
          
          ;; Compute the modified diagonal element of r and the
          ;; modified element of ((q transpose)*b,0).
          r(k,k) = cosine*r(k,k) + sine*sdiag(k)
          temp = cosine*wa(k) + sine*qtbpj
          qtbpj = -sine*wa(k) + cosine*qtbpj
          wa(k) = temp

          ;; Accumulate the transformation in the row of s
          if n GT k+1 then begin
              temp = cosine*r(k+1:n-1,k) + sine*sdiag(k+1:n-1)
              sdiag(k+1:n-1) = -sine*r(k+1:n-1,k) + cosine*sdiag(k+1:n-1)
              r(k+1:n-1,k) = temp
          endif
ELIM_NEXT_LOOP:
      endfor

STORE_RESTORE:
      sdiag(j) = r(j,j)
      r(j,j) = x(j)
  endfor

  ;; Solve the triangular system for z.  If the system is singular
  ;; then obtain a least squares solution
  nsing = n
  wh = where(sdiag EQ 0, ct)
  if ct GT 0 then begin
      nsing = wh(0)
      wa(nsing:*) = 0
  endif

  if nsing GE 1 then begin
      wa(nsing-1) = wa(nsing-1)/sdiag(nsing-1) ;; Degenerate case
      ;; *** Reverse loop ***
      for j=nsing-2,0,-1 do begin  
          sum = total(r(j+1:nsing-1,j)*wa(j+1:nsing-1))
          wa(j) = (wa(j)-sum)/sdiag(j)
      endfor
  endif

  ;; Permute the components of z back to components of x
  x(ipvt) = wa

;  profvals.qrsolv = profvals.qrsolv + (systime(1) - prof_start)
  return
end
      
  
;
;     subroutine lmpar
;
;     given an m by n matrix a, an n by n nonsingular diagonal
;     matrix d, an m-vector b, and a positive number delta,
;     the problem is to determine a value for the parameter
;     par such that if x solves the system
;
;     a*x = b ,   sqrt(par)*d*x = 0 ,
;
;     in the least squares sense, and dxnorm is the euclidean
;     norm of d*x, then either par is zero and
;
;     (dxnorm-delta) .le. 0.1*delta ,
;
;     or par is positive and
;
;     abs(dxnorm-delta) .le. 0.1*delta .
;
;     this subroutine completes the solution of the problem
;     if it is provided with the necessary information from the
;     qr factorization, with column pivoting, of a. that is, if
;     a*p = q*r, where p is a permutation matrix, q has orthogonal
;     columns, and r is an upper triangular matrix with diagonal
;     elements of nonincreasing magnitude, then lmpar expects
;     the full upper triangle of r, the permutation matrix p,
;     and the first n components of (q transpose)*b. on output
;     lmpar also provides an upper triangular matrix s such that
;
;      t   t         t
;     p *(a *a + par*d*d)*p = s *s .
;
;     s is employed within lmpar and may be of separate interest.
;
;     only a few iterations are generally needed for convergence
;     of the algorithm. if, however, the limit of 10 iterations
;     is reached, then the output par will contain the best
;     value obtained so far.
;
;     the subroutine statement is
;
; subroutine lmpar(n,r,ldr,ipvt,diag,qtb,delta,par,x,sdiag,
;      wa1,wa2)
;
;     where
;
; n is a positive integer input variable set to the order of r.
;
; r is an n by n array. on input the full upper triangle
;   must contain the full upper triangle of the matrix r.
;   on output the full upper triangle is unaltered, and the
;   strict lower triangle contains the strict upper triangle
;   (transposed) of the upper triangular matrix s.
;
; ldr is a positive integer input variable not less than n
;   which specifies the leading dimension of the array r.
;
; ipvt is an integer input array of length n which defines the
;   permutation matrix p such that a*p = q*r. column j of p
;   is column ipvt(j) of the identity matrix.
;
; diag is an input array of length n which must contain the
;   diagonal elements of the matrix d.
;
; qtb is an input array of length n which must contain the first
;   n elements of the vector (q transpose)*b.
;
; delta is a positive input variable which specifies an upper
;   bound on the euclidean norm of d*x.
;
; par is a nonnegative variable. on input par contains an
;   initial estimate of the levenberg-marquardt parameter.
;   on output par contains the final estimate.
;
; x is an output array of length n which contains the least
;   squares solution of the system a*x = b, sqrt(par)*d*x = 0,
;   for the output par.
;
; sdiag is an output array of length n which contains the
;   diagonal elements of the upper triangular matrix s.
;
; wa1 and wa2 are work arrays of length n.
;
;     subprograms called
;
; minpack-supplied ... dpmpar,enorm,qrsolv
;
; fortran-supplied ... dabs,dmax1,dmin1,dsqrt
;
;     argonne national laboratory. minpack project. march 1980.
;     burton s. garbow, kenneth e. hillstrom, jorge j. more
;
function mpfit_lmpar, r, ipvt, diag, qtb, delta, x, sdiag, par=par

  common mpfit_machar, machvals
  common mpfit_profile, profvals
;  prof_start = systime(1)

  MACHEP0 = machvals.machep
  DWARF   = machvals.minnum

  sz = size(r)
  m = sz(1)
  n = sz(2)
  delm = lindgen(n) * (m+1) ;; Diagonal elements of r

  ;; Compute and store in x the gauss-newton direction.  If the
  ;; jacobian is rank-deficient, obtain a least-squares solution
  nsing = n
  wa1 = qtb
  wh = where(r(delm) EQ 0, ct)
  if ct GT 0 then begin
      nsing = wh(0)
      wa1(wh(0):*) = 0
  endif

  if nsing GE 1 then begin
      ;; *** Reverse loop ***
      for j=nsing-1,0,-1 do begin  
          wa1(j) = wa1(j)/r(j,j)
          if (j-1 GE 0) then $
            wa1(0:(j-1)) = wa1(0:(j-1)) - r(0:(j-1),j)*wa1(j)
      endfor
  endif

  ;; Note: ipvt here is a permutation array
  x(ipvt) = wa1

  ;; Initialize the iteration counter.  Evaluate the function at the
  ;; origin, and test for acceptance of the gauss-newton direction
  iter = 0L
  wa2 = diag * x
  dxnorm = mpfit_enorm(wa2)
  fp = dxnorm - delta
  if fp LE 0.1*delta then goto, TERMINATE

  ;; If the jacobian is not rank deficient, the newton step provides a
  ;; lower bound, parl, for the zero of the function.  Otherwise set
  ;; this bound to zero.
  
  zero = wa2(0)*0.
  parl = zero
  if nsing GE n then begin
      wa1 = diag(ipvt)*wa2(ipvt)/dxnorm

      wa1(0) = wa1(0) / r(0,0) ;; Degenerate case 
      for j=1L, n-1 do begin   ;; Note "1" here, not zero
          sum = total(r(0:(j-1),j)*wa1(0:(j-1)))
          wa1(j) = (wa1(j) - sum)/r(j,j)
      endfor

      temp = mpfit_enorm(wa1)
      parl = ((fp/delta)/temp)/temp
  endif

  ;; Calculate an upper bound, paru, for the zero of the function
  for j=0, n-1 do begin
      sum = total(r(0:j,j)*qtb(0:j))
      wa1(j) = sum/diag(ipvt(j))
  endfor
  gnorm = mpfit_enorm(wa1)
  paru  = gnorm/delta
  if paru EQ 0 then paru = DWARF/min([delta,0.1])

  ;; If the input par lies outside of the interval (parl,paru), set
  ;; par to the closer endpoint

  par = max([par,parl])
  par = min([par,paru])
  if par EQ 0 then par = gnorm/dxnorm

  ;; Beginning of an interation
  ITERATION:
  iter = iter + 1
  
  ;; Evaluate the function at the current value of par
  if par EQ 0 then par = max([DWARF, paru*0.001])
  temp = sqrt(par)
  wa1 = temp * diag
  mpfit_qrsolv, r, ipvt, wa1, qtb, x, sdiag
  wa2 = diag*x
  dxnorm = mpfit_enorm(wa2)
  temp = fp
  fp = dxnorm - delta

  if (abs(fp) LE 0.1D*delta) $
    OR ((parl EQ 0) AND (fp LE temp) AND (temp LT 0)) $
    OR (iter EQ 10) then goto, TERMINATE

  ;; Compute the newton correction
  wa1 = diag(ipvt)*wa2(ipvt)/dxnorm

  for j=0,n-2 do begin
      wa1(j) = wa1(j)/sdiag(j)
      wa1(j+1:n-1) = wa1(j+1:n-1) - r(j+1:n-1,j)*wa1(j)
  endfor
  wa1(n-1) = wa1(n-1)/sdiag(n-1) ;; Degenerate case

  temp = mpfit_enorm(wa1)
  parc = ((fp/delta)/temp)/temp

  ;; Depending on the sign of the function, update parl or paru
  if fp GT 0 then parl = max([parl,par])
  if fp LT 0 then paru = min([paru,par])

  ;; Compute an improved estimate for par
  par = max([parl, par+parc])

  ;; End of an iteration
  goto, ITERATION
  
TERMINATE:
  ;; Termination
;  profvals.lmpar = profvals.lmpar + (systime(1) - prof_start)
  if iter EQ 0 then return, par(0)*0.
  return, par
end

;; Procedure to tie one parameter to another.
pro mpfit_tie, p, _ptied
  if n_elements(_ptied) EQ 0 then return
  if n_elements(_ptied) EQ 1 then if _ptied(0) EQ '' then return
  for _i = 0L, n_elements(_ptied)-1 do begin
      if _ptied(_i) EQ '' then goto, NEXT_TIE
      _cmd = 'p('+strtrim(_i,2)+') = '+_ptied(_i)
      _err = execute(_cmd)
      if _err EQ 0 then begin
          message, 'ERROR: Tied expression "'+_cmd+'" failed.'
          return
      endif
      NEXT_TIE:
  endfor
end

;; Default print procedure
pro mpfit_defprint, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, $
                    p11, p12, p13, p14, p15, p16, p17, p18, $
                    format=format, unit=unit0, _EXTRA=extra

  if n_elements(unit0) EQ 0 then unit = -1 else unit = round(unit0(0))
  if n_params() EQ 0 then printf, unit, '' $
  else if n_params() EQ 1 then printf, unit, p1, format=format $
  else if n_params() EQ 2 then printf, unit, p1, p2, format=format $
  else if n_params() EQ 3 then printf, unit, p1, p2, p3, format=format $
  else if n_params() EQ 4 then printf, unit, p1, p2, p4, format=format 

  return
end


;; Default procedure to be called every iteration.  It simply prints
;; the parameter values.
pro mpfit_defiter, fcn, x, iter, fnorm, FUNCTARGS=fcnargs, $
                   quiet=quiet, iterstop=iterstop, iterkeybyte=iterkeybyte, $
                   parinfo=parinfo, iterprint=iterprint0, $
                   format=fmt, pformat=pformat, dof=dof0, _EXTRA=iterargs

  common mpfit_error, mperr
  mperr = 0
  if keyword_set(quiet) then goto, DO_ITERSTOP
  if n_params() EQ 3 then begin
      fvec = mpfit_call(fcn, x, _EXTRA=fcnargs)
      fnorm = mpfit_enorm(fvec)^2
  endif

  ;; Determine which parameters to print
  nprint = n_elements(x)
  iprint = lindgen(nprint)

  if n_elements(iterprint0) EQ 0 then iterprint = 'MPFIT_DEFPRINT' $
  else iterprint = strtrim(iterprint0(0),2)

  if n_elements(dof0) EQ 0 then dof = 1L else dof = floor(dof0(0))
  call_procedure, iterprint, iter, fnorm, dof, $
    format='("Iter ",I6,"   CHI-SQUARE = ",G15.8,"          DOF = ",I0)', $
    _EXTRA=iterargs
  if n_elements(fmt) GT 0 then begin
      call_procedure, iterprint, x, format=fmt, _EXTRA=iterargs
  endif else begin
      if n_elements(pformat) EQ 0 then pformat = '(G20.6)'
      parname = 'P('+strtrim(iprint,2)+')'
      pformats = strarr(nprint) + pformat

      if n_elements(parinfo) GT 0 then begin
          parinfo_tags = tag_names(parinfo)
          wh = where(parinfo_tags EQ 'PARNAME', ct)
          if ct EQ 1 then begin
              wh = where(parinfo.parname NE '', ct)
              if ct GT 0 then $
                parname(wh) = strmid(parinfo(wh).parname,0,25)
          endif
          wh = where(parinfo_tags EQ 'MPPRINT', ct)
          if ct EQ 1 then begin
              iprint = where(parinfo.mpprint EQ 1, nprint)
              if nprint EQ 0 then goto, DO_ITERSTOP
          endif
          wh = where(parinfo_tags EQ 'MPFORMAT', ct)
          if ct EQ 1 then begin
              wh = where(parinfo.mpformat NE '', ct)
              if ct GT 0 then pformats(wh) = parinfo(wh).mpformat
          endif
      endif

      for i = 0, nprint-1 do begin
          call_procedure, iterprint, parname(iprint(i)), x(iprint(i)), $
            format='("    ",A0," = ",'+pformats(iprint(i))+')', $
            _EXTRA=iterargs
      endfor
  endelse

  DO_ITERSTOP:
  if n_elements(iterkeybyte) EQ 0 then iterkeybyte = 7b
  if keyword_set(iterstop) then begin
      k = get_kbrd(0)
      if k EQ string(iterkeybyte(0)) then begin
          message, 'WARNING: minimization not complete', /info
          print, 'Do you want to terminate this procedure? (y/n)', $
            format='(A,$)'
          k = ''
          read, k
          if strupcase(strmid(k,0,1)) EQ 'Y' then begin
              message, 'WARNING: Procedure is terminating.', /info
              mperr = -1
          endif
      endif
  endif

  return
end

;; Procedure to parse the parameter values in PARINFO
pro mpfit_parinfo, parinfo, tnames, tag, values, default=def, status=status, $
                   n_param=n

  status = 0
  if n_elements(n) EQ 0 then n = n_elements(parinfo)

  if n EQ 0 then begin
      if n_elements(def) EQ 0 then return
      values = def
      status = 1
      return
  endif

  if n_elements(parinfo) EQ 0 then goto, DO_DEFAULT
  if n_elements(tnames) EQ 0 then tnames = tag_names(parinfo)
  wh = where(tnames EQ tag, ct)

  if ct EQ 0 then begin
      DO_DEFAULT:
      if n_elements(def) EQ 0 then return
      values = make_array(n, value=def(0))
      values(0) = def
  endif else begin
      values = parinfo.(wh(0))
  endelse

  status = 1
  return
end


;     **********
;
;     subroutine covar
;
;     given an m by n matrix a, the problem is to determine
;     the covariance matrix corresponding to a, defined as
;
;                    t
;           inverse(a *a) .
;
;     this subroutine completes the solution of the problem
;     if it is provided with the necessary information from the
;     qr factorization, with column pivoting, of a. that is, if
;     a*p = q*r, where p is a permutation matrix, q has orthogonal
;     columns, and r is an upper triangular matrix with diagonal
;     elements of nonincreasing magnitude, then covar expects
;     the full upper triangle of r and the permutation matrix p.
;     the covariance matrix is then computed as
;
;                      t     t
;           p*inverse(r *r)*p  .
;
;     if a is nearly rank deficient, it may be desirable to compute
;     the covariance matrix corresponding to the linearly independent
;     columns of a. to define the numerical rank of a, covar uses
;     the tolerance tol. if l is the largest integer such that
;
;           abs(r(l,l)) .gt. tol*abs(r(1,1)) ,
;
;     then covar computes the covariance matrix corresponding to
;     the first l columns of r. for k greater than l, column
;     and row ipvt(k) of the covariance matrix are set to zero.
;
;     the subroutine statement is
;
;       subroutine covar(n,r,ldr,ipvt,tol,wa)
;
;     where
;
;       n is a positive integer input variable set to the order of r.
;
;       r is an n by n array. on input the full upper triangle must
;         contain the full upper triangle of the matrix r. on output
;         r contains the square symmetric covariance matrix.
;
;       ldr is a positive integer input variable not less than n
;         which specifies the leading dimension of the array r.
;
;       ipvt is an integer input array of length n which defines the
;         permutation matrix p such that a*p = q*r. column j of p
;         is column ipvt(j) of the identity matrix.
;
;       tol is a nonnegative input variable used to define the
;         numerical rank of a in the manner described above.
;
;       wa is a work array of length n.
;
;     subprograms called
;
;       fortran-supplied ... dabs
;
;     argonne national laboratory. minpack project. august 1980.
;     burton s. garbow, kenneth e. hillstrom, jorge j. more
;
;     **********
function mpfit_covar, rr, ipvt, tol=tol

  sz = size(rr)
  if sz(0) NE 2 then begin
      message, 'ERROR: r must be a two-dimensional matrix'
      return, -1L
  endif
  n = sz(1)
  if n NE sz(2) then begin
      message, 'ERROR: r must be a square matrix'
      return, -1L
  endif

  zero = rr(0) * 0.
  one  = zero  + 1.
  if n_elements(ipvt) EQ 0 then ipvt = lindgen(n)
  r = rr
  r = reform(rr, n, n, /overwrite)
  
  ;; Form the inverse of r in the full upper triangle of r
  l = -1L
  if n_elements(tol) EQ 0 then tol = one*1.E-14
  tolr = tol * abs(r(0,0))
  for k = 0L, n-1 do begin
      if abs(r(k,k)) LE tolr then goto, INV_END_LOOP
      r(k,k) = one/r(k,k)
      for j = 0L, k-1 do begin
          temp = r(k,k) * r(j,k)
          r(j,k) = zero
          r(0,k) = r(0:j,k) - temp*r(0:j,j)
      endfor
      l = k
  endfor
  INV_END_LOOP:

  ;; Form the full upper triangle of the inverse of (r transpose)*r
  ;; in the full upper triangle of r
  if l GE 0 then $
    for k = 0L, l do begin
      for j = 0L, k-1 do begin
          temp = r(j,k)
          r(0,j) = r(0:j,j) + temp*r(0:j,k)
      endfor
      temp = r(k,k)
      r(0,k) = temp * r(0:k,k)
  endfor

  ;; Form the full lower triangle of the covariance matrix
  ;; in the strict lower triangle of r and in wa
  wa = replicate(r(0,0), n)
  for j = 0L, n-1 do begin
      jj = ipvt(j)
      sing = j GT l
      for i = 0L, j do begin
          if sing then r(i,j) = zero
          ii = ipvt(i)
          if ii GT jj then r(ii,jj) = r(i,j)
          if ii LT jj then r(jj,ii) = r(i,j)
      endfor
      wa(jj) = r(j,j)
  endfor

  ;; Symmetrize the covariance matrix in r
  for j = 0L, n-1 do begin
      r(0:j,j) = r(j,0:j)
      r(j,j) = wa(j)
  endfor

  return, r
end

;     **********
;
;     subroutine lmdif
;
;     the purpose of lmdif is to minimize the sum of the squares of
;     m nonlinear functions in n variables by a modification of
;     the levenberg-marquardt algorithm. the user must provide a
;     subroutine which calculates the functions. the jacobian is
;     then calculated by a forward-difference approximation.
;
;     the subroutine statement is
;
; subroutine lmdif(fcn,m,n,x,fvec,ftol,xtol,gtol,maxfev,epsfcn,
;      diag,mode,factor,nprint,info,nfev,fjac,
;      ldfjac,ipvt,qtf,wa1,wa2,wa3,wa4)
;
;     where
;
; fcn is the name of the user-supplied subroutine which
;   calculates the functions. fcn must be declared
;   in an external statement in the user calling
;   program, and should be written as follows.
;
;   subroutine fcn(m,n,x,fvec,iflag)
;   integer m,n,iflag
;   double precision x(n),fvec(m)
;   ----------
;   calculate the functions at x and
;   return this vector in fvec.
;   ----------
;   return
;   end
;
;   the value of iflag should not be changed by fcn unless
;   the user wants to terminate execution of lmdif.
;   in this case set iflag to a negative integer.
;
; m is a positive integer input variable set to the number
;   of functions.
;
; n is a positive integer input variable set to the number
;   of variables. n must not exceed m.
;
; x is an array of length n. on input x must contain
;   an initial estimate of the solution vector. on output x
;   contains the final estimate of the solution vector.
;
; fvec is an output array of length m which contains
;   the functions evaluated at the output x.
;
; ftol is a nonnegative input variable. termination
;   occurs when both the actual and predicted relative
;   reductions in the sum of squares are at most ftol.
;   therefore, ftol measures the relative error desired
;   in the sum of squares.
;
; xtol is a nonnegative input variable. termination
;   occurs when the relative error between two consecutive
;   iterates is at most xtol. therefore, xtol measures the
;   relative error desired in the approximate solution.
;
; gtol is a nonnegative input variable. termination
;   occurs when the cosine of the angle between fvec and
;   any column of the jacobian is at most gtol in absolute
;   value. therefore, gtol measures the orthogonality
;   desired between the function vector and the columns
;   of the jacobian.
;
; maxfev is a positive integer input variable. termination
;   occurs when the number of calls to fcn is at least
;   maxfev by the end of an iteration.
;
; epsfcn is an input variable used in determining a suitable
;   step length for the forward-difference approximation. this
;   approximation assumes that the relative errors in the
;   functions are of the order of epsfcn. if epsfcn is less
;   than the machine precision, it is assumed that the relative
;   errors in the functions are of the order of the machine
;   precision.
;
; diag is an array of length n. if mode = 1 (see
;   below), diag is internally set. if mode = 2, diag
;   must contain positive entries that serve as
;   multiplicative scale factors for the variables.
;
; mode is an integer input variable. if mode = 1, the
;   variables will be scaled internally. if mode = 2,
;   the scaling is specified by the input diag. other
;   values of mode are equivalent to mode = 1.
;
; factor is a positive input variable used in determining the
;   initial step bound. this bound is set to the product of
;   factor and the euclidean norm of diag*x if nonzero, or else
;   to factor itself. in most cases factor should lie in the
;   interval (.1,100.). 100. is a generally recommended value.
;
; nprint is an integer input variable that enables controlled
;   printing of iterates if it is positive. in this case,
;   fcn is called with iflag = 0 at the beginning of the first
;   iteration and every nprint iterations thereafter and
;   immediately prior to return, with x and fvec available
;   for printing. if nprint is not positive, no special calls
;   of fcn with iflag = 0 are made.
;
; info is an integer output variable. if the user has
;   terminated execution, info is set to the (negative)
;   value of iflag. see description of fcn. otherwise,
;   info is set as follows.
;
;   info = 0  improper input parameters.
;
;   info = 1  both actual and predicted relative reductions
;       in the sum of squares are at most ftol.
;
;   info = 2  relative error between two consecutive iterates
;       is at most xtol.
;
;   info = 3  conditions for info = 1 and info = 2 both hold.
;
;   info = 4  the cosine of the angle between fvec and any
;       column of the jacobian is at most gtol in
;       absolute value.
;
;   info = 5  number of calls to fcn has reached or
;       exceeded maxfev.
;
;   info = 6  ftol is too small. no further reduction in
;       the sum of squares is possible.
;
;   info = 7  xtol is too small. no further improvement in
;       the approximate solution x is possible.
;
;   info = 8  gtol is too small. fvec is orthogonal to the
;       columns of the jacobian to machine precision.
;
; nfev is an integer output variable set to the number of
;   calls to fcn.
;
; fjac is an output m by n array. the upper n by n submatrix
;   of fjac contains an upper triangular matrix r with
;   diagonal elements of nonincreasing magnitude such that
;
;    t     t     t
;   p *(jac *jac)*p = r *r,
;
;   where p is a permutation matrix and jac is the final
;   calculated jacobian. column j of p is column ipvt(j)
;   (see below) of the identity matrix. the lower trapezoidal
;   part of fjac contains information generated during
;   the computation of r.
;
; ldfjac is a positive integer input variable not less than m
;   which specifies the leading dimension of the array fjac.
;
; ipvt is an integer output array of length n. ipvt
;   defines a permutation matrix p such that jac*p = q*r,
;   where jac is the final calculated jacobian, q is
;   orthogonal (not stored), and r is upper triangular
;   with diagonal elements of nonincreasing magnitude.
;   column j of p is column ipvt(j) of the identity matrix.
;
; qtf is an output array of length n which contains
;   the first n elements of the vector (q transpose)*fvec.
;
; wa1, wa2, and wa3 are work arrays of length n.
;
; wa4 is a work array of length m.
;
;     subprograms called
;
; user-supplied ...... fcn
;
; minpack-supplied ... dpmpar,enorm,fdjac2,lmpar,qrfac
;
; fortran-supplied ... dabs,dmax1,dmin1,dsqrt,mod
;
;     argonne national laboratory. minpack project. march 1980.
;     burton s. garbow, kenneth e. hillstrom, jorge j. more
;
;     **********
function mpfit, fcn, xall, FUNCTARGS=fcnargs, SCALE_FCN=scalfcn, $
                ftol=ftol, xtol=xtol, gtol=gtol, epsfcn=epsfcn, resdamp=damp, $
                nfev=nfev, maxiter=maxiter, errmsg=errmsg, $
                factor=factor, nprint=nprint, STATUS=info, $
                iterproc=iterproc, iterargs=iterargs, iterstop=ss,$
                iterkeystop=iterkeystop, $
                niter=iter, nfree=nfree, npegged=npegged, dof=dof, $
                diag=diag, rescale=rescale, autoderivative=autoderiv, $
                perror=perror, covar=covar, nocovar=nocovar, bestnorm=fnorm, $
                parinfo=parinfo, quiet=quiet, nocatch=nocatch, $
                fastnorm=fastnorm, proc=proc, query=query, $
                external_state=state, external_init=extinit, $
                external_fvec=efvec, external_fjac=efjac

  if keyword_set(query) then return, 1

  if n_params() EQ 0 then begin
      message, "USAGE: PARMS = MPFIT('MYFUNCT', START_PARAMS, ... )", /info
      return, !values.d_nan
  endif
  
  ;; Use of double here not a problem since f/x/gtol are all only used
  ;; in comparisons
  if n_elements(ftol) EQ 0 then ftol = 1.D-10
  if n_elements(xtol) EQ 0 then xtol = 1.D-10
  if n_elements(gtol) EQ 0 then gtol = 1.D-10
  if n_elements(factor) EQ 0 then factor = 100.
  if n_elements(nprint) EQ 0 then nprint = 1
  if n_elements(iterproc) EQ 0 then iterproc = 'MPFIT_DEFITER'
  if n_elements(autoderiv) EQ 0 then autoderiv = 1
  if n_elements(fastnorm) EQ 0 then fastnorm = 0
  if n_elements(damp) EQ 0 then damp = 0 else damp = damp(0)

  ;; These are special configuration parameters that can't be easily
  ;; passed by MPFIT directly.
  ;;  FASTNORM - decide on which sum-of-squares technique to use (1)
  ;;             is fast, (0) is slower
  ;;  PROC - user routine is a procedure (1) or function (0)
  ;;  QANYTIED - set to 1 if any parameters are TIED, zero if none
  ;;  PTIED - array of strings, one for each parameter
  common mpfit_config, mpconfig
  mpconfig = {fastnorm: keyword_set(fastnorm), proc: 0, nfev: 0L, damp: damp}
  common mpfit_machar, machvals

  info = 0L
  iflag = 0L
  errmsg = ''
  catch_msg = 'in MPFIT'
  nfree = 0L
  npegged = 0L
  dof = 0L

  ;; Parameter damping doesn't work when user is providing their own
  ;; gradients.
  if damp NE 0 AND NOT keyword_set(autoderiv) then begin
      errmsg = 'ERROR: keywords DAMP and AUTODERIV are mutually exclusive'
      goto, TERMINATE
  endif      
  
  ;; Process the ITERSTOP and ITERKEYSTOP keywords, and turn this into
  ;; a set of keywords to pass to MPFIT_DEFITER.
  if strupcase(iterproc) EQ 'MPFIT_DEFITER' AND n_elements(iterargs) EQ 0 $
    AND keyword_set(ss) then begin
      if n_elements(iterkeystop) GT 0 then begin
          sz = size(iterkeystop)
          tp = sz(sz(0)+1)
          if tp EQ 7 then begin
              ;; String - convert first char to byte
              iterkeybyte = (byte(iterkeystop(0)))(0)
          endif
          if (tp GE 1 AND tp LE 3) OR (tp GE 12 AND tp LE 15) then begin
              ;; Integer - convert to byte
              iterkeybyte = byte(iterkeystop(0))
          endif
          if n_elements(iterkeybyte) EQ 0 then begin
              errmsg = 'ERROR: ITERKEYSTOP must be either a BYTE or STRING'
              goto, TERMINATE
          endif

          iterargs = {iterstop: 1, iterkeybyte: iterkeybyte}
      endif else begin
          iterargs = {iterstop: 1, iterkeybyte: 7b}
      endelse
  endif


  ;; Handle error conditions gracefully
  if NOT keyword_set(nocatch) then begin
      catch, catcherror
      if catcherror NE 0 then begin
          catch, /cancel
          message, 'Error detected while '+catch_msg+':', /info
          message, !err_string, /info
          message, 'Error condition detected. Returning to MAIN level.', /info
          return, !values.d_nan
      endif
  endif

  ;; Parse FCN function name - be sure it is a scalar string
  sz = size(fcn)
  if sz(0) NE 0 then begin
      FCN_NAME:
      errmsg = 'ERROR: MYFUNCT must be a scalar string'
      goto, TERMINATE
  endif
  if sz(sz(0)+1) NE 7 then goto, FCN_NAME

  isext = 0
  if fcn EQ '(EXTERNAL)' then begin
      if n_elements(efvec) EQ 0 OR n_elements(efjac) EQ 0 then begin
          errmsg = 'ERROR: when using EXTERNAL function, EXTERNAL_FVEC '+$
            'and EXTERNAL_FJAC must be defined'
          goto, TERMINATE
      endif
      nv = n_elements(efvec)
      nj = n_elements(efjac)
      if (nj MOD nv) NE 0 then begin
          errmsg = 'ERROR: the number of values in EXTERNAL_FJAC must be '+ $
            'a multiple of the number of values in EXTERNAL_FVEC'
          goto, TERMINATE
      endif
      isext = 1
  endif

  ;; Parinfo:
  ;; --------------- STARTING/CONFIG INFO (passed in to routine, not changed)
  ;; .value   - starting value for parameter
  ;; .fixed   - parameter is fixed
  ;; .limited - a two-element array, if parameter is bounded on
  ;;            lower/upper side
  ;; .limits - a two-element array, lower/upper parameter bounds, if
  ;;           limited vale is set
  ;; .step   - step size in Jacobian calc, if greater than zero

  catch_msg = 'parsing input parameters'
  ;; Parameters can either be stored in parinfo, or x.  Parinfo takes
  ;; precedence if it exists.
  if n_elements(xall) EQ 0 AND n_elements(parinfo) EQ 0 then begin
      errmsg = 'ERROR: must pass parameters in P or PARINFO'
      goto, TERMINATE
  endif

  ;; Be sure that PARINFO is of the right type
  if n_elements(parinfo) GT 0 then begin
      parinfo_size = size(parinfo)
      if parinfo_size(parinfo_size(0)+1) NE 8 then begin
          errmsg = 'ERROR: PARINFO must be a structure.'
          goto, TERMINATE
      endif
      if n_elements(xall) GT 0 AND n_elements(xall) NE n_elements(parinfo) $
        then begin
          errmsg = 'ERROR: number of elements in PARINFO and P must agree'
          goto, TERMINATE
      endif
  endif

  ;; If the parameters were not specified at the command line, then
  ;; extract them from PARINFO
  if n_elements(xall) EQ 0 then begin
      mpfit_parinfo, parinfo, tagnames, 'VALUE', xall, status=status
      if status EQ 0 then begin
          errmsg = 'ERROR: either P or PARINFO(*).VALUE must be supplied.'
          goto, TERMINATE
      endif

      sz = size(xall)
      ;; Convert to double if parameters are not float or double
      if sz(sz(0)+1) NE 4 AND sz(sz(0)+1) NE 5 then $
        xall = double(xall)
  endif
  npar = n_elements(xall)
  zero = xall(0) * 0.
  one  = zero    + 1.
  fnorm  = -one
  fnorm1 = -one

  ;; TIED parameters?
  mpfit_parinfo, parinfo, tagnames, 'TIED', ptied, default='', n=npar
  ptied = strtrim(ptied, 2)
  wh = where(ptied NE '', qanytied) 
  qanytied = qanytied GT 0
  mpconfig = create_struct(mpconfig, 'QANYTIED', qanytied, 'PTIED', ptied)

  ;; FIXED parameters ?
  mpfit_parinfo, parinfo, tagnames, 'FIXED', pfixed, default=0, n=npar
  pfixed = pfixed EQ 1
  pfixed = pfixed OR (ptied NE '');; Tied parameters are also effectively fixed
  
  ;; Finite differencing step, absolute and relative, and sidedness of deriv.
  mpfit_parinfo, parinfo, tagnames, 'STEP',     step, default=zero, n=npar
  mpfit_parinfo, parinfo, tagnames, 'RELSTEP', dstep, default=zero, n=npar
  mpfit_parinfo, parinfo, tagnames, 'MPSIDE',  dside, default=0,    n=npar

  ;; Maximum and minimum steps allowed to be taken in one iteration
  mpfit_parinfo, parinfo, tagnames, 'MPMAXSTEP', maxstep, default=zero, n=npar
  mpfit_parinfo, parinfo, tagnames, 'MPMINSTEP', minstep, default=zero, n=npar
  qmin = minstep *  0  ;; Remove minstep for now!!
  qmax = maxstep NE 0
  wh = where(qmin AND qmax AND maxstep LT minstep, ct)
  if ct GT 0 then begin
      errmsg = 'ERROR: MPMINSTEP is greater than MPMAXSTEP'
      goto, TERMINATE
  endif
  wh = where(qmin OR qmax, ct)
  qminmax = ct GT 0

  ;; Finish up the free parameters
  ifree = where(pfixed NE 1, nfree)
  if nfree EQ 0 then begin
      errmsg = 'ERROR: no free parameters'
      goto, TERMINATE
  endif

  ;; An external Jacobian must be checked against the number of
  ;; parameters
  if isext then begin
      if (nj/nv) NE nfree then begin
          errmsg = string(nv, nfree, nfree, $
           format=('("ERROR: EXTERNAL_FJAC must be a ",I0," x ",I0,' + $
                   '" array, where ",I0," is the number of free parameters")'))
          goto, TERMINATE
      endif
  endif

  ;; Compose only VARYING parameters
  xnew = xall      ;; xnew is the set of parameters to be returned
  x = xnew(ifree)  ;; x is the set of free parameters

  ;; LIMITED parameters ?
  mpfit_parinfo, parinfo, tagnames, 'LIMITED', limited, status=st1
  mpfit_parinfo, parinfo, tagnames, 'LIMITS',  limits,  status=st2
  if st1 EQ 1 AND st2 EQ 1 then begin

      ;; Error checking on limits in parinfo
      wh = where((limited(0,*) AND xall LT limits(0,*)) OR $
                 (limited(1,*) AND xall GT limits(1,*)), ct)
      if ct GT 0 then begin
          errmsg = 'ERROR: parameters are not within PARINFO limits'
          goto, TERMINATE
      endif
      wh = where(limited(0,*) AND limited(1,*) AND $
                 limits(0,*) GE limits(1,*) AND $
                 pfixed EQ 0, ct)
      if ct GT 0 then begin
          errmsg = 'ERROR: PARINFO parameter limits are not consistent'
          goto, TERMINATE
      endif
      

      ;; Transfer structure values to local variables
      qulim = limited(1, ifree)
      ulim  = limits (1, ifree)
      qllim = limited(0, ifree)
      llim  = limits (0, ifree)

      wh = where(qulim OR qllim, ct)
      if ct GT 0 then qanylim = 1 else qanylim = 0

  endif else begin

      ;; Fill in local variables with dummy values
      qulim = lonarr(nfree)
      ulim  = x * 0.
      qllim = qulim
      llim  = x * 0.
      qanylim = 0

  endelse

  ;; Initialize the number of parameters pegged at a hard limit value
  wh = where((qulim AND (x EQ ulim)) OR (qllim AND (x EQ llim)), npegged)

  n = n_elements(x)
  if n_elements(maxiter) EQ 0 then maxiter = 200L

  ;; Check input parameters for errors
  if (n LE 0) OR (ftol LE 0) OR (xtol LE 0) OR (gtol LE 0) $
    OR (maxiter LE 0) OR (factor LE 0) then begin
      errmsg = 'ERROR: input keywords are inconsistent'
      goto, TERMINATE
  endif

  if keyword_set(rescale) then begin
      errmsg = 'ERROR: DIAG parameter scales are inconsistent'
      if n_elements(diag) LT n then goto, TERMINATE
      wh = where(diag LE 0, ct)
      if ct GT 0 then goto, TERMINATE
      errmsg = ''
  endif

  if n_elements(state) NE 0 AND NOT keyword_set(extinit) then begin
      szst = size(state)
      if szst(szst(0)+1) NE 8  then begin
          errmsg = 'EXTERNAL_STATE keyword was not preserved'
          status = 0
          goto, TERMINATE
      endif
      if nfree NE n_elements(state.ifree) then begin
          BAD_IFREE:
          errmsg = 'Number of free parameters must not change from one '+$
            'external iteration to the next'
          status = 0
          goto, TERMINATE
      endif
      wh = where(ifree NE state.ifree, ct)
      if ct GT 0 then goto, BAD_IFREE

      tnames = tag_names(state)
      for i = 0, n_elements(tnames)-1 do begin
          dummy = execute(tnames(i)+' = state.'+tnames(i))
      endfor
      wa4 = reform(efvec, n_elements(efvec))

      goto, RESUME_FIT
  endif

  common mpfit_error, mperr

  if NOT isext then begin
      mperr = 0
      catch_msg = 'calling '+fcn
      fvec = mpfit_call(fcn, xnew, _EXTRA=fcnargs)
      iflag = mperr
      if iflag LT 0 then begin
          errmsg = 'ERROR: first call to "'+fcn+'" failed'
          goto, TERMINATE
      endif
  endif else begin
      fvec = reform(efvec, n_elements(efvec))
  endelse

  catch_msg = 'calling MPFIT_SETMACHAR'
  sz = size(fvec(0))
  isdouble = (sz(sz(0)+1) EQ 5)
  
  mpfit_setmachar, double=isdouble

  common mpfit_profile, profvals
;  prof_start = systime(1)

  MACHEP0 = machvals.machep
  DWARF   = machvals.minnum

  szx = size(x)
  ;; The parameters and the squared deviations should have the same
  ;; type.  Otherwise the MACHAR-based evaluation will fail.
  catch_msg = 'checking parameter data'
  tp = szx(szx(0)+1)
  if tp NE 4 AND tp NE 5 then begin
      if NOT keyword_set(quiet) then begin
          message, 'WARNING: input parameters must be at least FLOAT', /info
          message, '         (converting parameters to FLOAT)', /info
      endif
      x = float(x)
      xnew = float(x)
      szx = size(x)
  endif
  if isdouble AND tp NE 5 then begin
      if NOT keyword_set(quiet) then begin
          message, 'WARNING: data is DOUBLE but parameters are FLOAT', /info
          message, '         (converting parameters to DOUBLE)', /info
      endif
      x = double(x)
      xnew = double(xnew)
  endif

  m = n_elements(fvec)
  if (m LT n) then begin
      errmsg = 'ERROR: number of parameters must not exceed data'
      goto, TERMINATE
  endif

  fnorm = mpfit_enorm(fvec)

  ;; Initialize Levelberg-Marquardt parameter and iteration counter

  par = zero
  iter = 1L
  qtf = x * 0.

  ;; Beginning of the outer loop
  
  OUTER_LOOP:

  ;; If requested, call fcn to enable printing of iterates
  xnew(ifree) = x
  if qanytied then mpfit_tie, xnew, ptied
  dof = (n_elements(fvec) - nfree) > 1L

  if nprint GT 0 AND iterproc NE '' then begin
      catch_msg = 'calling '+iterproc
      iflag = 0L
      if (iter-1) MOD nprint EQ 0 then begin
          mperr = 0
          xnew0 = xnew

          call_procedure, iterproc, fcn, xnew, iter, fnorm^2, $
            FUNCTARGS=fcnargs, parinfo=parinfo, quiet=quiet, $
            dof=dof, _EXTRA=iterargs
          iflag = mperr

          ;; Check for user termination
          if iflag LT 0 then begin  
              errmsg = 'WARNING: premature termination by "'+iterproc+'"'
              goto, TERMINATE
          endif

          ;; If parameters were changed (grrr..) then re-tie
          if max(abs(xnew0-xnew)) GT 0 then begin
              if qanytied then mpfit_tie, xnew, ptied
              x = xnew(ifree)
          endif

      endif
  endif

  ;; Calculate the jacobian matrix
  iflag = 2
  if NOT isext then begin
      catch_msg = 'calling MPFIT_FDJAC2'
      fjac = mpfit_fdjac2(fcn, x, fvec, step, qulim, ulim, dside, $
                          iflag=iflag, epsfcn=epsfcn, $
                          autoderiv=autoderiv, dstep=dstep, $
                          FUNCTARGS=fcnargs, ifree=ifree, xall=xnew)
      if iflag LT 0 then begin
          errmsg = 'WARNING: premature termination by FDJAC2'
          goto, TERMINATE
      endif
  endif else begin
      fjac = reform(efjac,n_elements(fvec),npar, /overwrite)
  endelse

  ;; Rescale the residuals and gradient, for use with "alternative"
  ;; statistics such as the Cash statistic.
  catch_msg = 'prescaling residuals and gradient'
  if n_elements(scalfcn) GT 0 then begin
      call_procedure, strtrim(scalfcn(0),2), fvec, fjac
  endif

  ;; Determine if any of the parameters are pegged at the limits
  npegged = 0L
  if qanylim then begin
      catch_msg = 'zeroing derivatives of pegged parameters'
      whlpeg = where(qllim AND (x EQ llim), nlpeg)
      whupeg = where(qulim AND (x EQ ulim), nupeg)
      npegged = nlpeg + nupeg
      
      ;; See if any "pegged" values should keep their derivatives
      if (nlpeg GT 0) then begin
          ;; Total derivative of sum wrt lower pegged parameters
          for i = 0L, nlpeg-1 do begin
              sum = total(fvec * fjac(*,whlpeg(i)))
              if sum GT 0 then fjac(*,whlpeg(i)) = 0
          endfor
      endif
      if (nupeg GT 0) then begin
          ;; Total derivative of sum wrt upper pegged parameters
          for i = 0L, nupeg-1 do begin
              sum = total(fvec * fjac(*,whupeg(i)))
              if sum LT 0 then fjac(*,whupeg(i)) = 0
          endfor
      endif
  endif

  ;; Compute the QR factorization of the jacobian
  catch_msg = 'calling MPFIT_QRFAC'
  mpfit_qrfac, fjac, ipvt, wa1, wa2, /pivot

  ;; On the first iteration if "diag" is unspecified, scale
  ;; according to the norms of the columns of the initial jacobian
  catch_msg = 'rescaling diagonal elements'
  if (iter EQ 1) then begin

      if NOT keyword_set(rescale) OR (n_elements(diag) LT n) then begin
          diag = wa2
          wh = where (diag EQ 0, ct)
          if ct GT 0 then diag(wh) = one
      endif
      
      ;; On the first iteration, calculate the norm of the scaled x
      ;; and initialize the step bound delta 
      wa3 = diag * x
      xnorm = mpfit_enorm(wa3)
      delta = factor*xnorm
      if delta EQ zero then delta = zero + factor
  endif

  ;; Form (q transpose)*fvec and store the first n components in qtf
  catch_msg = 'forming (q transpose)*fvec'
  wa4 = fvec
  for j=0L, n-1 do begin
      lj = ipvt(j)
      temp3 = fjac(j,lj)
      if temp3 NE 0 then begin
          fj = fjac(j:*,lj)
          wj = wa4(j:*)
          ;; *** optimization wa4(j:*)
          wa4(j) = wj - fj * total(fj*wj) / temp3  
      endif
      fjac(j,lj) = wa1(j)
      qtf(j) = wa4(j)
  endfor
  ;; From this point on, only the square matrix, consisting of the
  ;; triangle of R, is needed.
  fjac = fjac(0:n-1, 0:n-1)
  fjac = reform(fjac, n, n, /overwrite)
  fjac = fjac(*, ipvt)                    ;; Convert to permuted order
  fjac = reform(fjac, n, n, /overwrite)

  ;; Check for overflow.  This should be a cheap test here since FJAC
  ;; has been reduced to a (small) square matrix, and the test is
  ;; O(N^2).
  wh = where(finite(fjac) EQ 0, ct)
  if ct GT 0 then goto, FAIL_OVERFLOW

  ;; Compute the norm of the scaled gradient
  catch_msg = 'computing the scaled gradient'
  gnorm = zero
  if fnorm NE 0 then begin
      for j=0L, n-1 do begin
          l = ipvt(j)
          if wa2(l) NE 0 then begin
              sum = total(fjac(0:j,j)*qtf(0:j))/fnorm
              gnorm = max([gnorm,abs(sum/wa2(l))])
          endif
      endfor
  endif

  ;; Test for convergence of the gradient norm
  if gnorm LE gtol then info = 4
  if info NE 0 then goto, TERMINATE

  ;; Rescale if necessary
  if NOT keyword_set(rescale) then $
    diag = diag > wa2

  ;; Beginning of the inner loop
  INNER_LOOP:
  
  ;; Determine the levenberg-marquardt parameter
  catch_msg = 'calculating LM parameter (MPFIT_LMPAR)'
  par = mpfit_lmpar(fjac, ipvt, diag, qtf, delta, wa1, wa2, par=par)

  ;; Store the direction p and x+p. Calculate the norm of p
  wa1 = -wa1

  if qanylim EQ 0 AND qminmax EQ 0 then begin
      ;; No parameter limits, so just move to new position WA2
      alpha = one
      wa2 = x + wa1

  endif else begin
      
      ;; Respect the limits.  If a step were to go out of bounds, then
      ;; we should take a step in the same direction but shorter distance.
      ;; The step should take us right to the limit in that case.
      alpha = one

      if qanylim EQ 1 then begin
          ;; Do not allow any steps out of bounds
          catch_msg = 'checking for a step out of bounds'
          if nlpeg GT 0 then wa1(whlpeg) = wa1(whlpeg) > 0
          if nupeg GT 0 then wa1(whupeg) = wa1(whupeg) < 0

          dwa1 = abs(wa1) GT MACHEP0
          whl = where(dwa1 AND qllim AND (x + wa1 LT llim), lct)
          if lct GT 0 then $
            alpha = min([alpha, (llim(whl)-x(whl))/wa1(whl)])
          whu = where(dwa1 AND qulim AND (x + wa1 GT ulim), uct)
          if uct GT 0 then $
            alpha = min([alpha, (ulim(whu)-x(whu))/wa1(whu)])
      endif

      ;; Obey any max step values.

      if qminmax EQ 1 then begin
          nwa1 = wa1 * alpha
          whmax = where(qmax AND maxstep GT 0, ct)
          if ct GT 0 then begin
              mrat = max(abs(nwa1(whmax))/abs(maxstep(whmax)))
              if mrat GT 1 then alpha = alpha / mrat
          endif
      endif          

      ;; Scale the resulting vector
      wa1 = wa1 * alpha
      wa2 = x + wa1

      ;; Adjust the final output values.  If the step put us exactly
      ;; on a boundary, make sure it is exact.
      sgnu = (ulim GE 0)*2d - 1d
      sgnl = (llim GE 0)*2d - 1d
      wh = where(qulim AND wa2 GE ulim*(1-sgnu*MACHEP0), ct)
      if ct GT 0 then wa2(wh) = ulim(wh)

      wh = where(qllim AND wa2 LE llim*(1+sgnl*MACHEP0), ct)
      if ct GT 0 then wa2(wh) = llim(wh)
  endelse

  wa3 = diag * wa1
  pnorm = mpfit_enorm(wa3)

  ;; On the first iteration, adjust the initial step bound
  if iter EQ 1 then delta = min([delta,pnorm])

  xnew(ifree) = wa2
  if isext then goto, SAVE_STATE

  ;; Evaluate the function at x+p and calculate its norm
  mperr = 0
  catch_msg = 'calling '+fcn
  wa4 = mpfit_call(fcn, xnew, _EXTRA=fcnargs)
  iflag = mperr
  if iflag LT 0 then begin
      errmsg = 'WARNING: premature termination by "'+fcn+'"'
      goto, TERMINATE
  endif
  RESUME_FIT:
  fnorm1 = mpfit_enorm(wa4)
  
  ;; Compute the scaled actual reduction
  catch_msg = 'computing convergence criteria'
  actred = -one
  if 0.1D * fnorm1 LT fnorm then actred = - (fnorm1/fnorm)^2 + 1.

  ;; Compute the scaled predicted reduction and the scaled directional
  ;; derivative
  for j = 0L, n-1 do begin
      wa3(j) = 0
      wa3(0:j) = wa3(0:j) + fjac(0:j,j)*wa1(ipvt(j))
  endfor

  ;; Remember, alpha is the fraction of the full LM step actually
  ;; taken
  temp1 = mpfit_enorm(alpha*wa3)/fnorm
  temp2 = (sqrt(alpha*par)*pnorm)/fnorm
  half  = zero + 0.5
  prered = temp1*temp1 + (temp2*temp2)/half
  dirder = -(temp1*temp1 + temp2*temp2)

  ;; Compute the ratio of the actual to the predicted reduction.
  ratio = zero
  tenth = zero + 0.1
  if prered NE 0 then ratio = actred/prered

  ;; Update the step bound
  if ratio LE 0.25D then begin
      if actred GE 0 then temp = half $
      else temp = half*dirder/(dirder + half*actred)
      if ((0.1D*fnorm1) GE fnorm) OR (temp LT 0.1D) then temp = tenth
      delta = temp*min([delta,pnorm/tenth])
      par = par/temp
  endif else begin
      if (par EQ 0) OR (ratio GE 0.75) then begin
          delta = pnorm/half
          par = half*par
      endif
  endelse

  ;; Test for successful iteration
  if ratio GE 0.0001 then begin
      ;; Successful iteration.  Update x, fvec, and their norms
      x = wa2
      wa2 = diag * x

      fvec = wa4
      xnorm = mpfit_enorm(wa2)
      fnorm = fnorm1
      iter = iter + 1
  endif

  ;; Tests for convergence
  if (abs(actred) LE ftol) AND (prered LE ftol) $
    AND  (0.5D * ratio LE 1) then info = 1
  if delta LE xtol*xnorm then info = 2
  if (abs(actred) LE ftol) AND (prered LE ftol) $
    AND (0.5D * ratio LE 1) AND (info EQ 2) then info = 3
  if info NE 0 then goto, TERMINATE

  ;; Tests for termination and stringent tolerances
  if iter GE maxiter then info = 5
  if (abs(actred) LE MACHEP0) AND (prered LE MACHEP0) $
    AND (0.5*ratio LE 1) then info = 6
  if delta LE MACHEP0*xnorm then info = 7
  if gnorm LE MACHEP0 then info = 8
  if info NE 0 then goto, TERMINATE

  ;; End of inner loop. Repeat if iteration unsuccessful
  if ratio LT 0.0001 then begin
      goto, INNER_LOOP
  endif

  ;; Check for over/underflow
  wh = where(finite(wa1) EQ 0 OR finite(wa2) EQ 0 OR finite(x) EQ 0, ct)
  if ct GT 0 OR finite(ratio) EQ 0 then begin
      FAIL_OVERFLOW:
      errmsg = ('ERROR: parameter or function value(s) have become '+$
                'infinite; check model function for over- '+$
                'and underflow')
      info = -16
      goto, TERMINATE
  endif

  ;; End of outer loop.
  goto, OUTER_LOOP

TERMINATE:
  catch_msg = 'in the termination phase'
  ;; Termination, either normal or user imposed.
  if iflag LT 0 then info = iflag
  iflag = 0
  if n_elements(xnew) EQ 0 then goto, FINAL_RETURN
  if nfree EQ 0 then xnew = xall else xnew(ifree) = x
  dof = n_elements(fvec) - nfree


  ;; Call the ITERPROC at the end of the fit, if the fit status is
  ;; okay.  Don't call it if the fit failed for some reason.
  if info GT 0 then begin
      
      mperr = 0
      xnew0 = xnew
      
      call_procedure, iterproc, fcn, xnew, iter, fnorm^2, $
        FUNCTARGS=fcnargs, parinfo=parinfo, quiet=quiet, $
        dof=dof, _EXTRA=iterargs
      iflag = mperr

      if iflag LT 0 then begin  
          errmsg = 'WARNING: premature termination by "'+iterproc+'"'
      endif else begin
          ;; If parameters were changed (grrr..) then re-tie
          if max(abs(xnew0-xnew)) GT 0 then begin
              if qanytied then mpfit_tie, xnew, ptied
              x = xnew(ifree)
          endif
      endelse

  endif

  ;; Initialize the number of parameters pegged at a hard limit value
  npegged = 0L
  if n_elements(qanylim) GT 0 then if qanylim then begin
      wh = where((qulim AND (x EQ ulim)) OR $
                 (qllim AND (x EQ llim)), npegged)
  endif

  if fcn NE '(EXTERNAL)' AND nprint GT 0 AND info GT 0 then begin
      catch_msg = 'calling '+fcn
      fvec = mpfit_call(fcn, xnew, _EXTRA=fcnargs)
      catch_msg = 'in the termination phase'
      fnorm = mpfit_enorm(fvec)
  endif

  if n_elements(fnorm) GT 0 AND n_elements(fnorm1) GT 0 then begin
      fnorm = max([fnorm, fnorm1])
      fnorm = fnorm^2.
  endif

  covar = !values.d_nan
  ;; (very carefully) set the covariance matrix COVAR
  if info GT 0 AND NOT keyword_set(nocovar) $
    AND n_elements(n) GT 0 $
    AND n_elements(fjac) GT 0 AND n_elements(ipvt) GT 0 then begin
      sz = size(fjac)
      if n GT 0 AND sz(0) GT 1 AND sz(1) GE n AND sz(2) GE n $
        AND n_elements(ipvt) GE n then begin
          catch_msg = 'computing the covariance matrix'
          if n EQ 1 then $
            cv = mpfit_covar(reform([fjac(0,0)],1,1), ipvt(0)) $
          else $
            cv = mpfit_covar(fjac(0:n-1,0:n-1), ipvt(0:n-1))
          cv = reform(cv, n, n, /overwrite)
          nn = n_elements(xall)
          
          ;; Fill in actual covariance matrix, accounting for fixed
          ;; parameters.
          covar = replicate(zero, nn, nn)
          for i = 0L, n-1 do begin
              covar(ifree, ifree(i)) = cv(*,i)
          end
          
          ;; Compute errors in parameters
          catch_msg = 'computing parameter errors'
          i = lindgen(nn)
          perror = replicate(abs(covar(0))*0., nn)
          wh = where(covar(i,i) GE 0, ct)
          if ct GT 0 then $
            perror(wh) = sqrt(covar(wh, wh))
      endif
  endif
;  catch_msg = 'returning the result'
;  profvals.mpfit = profvals.mpfit + (systime(1) - prof_start)

  FINAL_RETURN:
  nfev = mpconfig.nfev
  if n_elements(xnew) EQ 0 then return, !values.d_nan
  return, xnew

  
  ;; ------------------------------------------------------------------
  ;; Alternate ending if the user supplies the function and gradients
  ;; externally
  ;; ------------------------------------------------------------------

  SAVE_STATE:

  catch_msg = 'saving MPFIT state'

  ;; Names of variables to save
  varlist = ['alpha', 'delta', 'diag', 'dwarf', 'factor', 'fnorm', $
             'fjac', 'gnorm', 'nfree', 'ifree', 'ipvt', 'iter', $
             'm', 'n', 'machvals', 'machep0', 'npegged', $
             'whlpeg', 'whupeg', 'nlpeg', 'nupeg', $
             'mpconfig', 'par', 'pnorm', 'qtf', $
             'wa1', 'wa2', 'wa3', 'xnorm', 'x', 'xnew']
  cmd = ''

  ;; Construct an expression that will save them
  for i = 0, n_elements(varlist)-1 do begin
      ival = 0
      dummy = execute('ival = n_elements('+varlist(i)+')')
      if ival GT 0 then begin
          cmd = cmd + ',' + varlist(i)+':'+varlist(i)
      endif
  endfor
  cmd = 'state = create_struct({'+strmid(cmd,1)+'})'
  state = 0

  if execute(cmd) NE 1 then $
    message, 'ERROR: could not save MPFIT state'

  ;; Set STATUS keyword to prepare for next iteration, and reset init
  ;; so we do not init the next time
  info = 9
  extinit = 0

  return, xnew

end



