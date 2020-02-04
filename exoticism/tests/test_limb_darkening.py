import os
import numpy as np

from exoticism.config import CONFIG_INI
import exoticism.limb_darkening as ld
import exoticism.margmodule as marg


# Find the local path of the repository so that we can access the data
LOCAL_PATH = marg.find_data_parent('data')


def test_limb_dark_fit():

    planet_system = 'W17'

    dataDir = os.path.join(LOCAL_PATH, 'data', planet_system)
    get_wvln = CONFIG_INI.get(planet_system, 'wvln_file')

    dirsen = os.path.join(LOCAL_PATH, 'Limb-darkening')   # Directory for sensitivity files
    wavelength = np.loadtxt(os.path.join(dataDir, get_wvln), skiprows=3)

    # Chose your parameters
    ld_model = CONFIG_INI.get('setup', 'ld_model')
    FeH = CONFIG_INI.getfloat(planet_system, 'metallicity')
    Teff = CONFIG_INI.getfloat(planet_system, 'Teff')
    logg = CONFIG_INI.getfloat(planet_system, 'logg')    # choice of logg depends on Teff in 3D models
    grating = 'G141'

    result = ld.limb_dark_fit(grating, wavelength, FeH, Teff, logg, dirsen, ld_model)

    assert True   # I need to come up with a way of testing this
