import numpy as np
import os
import time
from G141_lightcurve_circle import G141_lightcurve_circle

if __name__ == '__main__':
    start_time = time.time()

    dtosec = 86400
    big_G = 6.67259e-11
    HST_period = 0.06691666

    mainDir = '..'
    outDir = os.path.join(mainDir, 'outputs/W6')
    dataDir = os.path.join(mainDir, 'data/W6')


    # READ in the txt file for the lightcurve data
    x, y, err, sh = np.loadtxt(os.path.join(dataDir, 'W6_wlspec_lightcurve_test_data.txt'), skiprows=7, unpack=True)
    wavelength = np.loadtxt(os.path.join(dataDir, 'W6_wlspec_wavelength_test_data.txt'), skiprows=3)

    # SET-UP the parameters for the subroutine
    # ---------------------
    # PLANET PARAMETERS
    rl = 0.13169232  # Rp/R* estimate
    epoch = 57879.633617736  # in MJD
    inclin = 88.41  # this is converted into radians in the subroutine
    ecc = 0.0  # set to zero and not used when circular
    omega = 0.0  # set to zero and not used when circular
    Per = 3.36100239  # in days, converted to seconds in subroutine
    aor = 10.94  # a/r* converted to system density for the subroutine

    ld_model = '1D'   # Which limb darkening models to use, '1D' or '3D'
    FeH = -0.2
    Teff = 5375
    logg = 4.487

    persec = Per * dtosec
    constant1 = (big_G * persec * persec / np.float32(4. * np.pi * np.pi)) ** (1. / 3.)
    MsMpR = (aor / constant1) ** 3.

    data_params = [rl, epoch, inclin, MsMpR, ecc, omega, Per, FeH, Teff, logg]
    grat = 'G141'   # Which grating to use
    grid_selection = 'fit_time'
    run_name = 'wl_time_1d'
    plotting = False

    G141_lightcurve_circle(x, y, err, sh, data_params, ld_model, wavelength, grat, grid_selection, outDir, run_name, plotting)

    end_time = time.time()
    print('\nTime it took to run the code:', (end_time-start_time)/60, 'min' )

    print("\n--- ALL IS DONE, LET'S GO HOME AND HAVE A DRINK! ---\n")