"""
Preparing to post as an issue on sherpa GitHub.
Copy-paste it and it wil run.
It uses fake data created on the fly.
"""

import numpy as np
import matplotlib.pyplot as plt

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


def _phase_calc(data, epoch, period):
    """
    Convert time array data in terms of phase, with a period, centered on epoch.
    :param data: time array
    :param epoch: center of period
    :param period: phase period
    :return: phase: array
    """

    phase1 = (data - epoch) / period     # the data point at time "epoch" will be the zero-point; convert int phase by division through period
    phase2 = np.floor(phase1)            # identify integer intervals of phase (where phase is between 0-1, between 1-2, between 2-3 and over 3)
    phase = phase1 - phase2              # make phase be in interval from 0 to 1
    toobig = np.where(phase > 0.5)[0]    # figure out where phase is bigger than 0.5
    if toobig.size > 0:
        phase[toobig] -= 1.0                 # and where it is bigger than 0.5 indeed, subtract one to get to interval [-0.5, 0.5]

    return phase


def _impact_param(per, msmpr, phase, incl):
    """
    Calculate impact parameter
    :param per: period
    :param msmpr: MsMpR
    :param phase: phase
    :param incl: inclination
    :return:
    """

    b0 = (6.67259e-11 * per * per / (4 * np.pi * np.pi)) ** (1 / 3.) * (msmpr ** (1 / 3.)) * np.sqrt(
        (np.sin(phase * 2 * np.pi)) ** 2 + (np.cos(incl) * np.cos(phase * 2 * np.pi)) ** 2)

    return b0


def _sys_model(phase, hst_phase, sh, m_fac, hstp1, hstp2, hstp3, hstp4, xshift1, xshift2, xshift3, xshift4):
    """
    Systematic model for WFC3 data
    :param phase:
    :param hst_phase:
    :param sh: array corresponding to the shift in wavelength position on the detector throughout the visit
    :param m_fac:
    :param hstp1:
    :param hstp2:
    :param hstp3:
    :param hstp4:
    :param xshift1:
    :param xshift2:
    :param xshift3:
    :param xshift4:
    :return:
    """

    sys_m = (phase * m_fac + 1.0) * (
            hst_phase * hstp1 + hst_phase ** 2. * hstp2 + hst_phase ** 3. * hstp3 + hst_phase ** 4. * hstp4 + 1.0) * (
                    sh * xshift1 + sh ** 2. * xshift2 + sh ** 3. * xshift3 + sh ** 4. * xshift4 + 1.0)

    return sys_m


def _occultnl(rl, c1, c2, c3, c4, b0):
    """
    MANDEL & AGOL (2002) transit model.
    :param rl: transit depth (Rp/R*)
    :param c1: limb darkening parameter 1
    :param c2: limb darkening parameter 2
    :param c3: limb darkening parameter 3
    :param c4: limb darkening parameter 4
    :param b0: impact parameter
    :return:mulimb0?, mulimbf?
    """
    mulimb0 = _occultuniform(b0, rl)
    bt0 = b0
    fac = np.max(abs(mulimb0 - 1))
    if fac == 0:
        fac = 1e-6  # DKS edit

    omega = 4 * ((1 - c1 - c2 - c3 - c4) / 4 + c1 / 5 + c2 / 6 + c3 / 7 + c4 / 8)
    nb = len(b0)
    indx = np.where(mulimb0 != 1.0)[0]
    if len(indx) == 0:
        indx = -1
    mulimb = mulimb0[indx]
    mulimbf = np.zeros((5, nb))
    mulimbf[0, :] = mulimbf[0, :] + 1.
    mulimbf[1, :] = mulimbf[1, :] + 0.8
    mulimbf[2, :] = mulimbf[2, :] + 2 / 3
    mulimbf[3, :] = mulimbf[3, :] + 4 / 7
    mulimbf[4, :] = mulimbf[4, :] + 0.5
    nr = np.int64(2)
    dmumax = 1.0

    while (dmumax > fac * 1.e-3) and (nr <= 131072):
        #print(nr)
        mulimbp = mulimb
        nr = nr * 2
        dt = 0.5 * np.pi / nr
        t = dt * np.arange(nr + 1)
        th = t + 0.5 * dt
        r = np.sin(t)
        sig = np.sqrt(np.cos(th[nr - 1]))
        mulimbhalf = sig ** 3 * mulimb0[indx] / (1 - r[nr - 1])
        mulimb1 = sig ** 4 * mulimb0[indx] / (1 - r[nr - 1])
        mulimb3half = sig ** 5 * mulimb0[indx] / (1 - r[nr - 1])
        mulimb2 = sig ** 6 * mulimb0[indx] / (1 - r[nr - 1])
        for i in range(1, nr):
            mu = _occultuniform(b0[indx] / r[i], rl / r[i])
            sig1 = np.sqrt(np.cos(th[i - 1]))
            sig2 = np.sqrt(np.cos(th[i]))
            mulimbhalf = mulimbhalf + r[i] ** 2 * mu * (sig1 ** 3 / (r[i] - r[i - 1]) - sig2 ** 3 / (r[i + 1] - r[i]))
            mulimb1 = mulimb1 + r[i] ** 2 * mu * (sig1 ** 4 / (r[i] - r[i - 1]) - sig2 ** 4 / (r[i + 1] - r[i]))
            mulimb3half = mulimb3half + r[i] ** 2 * mu * (sig1 ** 5 / (r[i] - r[i - 1]) - sig2 ** 5 / (r[i + 1] - r[i]))
            mulimb2 = mulimb2 + r[i] ** 2 * mu * (sig1 ** 6 / (r[i] - r[i - 1]) - sig2 ** 6 / (r[i + 1] - r[i]))

        mulimb = ((1 - c1 - c2 - c3 - c4) * mulimb0[
            indx] + c1 * mulimbhalf * dt + c2 * mulimb1 * dt + c3 * mulimb3half * dt + c4 * mulimb2 * dt) / omega
        ix1 = np.where(mulimb + mulimbp != 0.)[0]
        if len(ix1) == 0:
            ix1 = -1

        #print(ix1)
        # python cannot index on single values so you need to use atlest_1d for the below to work when mulimb is a single value
        dmumax = np.max(abs(np.atleast_1d(mulimb)[ix1] - np.atleast_1d(mulimbp)[ix1]) / (
                np.atleast_1d(mulimb)[ix1] + np.atleast_1d(mulimbp)[ix1]))

    mulimbf[0, indx] = np.atleast_1d(mulimb0)[indx]
    mulimbf[1, indx] = mulimbhalf * dt
    mulimbf[2, indx] = mulimb1 * dt
    mulimbf[3, indx] = mulimb3half * dt
    mulimbf[4, indx] = mulimb2 * dt
    np.atleast_1d(mulimb0)[indx] = mulimb
    b0 = bt0

    return mulimb0, mulimbf


