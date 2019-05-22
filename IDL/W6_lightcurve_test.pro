; W6_lightcurve_test.pro
PRO W6_lightcurve_test

; Read config file (mainly for paths)
whereis,'W6_lightcurve_test', HST_fullpath
HST_dir = FILE_DIRNAME(HST_fullpath)

IF FILE_TEST(HST_dir + '/config_override.txt') THEN BEGIN
  structure = read_params_vm(HST_dir + '/config_override.txt')
ENDIF ELSE BEGIN
  structure = read_params_vm(HST_dir + '/config.txt')
ENDELSE

; Start Hannah's code
	set_plot, 'x'
; SET THE CONSTANTS 
dtosec = 86400
big_G = 6.67259D-11
Rjup = 7.15D7
Rsun = 6.96D8
Mjup = 1.9D27
Msun = 1.99D30
HST_second = 5781.6
HST_period = 0.06691666
; ------------------------

; READ in the txt file for the lightcurve data
; the double precision seems important here as the x array is very specific
dataDir = structure.INPUTDATA
data = ddread(dataDir + 'W6/' + 'W6_wlspec_lightcurve_test_data.txt', offset=7, /countall, /double)
wavelength = ddread(dataDir + 'W6/' + 'W6_wlspec_wavelength_test_data.txt', offset=3, /countall, /double)

x = REFORM(data(0,*))
y = REFORM(data(1,*))
err = REFORM(data(2,*))
sh = REFORM(data(3,*))

wavelength = REFORM(wavelength)

; SET-UP the parameters for the subroutine
; ---------------------
;PLANET PARAMETERS
rl = 0.1345D0 ; Rp/R* estimate
epoch = 57879.652D0 ; in MJD 
inclin = 88.47D0 ;this is converted into radians in the subroutine
ecc = 0.0 ; set to zero and not used when circular
omega = 0.0 ; set to zero and not used when circular
Per = 3.3610060D0 ; in days, converted to seconds in subroutine

persec = Per * dtosec
aor = 10.62D0 ; a/r* converted to system density for the subroutine
constant1 = (big_G*Persec*Persec/(4*!pi*!pi))^(1D0/3D0)
MsMpR = (aor/(constant1))^3D0
; ---------------------


LD3D = 'no'

IF (LD3D EQ 'no') THEN BEGIN
; These numbers represent specific points in the grid for now. This will be updated to automatic grid selection soon. 
FeH = 1 ;Fe/H = -0.2
Teff = 97 ; logg = 4.6, Teff = 5450 K - logg is incorporated into the temperature selection for now.
logg = 4.6
endif

IF (LD3D EQ 'yes') THEN BEGIN
; These numbers are the real values and the grid selection will take place in the sub-routine.
FeH = -0.2
Teff = 5450
logg = 4.6
endif

data_params = [rl, epoch, inclin, MsMpR, ecc, omega, Per, FeH, Teff, logg]
grid_selection = 'fit_time'
out_folder = structure.OUTPUTS
run_name = 'wl_time'
plotting='off'

; CALL THE TRANSIT FITTING ROUTINE
G141_lightcurve_circle, x, y, err, sh, data_params, LD3D, wavelength, grid_selection, out_folder, run_name, plotting

; At the end of all this the needed sav files should be dumped into the folder of your choice

END