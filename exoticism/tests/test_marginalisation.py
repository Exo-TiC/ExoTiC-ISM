import csv
import glob
import os
import numpy as np

from exoticism.config import CONFIG_INI
from exoticism.margmodule import find_data_parent
from exoticism.marginalisation import total_marg


def test_marginalisation_w17_fit_time():
    """Test the correct marginalised parameters for W17 with the grid selection 'fit time'."""

    # Set the star/exoplanet system to W17
    exoplanet = 'W17'

    # Set up data paths that work with CI
    # Outputs will be dumped in the same directory like this test lives in and can/should be deleted when done.
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

    ### Test against old values obtained with ExoTiC-ISM v2.0.0 (tagged)

    # Marginalized parameters
    assert np.isclose(float(output_dict['rl_marg']), 0.12401905841361494, rtol=1e-9), 'rl_marg value is off'
    assert np.isclose(float(output_dict['rl_marg_err']), 0.00019560291752800156, rtol=1e-9), 'rl_marg_err value is off'
    assert np.isclose(float(output_dict['epoch_marg']), 57957.97007898447, rtol=1e-6), 'epoch_marg value is off'
    assert np.isclose(float(output_dict['epoch_marg_err']), 0.0001836464061859145, rtol=1e-9), 'epoch_marg_err value is off'

    # Number of rejected systematic models
    assert int(output_dict['num_rejected']) == 0, 'No systematic model should have been rejected'

    # Top five model stats - the lists get saved out without commas to the csv, so reading them back in is a little cumbersome
    this = output_dict['top_five_numbers'][1:-1]        # read stringified list without commas and reject brackets
    that = this.split(' ')                              # split by white space
    that_clean = list(filter(None, that))               # reject entries that are empty (in case there where double white spaces)
    top_five_numbers = [int(i) for i in that_clean]     # cast into list of ints
    assert top_five_numbers == [40, 30, 41, 45, 33], 'top_five_numbers are incorrect'

    this = output_dict['top_five_weights'][1:-1]
    that = this.split(' ')
    that_clean = list(filter(None, that))
    top_five_weights = [float(i) for i in that_clean]
    assert np.allclose(top_five_weights, [0.10877472617236775, 0.08219481507255598, 0.08213473840712483, 0.08096430014677133, 0.06651390301754695], rtol=1e-9), 'top_five_weights are incorrect'

    this = output_dict['top_five_sdnr'][1:-1]
    that = this.split(' ')
    that_clean = list(filter(None, that))
    top_five_sdnr = [float(i) for i in that_clean]
    assert np.allclose(top_five_sdnr, [122.82905364, 125.7510669, 122.29547469, 122.34196309, 122.81473885], rtol=1e-6), 'top_five_sdnr are incorrect'

    # Noise stats
    assert np.isclose(float(output_dict['white_noise']), 0.00017134399252019425, rtol=1e-9), 'white_noise value is off'
    assert np.isclose(float(output_dict['red_noise']), 2.9945171057075465e-5, rtol=1e-9), 'red_noise value is off'
    assert np.isclose(float(output_dict['beta']), 1.1389386251150133, rtol=1e-9), 'beta value is off'


if __name__ == '__main__':
    test_marginalisation_w17_fit_time()