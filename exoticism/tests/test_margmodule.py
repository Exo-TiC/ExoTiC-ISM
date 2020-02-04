import os
import numpy as np
import astropy.units as u
from astropy.constants import G

from exoticism.config import CONFIG_INI
import exoticism.margmodule as marg


# Global star and planet parameters to test on
exoplanet = CONFIG_INI.get('setup', 'data_set')
RL = CONFIG_INI.getfloat(exoplanet, 'rl')
EPOCH = CONFIG_INI.getfloat(exoplanet, 'epoch') * u.d
INCLIN = CONFIG_INI.getfloat(exoplanet, 'inclin') * u.deg
ECC = CONFIG_INI.getfloat(exoplanet, 'ecc') * u.deg
OMEGA = CONFIG_INI.getfloat(exoplanet, 'omega') * u.deg
PERIOD = CONFIG_INI.getfloat(exoplanet, 'Per') * u.d
AOR = CONFIG_INI.getfloat(exoplanet, 'aor')

# Calculate msmpr, the density of the system
constant1 = ((G * np.square(PERIOD)) / (4 * np.square(np.pi))) ** (1 / 3)
MSMPR = (AOR / constant1) ** 3.

# Import data
localDir = CONFIG_INI.get('data_paths', 'local_path')
dataDir = os.path.join(CONFIG_INI.get('data_paths', 'input_path'), 'W17')
x_data, y_data, err, sh = np.loadtxt(os.path.join(dataDir, 'W17_G141_lightcurve_test_data.txt'),
                           skiprows=7, unpack=True) * u.d
#wavelength = np.loadtxt(os.path.join(dataDir, 'W17_G141_wavelength_test_data.txt'), skiprows=3) * u.Angstrom


def test_phase_calc():
    """ Test whether phase is unitless after being fed astropy units. """

    phase = marg.phase_calc(x_data, EPOCH, PERIOD)
    assert phase.unit == '' and type(phase.unit) == u.core.CompositeUnit


def test_impact_param():
    """ Test whether impact parameter is unitless after being fed astropy units. """

    phase = marg.phase_calc(x_data, EPOCH, PERIOD)
    imparam = marg.impact_param(PERIOD, MSMPR, phase, INCLIN)
    assert imparam.unit == '' and type(imparam.unit) == u.core.CompositeUnit


def test_wfc3_systematic_model_grid_selection():
    """ Check whether constructed grid of systematic models has correct shape. """

    for selec in ['fix_time', 'fit_time', 'fit_inclin', 'fit_msmpr', 'fit_ecc', 'fit_all']:
        full_grid = marg.wfc3_systematic_model_grid_selection(selec)
        assert full_grid.shape == (50, 22)
