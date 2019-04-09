import os
import numpy as np
import matplotlib.pyplot as plt

from config import CONFIG_INI
import margmodule as marg

from sherpa.data import Data1D
from sherpa.plot import DataPlot
from sherpa.plot import ModelPlot
from sherpa.fit import Fit
from sherpa.stats import LeastSq
from sherpa.optmethods import LevMar
from sherpa.stats import Chi2
from sherpa.plot import FitPlot
from sherpa import plot as sp


if __name__ == '__main__':

    # Import data
    localDir = CONFIG_INI.get('data_paths', 'local_path')
    curr_model = CONFIG_INI.get('data_paths', 'current_model')
    dataDir = os.path.join(localDir, os.path.join(localDir, CONFIG_INI.get('data_paths', 'data_path')), curr_model)
    x, y, err, sh = np.loadtxt(os.path.join(dataDir, 'W17_white_lightcurve_test_data.txt'),
                               skiprows=7, unpack=True)

    # Create Sherpa data object
    data = Data1D('Data', x, y, staterror=err)

    # Define the model
    tmodel = marg.Transit()
    print(tmodel)

    # Plot the model
    mplot = ModelPlot()
    mplot.prepare(data, tmodel)
    mplot.plot()
    plt.show()
