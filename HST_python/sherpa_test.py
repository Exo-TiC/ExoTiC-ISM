import os
import numpy as np
import matplotlib.pyplot as plt

from config import CONFIG_INI
import margmodule as marg

from sherpa.models import model
from sherpa.data import Data1D
from sherpa.plot import DataPlot
from sherpa.plot import ModelPlot
from sherpa.fit import Fit
from sherpa.stats import LeastSq
from sherpa.optmethods import LevMar
from sherpa.stats import Chi2
from sherpa.plot import FitPlot
from sherpa import plot as sp


def _transit_circle(pars, x):
    """
    Transit model.
    """

    HSTper = CONFIG_INI.getfloat('constants', 'HST_period')
    day_to_sec = CONFIG_INI.getfloat('constants', 'dtosec')

    # Define each of the parameters that are read into the fitting routine
    (rl, flux, epoch, inclin, MsMpR, ecc, omega, Per, T0, c1, c2, c3, c4,
     m_fac, hstp1, hstp2, hstp3, hstp4, xshift1, xshift2, xshift3, xshift4) = pars

    phase = marg.phase_calc(x, epoch, Per/day_to_sec)
    HSTphase = marg.phase_calc(x, T0, HSTper)

    # Calculate the impact parameter as a function of the planetary phase across the star.
    b0 = marg.impact_param(Per, MsMpR, phase, inclin)

    # Occultnl would be replaced with BATMAN if possible. The main result we need is the rl - radius ratio
    # The c1-c4 are the non-linear limb-darkening parameters
    # b0 is the impact parameter function and I am not sure how this is handled in BATMAN - I will also look into this.
    mulimb0, mulimbf = marg.occultnl(rl, c1, c2, c3, c4, b0)
    systematic_model = marg.sys_model(phase, HSTphase, sh, m_fac, hstp1,
                                         hstp2, hstp3, hstp4, xshift1, xshift2,
                                         xshift3, xshift4)

    # model fit to data = transit model * baseline flux (flux0) * systematic model
    model = mulimb0 * flux * systematic_model

    return model


class Transit(model.RegriddableModel1D):
    """Transit model"""

    def __init__(self, name='transit'):
        self.rl = model.Parameter(name, 'rl', 0.1, min=0, hard_min=0)
        self.flux = model.Parameter(name, 'flux', 1.)
        self.epoch = model.Parameter(name, 'epoch', 57957.98789)
        self.inclin = model.Parameter(name, 'inclin', 87.)
        self.msmpr = model.Parameter(name, 'msmpr', 1767., min=0, hard_min=0)
        self.ecc = model.Parameter(name, 'ecc', 0)
        self.omega = model.Parameter(name, 'omega', 90)
        self.period = model.Parameter(name, 'period', 2.69)
        self.tzero = model.Parameter(name, 'tzero', 557957.859985)
        self.c1 = model.Parameter(name, 'c1', 0)
        self.c2 = model.Parameter(name, 'c2', 0)
        self.c3 = model.Parameter(name, 'c3', 0)
        self.c4 = model.Parameter(name, 'c4', 0)
        self.m_fac = model.Parameter(name, 'm_fac', 0)
        self.hstp1 = model.Parameter(name, 'hstp1', 0)
        self.hstp2 = model.Parameter(name, 'hstp2', 0)
        self.hstp3 = model.Parameter(name, 'hstp3', 0)
        self.hstp4 = model.Parameter(name, 'hstp4', 0)
        self.xshift1 = model.Parameter(name, 'xshift1', 0)
        self.xshift2 = model.Parameter(name, 'xshift2', 0)
        self.xshift3 = model.Parameter(name, 'xshift3', 0)
        self.xshift4 = model.Parameter(name, 'xshift4', 0)

        model.RegriddableModel1D.__init__(self, name,
                                          (self.rl, self.flux, self.epoch,
                                           self.inclin, self.msmpr, self.ecc,
                                           self.omega, self.period, self.tzero,
                                           self.c1, self.c2, self.c3, self.c4, self.m_fac,
                                           self.hstp1, self.hstp2, self.hstp3,
                                           self.hstp4, self.xshift1, self.xshift2,
                                           self.xshift3, self.xshift4))

    def calc(self, pars, x, *args, **kwargs):
        """Evaluate the model"""
        return _transit_circle(pars, x)


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
    tmodel = Transit()
    print(tmodel)

    # Plot the model
    mplot = ModelPlot()
    mplot.prepare(data, tmodel)
    mplot.plot()
    plt.show()
