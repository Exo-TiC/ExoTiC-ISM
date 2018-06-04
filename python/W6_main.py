import numpy as np
import os
from G141_lightcurve_circle import G141_lightcurve_circle

if __name__ == '__main__':
    """
    This is a translation of the W17_lightcurve_test.pro
    """
    # don't need them in the user input part
    # SET THE CONSTANTS
    dtosec = 86400
    big_G = np.float64(6.67259e-11)
    Rjup = np.float64(7.15e7)
    Rsun = np.float64(6.96e8)
    Mjup = np.float64(1.9e27)
    Msun = np.float64(1.99e30)
    HST_second = 5781.6
    HST_period = 0.06691666

    mainDir = '..'
    outDir = os.path.join(mainDir, 'outputs')
    dataDir = os.path.join(mainDir, 'data')


    # READ in the txt file for the lightcurve data
    x, y, err, sh = np.loadtxt(os.path.join(dataDir, 'W6_wlspec_lightcurve_test_data.txt'), skiprows=7, unpack=True)
    wavelength = np.loadtxt(os.path.join(dataDir, 'W6_wlspec_wavelength_test_data.txt'), skiprows=3)

    # SET-UP the parameters for the subroutine
    # ---------------------
    # PLANET PARAMETERS
    rl = np.float64(0.13169232)  # Rp/R* estimate
    epoch = np.float64(57879.633617736)  # in MJD
    inclin = np.float64(88.41)  # this is converted into radians in the subroutine
    ecc = 0.0  # set to zero and not used when circular
    omega = 0.0  # set to zero and not used when circular
    Per = np.float64(3.36100239)  # in days, converted to seconds in subroutine

    persec = Per * dtosec
    aor = np.float64(10.94)  # a/r* converted to system density for the subroutine
    constant1 = (big_G * persec * persec / np.float32(4 * 3.1415927 * 3.1415927)) ** (1 / 3.)
    MsMpR = (aor / (constant1)) ** 3

    ld_model = '1D'   # Which limb darkening models to use, '1D' or '3D'
    FeH = -0.2
    Teff = 5375
    logg = 4.487

    data_params = [rl, epoch, inclin, MsMpR, ecc, omega, Per, FeH, Teff, logg]
    grat = 'G141'   # Which grating to use
    grid_selection = 'fit_time'
    run_name = 'wl_time_1d'
    plotting = True

    G141_lightcurve_circle(x, y, err, sh, data_params, ld_model, wavelength, grat, grid_selection, outDir, run_name, plotting)