def _occultuniform(b0, w):
    """
    Compute the lightcurve for occultation of a uniform source without microlensing (Mandel & Agol 2002).

    :param b0: array; impact parameter in units of rs
    :param w: array; occulting star size in units of rs
    :return: muo1: float; fraction of flux at each b0 for a uniform source
    """

    if abs(w - 0.5) < 1.0e-3:
        w = 0.5

    nb = len(np.atleast_1d(b0))
    muo1 = np.zeros(nb)

    for i in range(nb):
        # substitute z=b0(i) to shorten expressions
        z = np.atleast_1d(b0)[i]
        if z >= 1+w:
            muo1[i] = 1.0
            continue

        if w >= 1 and z <= w-1:
            muo1[i] = 0.0
            continue

        if z >= abs(1-w) and z <= 1+w:
            kap1 = np.arccos(np.min(np.append((1 - w ** 2 + z ** 2) / 2 / z, 1.)))
            kap0 = np.arccos(np.min(np.append((w ** 2 + z ** 2 - 1) / 2 / w / z, 1.)))
            lambdae = w ** 2 * kap0 + kap1
            lambdae = (lambdae - 0.5 * np.sqrt(np.max(np.append(4. * z ** 2 - (1 + z ** 2 - w ** 2) ** 2, 0.)))) / np.pi
            muo1[i] = 1 - lambdae

        if z <= 1-w:
            muo1[i] = 1 - w ** 2
            continue

    return muo1


def _transit_model(pars, x):
    """
    Transit model.
    """

    HSTper = 0.06691666
    day_to_sec = 86400

    # Define each of the parameters that are read into the fitting routine
    (rl, flux, epoch, inclin, MsMpR, ecc, omega, Per, T0, c1, c2, c3, c4,
     m_fac, hstp1, hstp2, hstp3, hstp4, xshift1, xshift2, xshift3, xshift4) = pars

    phase = _phase_calc(x, epoch, Per/day_to_sec)
    HSTphase = _phase_calc(x, T0, HSTper)

    # Calculate the impact parameter as a function of the planetary phase across the star.
    b0 = _impact_param(Per, MsMpR, phase, inclin)

    # Occultnl would be replaced with BATMAN if possible. The main result we need is the rl - radius ratio
    # The c1-c4 are the non-linear limb-darkening parameters
    # b0 is the impact parameter function and I am not sure how this is handled in BATMAN - I will also look into this.
    mulimb0, mulimbf = _occultnl(rl, c1, c2, c3, c4, b0)
    sh = np.ones_like(x) * 0.00278449    # TODO: replace with real data
    systematic_model = _sys_model(phase, HSTphase, sh, m_fac, hstp1,
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
        self.epoch = model.Parameter(name, 'epoch', 557957.98789)
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
        return _transit_model(pars, x)


if __name__ == '__main__':

    # Create data
    anfang = 557957.859985
    custom = 557957.98789
    lang = anfang - custom
    x = np.linspace(anfang, anfang+2*lang, 51)
    y = np.ones_like(x)
    y[21:32] = 0.988
    err = np.ones_like(y) * 0.00017

    # Create Sherpa data object
    data = Data1D('Data', x, y, staterror=err)

    # Plot the data with Sherpa
    dplot = DataPlot()  # create plot object
    dplot.prepare(data)  # prepare data for plotting
    dplot.plot()  # plot
    plt.show()

    # Define the model
    tmodel = Transit()
    print(tmodel)

    # Plot the model
    mplot = ModelPlot()
    mplot.prepare(data, tmodel)
    mplot.plot()
    plt.show()
