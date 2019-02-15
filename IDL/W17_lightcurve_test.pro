; W17_lightcurve_test.pro
PRO W17_lightcurve_test

; Read config file (mainly for paths)
whereis,'W17_lightcurve_test', HST_fullpath
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
data = ddread(dataDir + 'W17/' + 'W17_white_lightcurve_test_data.txt', offset=7, /countall, /double)
wavelength = ddread(dataDir + 'W17/' + 'W17_wavelength_test_data.txt', offset=3, /countall, /double)

x = REFORM(data(0,*))
y = REFORM(data(1,*))
err = REFORM(data(2,*))
sh = REFORM(data(3,*))

wavelength = REFORM(wavelength)

; SET-UP the parameters for the subroutine
; ---------------------
;PLANET PARAMETERS
rl = 0.12169232D0 ; Rp/R* estimate
epoch = 57957.970153390D0 ; in MJD 
inclin = 87.34635D0 ;this is converted into radians in the subroutine
ecc = 0.0 ; set to zero and not used when circular
omega = 0.0 ; set to zero and not used when circular
Per = 3.73548535D0 ; in days, converted to seconds in subroutine

persec = Per * dtosec
aor = 7.0780354D0 ; a/r* converted to system density for the subroutine
constant1 = (big_G*Persec*Persec/(4*!pi*!pi))^(1D0/3D0)
MsMpR = (aor/(constant1))^3D0
; ---------------------


LD3D = 'yes'

IF (LD3D EQ 'no') THEN BEGIN
; These numbers represent specific points in the grid for now. This will be updated to automatic grid selection soon. 
FeH = 2 ;Fe/H = -0.25
Teff = 139 ; logg = 4.2, Teff = 6550 K - logg is incorporated into the temperature selection for now.
logg = 4.2
endif

IF (LD3D EQ 'yes') THEN BEGIN
; These numbers are the real values and the grid selection will take place in the sub-routine.
FeH = -1.0
Teff = 6550
logg = 4.5
endif

data_params = [rl, epoch, inclin, MsMpR, ecc, omega, Per, FeH, Teff, logg]
grid_selection = 'fit_time'
out_folder = structure.OUTPUTS
run_name = 'wl_time_wm3d'
plotting='off'

; CALL THE TRANSIT FITTING ROUTINE
G141_lightcurve_circle, x, y, err, sh, data_params, LD3D, wavelength, grid_selection, out_folder, run_name, plotting

; At the end of all this the needed sav files should be dumped into the folder of your choice

END