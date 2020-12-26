import csv
import glob
import os
import numpy as np

from exoticism.config import CONFIG_INI
from exoticism.margmodule import find_data_parent
from exoticism.marginalisation import total_marg


def test_marginalisation_w17_fit_time():
    """Test the correct marginalise parameters for W17 with the grid selection 'fit time'."""

    # Set the star/exoplanet system to W17
    exoplanet = 'W17'

    # Set up data paths that work with CI
    output_dir = ''
    data_dir = find_data_parent('data')

    # Read in lightcurve data
    get_timeseries = CONFIG_INI.get(exoplanet, 'lightcurve_file')
    get_wvln = CONFIG_INI.get(exoplanet, 'wvln_file')
    x, y, err, sh = np.loadtxt(os.path.join(data_dir, 'data', exoplanet, get_timeseries), skiprows=7, unpack=True)
    wavelength = np.loadtxt(os.path.join(data_dir, 'data', exoplanet, get_wvln), skiprows=3)

    # Give it a run name and turn off plotting
    run_name = 'ci_test_run'
    plotting = False
    report = True
    ld_model = '3D'
    grating = 'G141'
    grid_selection = 'fit_time'

    # Run the marginalisation
    total_marg(exoplanet, x, y, err, sh, wavelength, ld_model, grating, grid_selection, output_dir, run_name, plotting, report)

    # Read the output CSV file
    run_dir = glob.glob(f'*{run_name}')[0]
    reader = csv.reader(open(os.path.join(run_dir, 'report.csv'), 'r'))
    output_dict = dict(reader)

    # Test against old values obtained with commit ???
    assert np.isclose(float(output_dict['rl_marg']), 3, rtol=0.00001), 'rl_marg value is off'
    assert np.isclose(float(output_dict['rl_marg_err']), 3, rtol=0.00001), 'rl_marg_err value is off'
    assert np.isclose(float(output_dict['epoch_marg']), 3, rtol=0.00001), 'epoch_marg value is off'
    assert np.isclose(float(output_dict['epoch_marg_err']), 3, rtol=0.00001), 'epoch_marg_err value is off'

    assert int(output_dict['num_rejected']) == 0, 'No systematic model should have been rejected'

    this = output_dict['top_five_numbers'][1:-2]
    that = this.split(' ')
    top_five_numbers = [int(i) for i in that]
    assert top_five_numbers == [0, 1, 2], 'top_five_numbers are incorrect'

    this = output_dict['top_five_weights'][1:-2]
    that = this.split(' ')
    top_five_weights = [int(i) for i in that]
    assert top_five_weights == [0, 1, 2], 'top_five_weights are incorrect'

    this = output_dict['top_five_sdnr'][1:-2]
    that = this.split(' ')
    top_five_sdnr = [int(i) for i in that]
    assert top_five_sdnr == [0, 1, 2], 'top_five_sdnr are incorrect'

    assert np.isclose(float(output_dict['white_noise']), 3, rtol=0.00001), 'white_noise value is off'
    assert np.isclose(float(output_dict['red_noise']), 3, rtol=0.00001), 'red_noise value is off'
    assert np.isclose(float(output_dict['beta']), 3, rtol=0.00001), 'beta value is off'


if __name__ == '__main__':
    test_marginalisation_w17_fit_time()